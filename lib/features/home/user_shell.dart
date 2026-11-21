import 'package:material_ui/material_ui.dart';

import '../../data/mock_data.dart';
import '../../models/exercise.dart';
import '../../models/home_summary.dart';
import '../../models/practice_session.dart';
import '../../models/practice_word.dart';
import '../../models/user_profile.dart';
import '../../services/practice_repository.dart';
import '../../theme/app_colors.dart';
import '../history/history_screen.dart';
import '../practice/practice_flow.dart';
import '../profile/link_therapist_dialog.dart';
import '../profile/profile_screen.dart';
import '../summary/session_summary_screen.dart';
import 'home_screen.dart';

/// Adult user's main screen with the bottom navigation (Home, Practice, History, Profile).
class UserShell extends StatefulWidget {
  const UserShell({super.key, this.profile = MockData.user});

  /// The signed-in adult user.
  final UserProfile profile;

  @override
  State<UserShell> createState() => _UserShellState();
}

class _UserShellState extends State<UserShell> {
  int _tab = 0;

  // Created once, so rebuilding doesn't re-subscribe.
  late final Stream<List<Assignment>> _assignments = practiceRepository
      .assignmentsFor(widget.profile.id);
  late final Stream<List<PracticeSession>> _sessions = practiceRepository
      .sessions(widget.profile.id);

  static const _practiceItem = 1;

  bool get _linked => widget.profile.therapistId != null;

  /// Starts practice with [words] (all assigned words, or one), or explains
  /// why there is nothing to practise yet.
  void _practise(List<PracticeWord>? words) {
    if (!_linked) {
      showLinkTherapistDialog(context);
    } else if (words == null) {
      return; // still loading
    } else if (words.isEmpty) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Your therapist hasn\'t assigned any words yet.'),
          ),
        );
    } else {
      PracticeFlow(
        words,
        userId: widget.profile.id,
        therapistId: widget.profile.therapistId!,
      ).start(context);
    }
  }

  void _openSession(PracticeSession session) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => SessionSummaryScreen(session: session)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Assignment>>(
      stream: _assignments,
      builder: (context, assignmentsSnapshot) {
        // Only words from the current therapist (after re-linking, the old
        // therapist's assignments are not shown).
        final words = assignmentsSnapshot.data
            ?.where((a) => a.therapistId == widget.profile.therapistId)
            .map((a) => a.word)
            .toList();

        return StreamBuilder<List<PracticeSession>>(
          stream: _sessions,
          builder: (context, sessionsSnapshot) {
            final sessions = sessionsSnapshot.data ?? const <PracticeSession>[];
            return _scaffold(words, sessions);
          },
        );
      },
    );
  }

  Widget _scaffold(List<PracticeWord>? words, List<PracticeSession> sessions) {
    final tabs = [
      HomeScreen(
        summary: HomeSummary.fromSessions(widget.profile, sessions),
        linked: _linked,
        words: words,
        onStartPractice: () => _practise(words),
        onPractiseWord: (word) => _practise([word]),
        onLinkTherapist: () => showLinkTherapistDialog(context),
        onViewHistory: () => setState(() => _tab = 2),
        onOpenSession: _openSession,
      ),
      // Never shown: the Practice item is a shortcut (see onDestinationSelected).
      const SizedBox.shrink(),
      HistoryScreen(sessions: sessions, onOpenSession: _openSession),
      ProfileScreen(profile: widget.profile),
    ];

    return Scaffold(
      // IndexedStack keeps each tab's scroll position when switching.
      body: IndexedStack(index: _tab, children: tabs),
      bottomNavigationBar: DecoratedBox(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.fieldBorder)),
        ),
        child: NavigationBar(
          selectedIndex: _tab,
          // Home, History and Profile are tabs. Practice is a quick link: it
          // starts a practice session and the current tab stays selected.
          onDestinationSelected: (index) => index == _practiceItem
              ? _practise(words)
              : setState(() => _tab = index),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(Icons.mic_none),
              label: 'Practice',
            ),
            NavigationDestination(icon: Icon(Icons.history), label: 'History'),
            NavigationDestination(
              icon: Icon(Icons.person_outline),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
