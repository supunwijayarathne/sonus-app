import 'package:material_ui/material_ui.dart';

import '../../data/mock_data.dart';
import '../../models/exercise.dart';
import '../../models/patient_record.dart';
import '../../models/user_profile.dart';
import '../../services/practice_repository.dart';
import '../../theme/app_colors.dart';
import '../exercises/create_exercise_screen.dart';
import '../exercises/exercise_library_screen.dart';
import '../profile/profile_screen.dart';
import 'invite_code_sheet.dart';
import 'overview_screen.dart';
import 'patient_profile_screen.dart';
import 'reviews_screen.dart';
import 'session_review_screen.dart';
import 'users_screen.dart';

/// Speech therapist's main screen with the bottom navigation
/// (Overview, Users, Exercises, Reviews, Profile).
class TherapistShell extends StatefulWidget {
  const TherapistShell({super.key, this.profile = MockData.therapist});

  /// The signed-in therapist.
  final UserProfile profile;

  @override
  State<TherapistShell> createState() => _TherapistShellState();
}

class _TherapistShellState extends State<TherapistShell> {
  int _tab = 0;

  // Created once, so rebuilding doesn't re-subscribe.
  late final Stream<List<PatientRecord>> _patients = practiceRepository
      .patients(widget.profile.id);
  late final Stream<List<Exercise>> _exercises = practiceRepository.exercises(
    widget.profile.id,
  );

  void _openObservation(Observation observation) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SessionReviewScreen(
          observation: observation,
          therapistName: widget.profile.name,
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
          therapistId: widget.profile.id,
          onOpenObservation: _openObservation,
        ),
      ),
    );
  }

  void _linkUser() => showInviteCodeSheet(context, widget.profile.inviteCode);

  void _createExercise() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CreateExerciseScreen(therapistId: widget.profile.id),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<PatientRecord>>(
      stream: _patients,
      builder: (context, patientsSnapshot) {
        final patients = patientsSnapshot.data ?? const <PatientRecord>[];
        final tabs = [
          OverviewScreen(
            therapist: widget.profile,
            patients: patients,
            onOpenPatient: _openPatient,
            onOpenObservation: _openObservation,
            onViewAllUsers: () => setState(() => _tab = 1),
            onLinkUser: _linkUser,
          ),
          UsersScreen(
            patients: patients,
            onOpenPatient: _openPatient,
            onLinkUser: _linkUser,
          ),
          StreamBuilder<List<Exercise>>(
            stream: _exercises,
            builder: (context, snapshot) => ExerciseLibraryScreen(
              exercises: snapshot.data,
              onCreate: _createExercise,
            ),
          ),
          ReviewsScreen(
            patients: patients,
            onOpenObservation: _openObservation,
          ),
          ProfileScreen(profile: widget.profile),
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
                  icon: Icon(Icons.library_books_outlined),
                  label: 'Exercises',
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
      },
    );
  }
}
