import 'practice_session.dart';

/// Status of one day in the "This week" tracker.
enum DayStatus { done, today, open }

/// Everything the adult user's home screen shows.
/// Built from mock data now; from Firestore later.
class HomeSummary {
  const HomeSummary({
    required this.firstName,
    required this.initials,
    required this.week,
    required this.sessionsDone,
    required this.sessionsPlanned,
    this.recent,
  });

  final String firstName;
  final String initials;

  /// Monday..Sunday, always 7 items.
  final List<DayStatus> week;

  final int sessionsDone;
  final int sessionsPlanned;
  final PracticeSession? recent;
}
