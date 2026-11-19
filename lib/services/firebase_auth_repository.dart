import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/user_profile.dart';
import '../models/user_role.dart';
import 'auth_repository.dart';

/// Accounts with Firebase Auth (email + password) and Firestore:
///
///   users/{uid}           role, name, email, code, inviteCode?, therapistId?
///   inviteCodes/{code}    therapistId        (lets a user find a therapist
///                                             by code without listing users)
///
/// What each person may read or write is enforced by firestore.rules.
class FirebaseAuthRepository implements AuthRepository {
  // Getters, so nothing touches Firebase until it is actually used.
  FirebaseAuth get _auth => FirebaseAuth.instance;
  FirebaseFirestore get _db => FirebaseFirestore.instance;

  DocumentReference<Map<String, dynamic>> _userDoc(String uid) =>
      _db.collection('users').doc(uid);

  /// Follows the signed-in user, and for them their users/{uid} document.
  ///
  /// When the user changes (sign in / sign out), the listener on the old
  /// user's document is cancelled first. (A plain `asyncExpand` would wait
  /// for the old listener to finish, which never happens, so later sign-ins
  /// would be stuck.)
  @override
  Stream<UserProfile?> profileChanges() {
    late final StreamController<UserProfile?> controller;
    StreamSubscription<User?>? authSub;
    StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? docSub;

    void watchUser(User? user) {
      docSub?.cancel();
      docSub = null;
      if (user == null) {
        controller.add(null);
        return;
      }
      docSub = _userDoc(user.uid).snapshots().listen(
        (snapshot) {
          // Right after sign-up the document may not exist for a moment.
          if (snapshot.exists) {
            controller.add(UserProfile.fromMap(user.uid, snapshot.data()!));
          }
        },
        onError: (Object error) {
          // A listener for a user who just signed out is refused by the
          // rules; that is expected, not an error to show.
          if (_auth.currentUser?.uid == user.uid) controller.addError(error);
        },
      );
    }

    controller = StreamController<UserProfile?>(
      onListen: () {
        authSub = _auth.authStateChanges().listen(
          watchUser,
          onError: controller.addError,
        );
      },
      onCancel: () async {
        await docSub?.cancel();
        await authSub?.cancel();
      },
    );
    return controller.stream;
  }

  @override
  Future<void> signUp({
    required UserRole role,
    required String name,
    required String email,
    required String password,
  }) async {
    final UserCredential credential;
    try {
      credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw AuthFailure(_message(e));
    }

    final uid = credential.user!.uid;
    try {
      await _createProfile(uid: uid, role: role, name: name, email: email);
    } catch (_) {
      // Don't leave an account without a profile behind.
      await credential.user!.delete();
      throw const AuthFailure(
        'Your account could not be set up. Please check your connection '
        'and try again.',
      );
    }
  }

  /// Writes users/{uid} (and, for a therapist, inviteCodes/{code}) in one
  /// batch: either everything is saved or nothing is.
  Future<void> _createProfile({
    required String uid,
    required UserRole role,
    required String name,
    required String email,
  }) async {
    // A random invite code can (rarely) already exist; the rules then
    // reject the batch and we try a new code.
    for (var attempt = 0; attempt < 5; attempt++) {
      final inviteCode = role == UserRole.therapist ? _newInviteCode() : null;
      final batch = _db.batch();
      batch.set(_userDoc(uid), {
        'role': role.firestoreValue,
        'name': name,
        'email': email,
        'code': _newUserCode(),
        'inviteCode': ?inviteCode,
        'createdAt': FieldValue.serverTimestamp(),
      });
      if (inviteCode != null) {
        batch.set(_db.collection('inviteCodes').doc(inviteCode), {
          'therapistId': uid,
        });
      }
      try {
        await batch.commit();
        return;
      } on FirebaseException catch (e) {
        final retry = inviteCode != null && e.code == 'permission-denied';
        if (!retry) rethrow;
      }
    }
    throw StateError('Could not create a unique invite code.');
  }

  @override
  Future<void> signIn({required String email, required String password}) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
    } on FirebaseAuthException catch (e) {
      throw AuthFailure(_message(e));
    }
  }

  @override
  Future<void> signOut() => _auth.signOut();

  @override
  Future<void> linkTherapist(String inviteCode) async {
    final code = inviteCode.trim().toUpperCase();
    final uid = _auth.currentUser!.uid;
    try {
      final invite = await _db.collection('inviteCodes').doc(code).get();
      if (!invite.exists) {
        throw const AuthFailure('That invite code wasn\'t found.');
      }
      // The rules check that therapistId really belongs to linkedCode.
      await _userDoc(uid).update({
        'therapistId': invite.data()!['therapistId'],
        'linkedCode': code,
      });
    } on FirebaseException {
      throw const AuthFailure(
        'Could not link right now. Please check your connection.',
      );
    }
  }

  @override
  Future<String?> nameOf(String uid) async {
    try {
      final doc = await _userDoc(uid).get();
      return doc.data()?['name'] as String?;
    } on FirebaseException {
      return null;
    }
  }

  // --- helpers -------------------------------------------------------------

  static final _random = Random.secure();

  /// "SN-2048": shown to the therapist. Display only, not used for security.
  static String _newUserCode() => 'SN-${1000 + _random.nextInt(9000)}';

  /// 6 characters without look-alikes (no 0/O, 1/I/L), e.g. "K7MPQ4".
  static String _newInviteCode() {
    const chars = 'ABCDEFGHJKMNPQRSTUVWXYZ23456789';
    return List.generate(6, (_) => chars[_random.nextInt(chars.length)]).join();
  }

  /// Turns Firebase error codes into short messages for the form.
  static String _message(FirebaseAuthException e) {
    return switch (e.code) {
      'email-already-in-use' => 'An account with this email already exists.',
      'invalid-email' => 'That email doesn\'t look right.',
      'weak-password' => 'Please choose a stronger password.',
      'invalid-credential' ||
      'wrong-password' ||
      'user-not-found' => 'Email or password is not right.',
      'too-many-requests' => 'Too many attempts. Please wait and try again.',
      'network-request-failed' => 'No connection. Please check your internet.',
      _ => 'Something went wrong. Please try again.',
    };
  }
}
