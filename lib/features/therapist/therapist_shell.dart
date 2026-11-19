import 'package:material_ui/material_ui.dart';

import '../../data/mock_data.dart';
import '../../models/patient_record.dart';
import '../../theme/app_colors.dart';
import '../profile/profile_screen.dart';
import 'overview_screen.dart';
import 'patient_profile_screen.dart';
import 'reviews_screen.dart';
import 'session_review_screen.dart';
import 'users_screen.dart';

/// Speech therapist's main screen with the bottom navigation
/// (Overview, Users, Reviews, Profile).
class TherapistShell extends StatefulWidget {
  const TherapistShell({super.key, this.onSignOut});

  final VoidCallback? onSignOut;

  @override
  State<TherapistShell> createState() => _TherapistShellState();
}

class _TherapistShellState extends State<TherapistShell> {
  int _tab = 0;

  void _openObservation(Observation observation) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SessionReviewScreen(
          observation: observation,
          therapistName: MockData.therapist.name,
        ),
      ),
    );
  }

  void _openPatient(PatientRecord patient) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PatientProfileScreen(
          patient: patient,
          onOpenObservation: _openObservation,
        ),
      ),
    );
  }

  void _linkUser() {
    // Invite-code linking comes with Firestore.
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('Linking by invitation code is coming next.'),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final patients = MockData.patients;
    final tabs = [
      OverviewScreen(
        therapist: MockData.therapist,
        patients: patients,
        onOpenPatient: _openPatient,
        onOpenObservation: _openObservation,
        onViewAllUsers: () => setState(() => _tab = 1),
      ),
      UsersScreen(
        patients: patients,
        onOpenPatient: _openPatient,
        onLinkUser: _linkUser,
      ),
      ReviewsScreen(patients: patients, onOpenObservation: _openObservation),
      ProfileScreen(profile: MockData.therapist, onSignOut: widget.onSignOut),
    ];

    return Scaffold(
      body: IndexedStack(index: _tab, children: tabs),
      bottomNavigationBar: DecoratedBox(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.fieldBorder)),
        ),
        child: NavigationBar(
          selectedIndex: _tab,
          onDestinationSelected: (index) => setState(() => _tab = index),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              label: 'Overview',
            ),
            NavigationDestination(
              icon: Icon(Icons.people_outline),
              label: 'Users',
            ),
            NavigationDestination(
              icon: Icon(Icons.assignment_outlined),
              label: 'Reviews',
            ),
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
