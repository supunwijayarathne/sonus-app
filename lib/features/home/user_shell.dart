import 'package:material_ui/material_ui.dart';

import '../../data/mock_data.dart';
import '../../models/practice_session.dart';
import '../../theme/app_colors.dart';
import '../history/history_screen.dart';
import '../practice/practice_flow.dart';
import '../profile/profile_screen.dart';
import '../summary/session_summary_screen.dart';
import 'home_screen.dart';

/// Adult user's main screen with the bottom navigation (Home, Practice, History, Profile).
class UserShell extends StatefulWidget {
  const UserShell({super.key, this.onSignOut});

  final VoidCallback? onSignOut;

  @override
  State<UserShell> createState() => _UserShellState();
}

class _UserShellState extends State<UserShell> {
  int _tab = 0;

  void _startPractice() {
    PracticeFlow(MockData.practiceWords).start(context);
  }

  /// Home, History and Profile are tabs. Practice is a quick link: it starts
  /// a practice session and the current tab stays selected underneath.
  void _onNavTap(int index) {
    if (index == _practiceItem) {
      _startPractice();
    } else {
      setState(() => _tab = index);
    }
  }

  static const _practiceItem = 1;

  void _openSession(PracticeSession session) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => SessionSummaryScreen(session: session)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tabs = [
      HomeScreen(
        summary: MockData.homeSummary(),
        onStartPractice: _startPractice,
        onViewHistory: () => setState(() => _tab = 2),
        onOpenSession: _openSession,
      ),
      // Never shown: the Practice item is a shortcut (see _onNavTap).
      const SizedBox.shrink(),
      HistoryScreen(sessions: MockData.sessions(), onOpenSession: _openSession),
      ProfileScreen(profile: MockData.user, onSignOut: widget.onSignOut),
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
          onDestinationSelected: _onNavTap,
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
