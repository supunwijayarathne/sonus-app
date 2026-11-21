import 'practice_session.dart';
import 'user_profile.dart';

/// Status of one day in the "This week" tracker.
enum DayStatus { done, today, open }

/// Everything the adult user's home screen shows.
class HomeSummary {
  const HomeSummary({
    required this.firstName,
    required this.initials,
    required this.week,
    required this.sessionsDone,
    required this.sessionsPlanned,
    this.recent,
  });

  /// Builds the summary from the user's sessions (newest first).
  factory HomeSummary.fromSessions(
    UserProfile profile,
    List<PracticeSession> sessions, {
    DateTime? now,
  }) {
    now ??= DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final monday = today.subtract(Duration(days: now.weekday - 1));
    final thisWeek = sessions.where((s) => !s.at.isBefore(monday)).toList();

    bool practisedOn(DateTime day) => thisWeek.any(
      (s) =>
          s.at.year == day.year &&
          s.at.month == day.month &&
          s.at.day == day.day,
    );

    return HomeSummary(
      firstName: profile.firstName,
      initials: profile.initials,
      week: [
        for (var i = 0; i < 7; i++)
          if (practisedOn(monday.add(Duration(days: i))))
            DayStatus.done
          else if (i == now.weekday - 1)
            DayStatus.today
          else
            DayStatus.open,
      ],
      sessionsDone: thisWeek.length,
      sessionsPlanned: weeklyPlan,
      recent: sessions.isEmpty ? null : sessions.first,
    );
  }

  /// Suggested number of practice sessions per week.
  static const weeklyPlan = 4;

  final String firstName;
  final String initials;

  /// Monday..Sunday, always 7 items.
  final List<DayStatus> week;

  final int sessionsDone;
  final int sessionsPlanned;
  final PracticeSession? recent;
}
