import 'package:material_ui/material_ui.dart';

import '../models/review.dart';

/// Keeps therapist reviews in memory until Firestore is connected.
///
/// Reviews are only ever ADDED (never edited or deleted), like the Firestore
/// `reviews` subcollection. The latest review for an attempt is the current one.
/// Screens rebuild when a review is added (it is a ChangeNotifier).
class ReviewStore extends ChangeNotifier {
  final Map<String, List<Review>> _byAttempt = {};

  void add(Review review) {
    _byAttempt.putIfAbsent(review.attemptId, () => []).add(review);
    notifyListeners();
  }

  /// Latest review of [attemptId], or null if not reviewed yet.
  Review? latestFor(String attemptId) => _byAttempt[attemptId]?.last;

  bool isReviewed(String attemptId) => latestFor(attemptId) != null;

  /// All reviews of [attemptId], oldest first.
  List<Review> allFor(String attemptId) =>
      List.unmodifiable(_byAttempt[attemptId] ?? const []);

  /// Only for tests: start each test with no reviews.
  @visibleForTesting
  void clearForTest() {
    _byAttempt.clear();
    notifyListeners();
  }
}

/// The store the app uses.
final ReviewStore reviewStore = ReviewStore();
