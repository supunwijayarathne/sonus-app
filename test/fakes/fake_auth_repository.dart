import 'dart:async';

import 'package:sonus_app/models/user_profile.dart';
import 'package:sonus_app/models/user_role.dart';
import 'package:sonus_app/services/auth_repository.dart';

/// In-memory accounts for widget tests (no Firebase).
class FakeAuthRepository implements AuthRepository {
  final _accounts = <String, (String password, UserProfile profile)>{};
  final _inviteCodes = <String, String>{}; // code -> therapist uid
  final _controller = StreamController<UserProfile?>.broadcast();
  UserProfile? _current;

  @override
  Stream<UserProfile?> profileChanges() async* {
    yield _current;
    yield* _controller.stream;
  }

  void _emit(UserProfile? profile) {
    _current = profile;
    _controller.add(profile);
  }

  @override
  Future<void> signUp({
    required UserRole role,
    required String name,
    required String email,
    required String password,
  }) async {
    if (_accounts.containsKey(email)) {
      throw const AuthFailure('An account with this email already exists.');
    }
    final uid = 'uid-${_accounts.length + 1}';
    final invite = role == UserRole.therapist ? 'INV${_accounts.length}' : null;
    final profile = UserProfile(
      id: uid,
      name: name,
      email: email,
      role: role,
      code: 'SN-1000',
      inviteCode: invite,
    );
    _accounts[email] = (password, profile);
    if (invite != null) _inviteCodes[invite] = uid;
    _emit(profile);
  }

  @override
  Future<void> signIn({required String email, required String password}) async {
    final account = _accounts[email];
    if (account == null || account.$1 != password) {
      throw const AuthFailure('Email or password is not right.');
    }
    _emit(account.$2);
  }

  @override
  Future<void> signOut() async => _emit(null);

  @override
  Future<void> linkTherapist(String inviteCode) async {
    final therapistId = _inviteCodes[inviteCode.trim().toUpperCase()];
    if (therapistId == null) {
      throw const AuthFailure('That invite code wasn\'t found.');
    }
    final me = _current!;
    final linked = UserProfile(
      id: me.id,
      name: me.name,
      email: me.email,
      role: me.role,
      code: me.code,
      therapistId: therapistId,
    );
    _accounts[me.email] = (_accounts[me.email]!.$1, linked);
    _emit(linked);
  }

  @override
  Future<void> updateName(String name) async {
    final me = _current!;
    final renamed = UserProfile(
      id: me.id,
      name: name.trim(),
      email: me.email,
      role: me.role,
      code: me.code,
      inviteCode: me.inviteCode,
      therapistId: me.therapistId,
    );
    _accounts[me.email] = (_accounts[me.email]!.$1, renamed);
    _emit(renamed);
  }

  @override
  Future<String?> nameOf(String uid) async => _accounts.values
      .map((a) => a.$2)
      .where((p) => p.id == uid)
      .firstOrNull
      ?.name;
}
