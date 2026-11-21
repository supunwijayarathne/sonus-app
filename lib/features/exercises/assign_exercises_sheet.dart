import 'package:material_ui/material_ui.dart';

import '../../models/exercise.dart';
import '../../models/user_profile.dart';
import '../../services/practice_repository.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../auth/auth_common.dart';
import 'create_exercise_screen.dart';

/// Bottom sheet where a therapist ticks the exercises one user should
/// practise. Unticking removes an assignment (past results stay).
Future<void> showAssignExercisesSheet(
  BuildContext context, {
  required String therapistId,
  required UserProfile user,
  required List<Assignment> current,
}) async {
  final saved = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: AppColors.surface,
    builder: (_) =>
        _AssignSheet(therapistId: therapistId, user: user, current: current),
  );
  if (saved == true && context.mounted) {
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Exercises updated.')));
  }
}

class _AssignSheet extends StatefulWidget {
  const _AssignSheet({
    required this.therapistId,
    required this.user,
    required this.current,
  });

  final String therapistId;
  final UserProfile user;
  final List<Assignment> current;

  @override
  State<_AssignSheet> createState() => _AssignSheetState();
}

class _AssignSheetState extends State<_AssignSheet> {
  late final Stream<List<Exercise>> _library = practiceRepository.exercises(
    widget.therapistId,
  );
  late final Set<String> _selected = {
    for (final a in widget.current) a.exerciseId,
  };
  bool _busy = false;
  String? _error;

  Future<void> _save(List<Exercise> library) async {
    final before = {for (final a in widget.current) a.exerciseId};
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await practiceRepository.updateAssignments(
        therapistId: widget.therapistId,
        userId: widget.user.id,
        add: [
          for (final e in library)
            if (_selected.contains(e.id) && !before.contains(e.id)) e,
        ],
        remove: [
          for (final a in widget.current)
            if (!_selected.contains(a.exerciseId)) a,
        ],
      );
      if (mounted) Navigator.pop(context, true);
    } on DataFailure catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _createExercise() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CreateExerciseScreen(therapistId: widget.therapistId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.85,
        maxWidth: AppSpacing.maxContentWidth,
      ),
      child: StreamBuilder<List<Exercise>>(
        stream: _library,
        builder: (context, snapshot) {
          final library = snapshot.data;
          return Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.md,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Assign exercises', style: AppTypography.title),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Choose what ${widget.user.firstName} should practise.',
                  style: AppTypography.small,
                ),
                const SizedBox(height: AppSpacing.md),
                if (library == null)
                  const Padding(
                    padding: EdgeInsets.all(AppSpacing.lg),
                    child: Center(
                      child: CircularProgressIndicator(color: AppColors.accent),
                    ),
                  )
                else if (library.isEmpty) ...[
                  Text(
                    'Your exercise library is empty. Create an exercise first.',
                    style: AppTypography.small,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  OutlinedButton.icon(
                    onPressed: _createExercise,
                    icon: const Icon(Icons.add),
                    label: const Text('New exercise'),
                  ),
                ] else
                  Flexible(
                    child: ListView(
                      shrinkWrap: true,
                      children: [
                        for (final exercise in library)
                          CheckboxListTile(
                            value: _selected.contains(exercise.id),
                            onChanged: _busy
                                ? null
                                : (on) => setState(
                                    () => on == true
                                        ? _selected.add(exercise.id)
                                        : _selected.remove(exercise.id),
                                  ),
                            activeColor: AppColors.accent,
                            checkColor: AppColors.onAccent,
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              exercise.text,
                              style: AppTypography.scaled(
                                AppTypography.sinhalaWord,
                                0.45,
                              ),
                            ),
                            subtitle: Text(
                              exercise.romanized.isEmpty
                                  ? exercise.expectedPhonemes.join(' ')
                                  : '${exercise.romanized} · '
                                        '${exercise.expectedPhonemes.join(' ')}',
                              style: AppTypography.caption,
                            ),
                          ),
                      ],
                    ),
                  ),
                if (_error != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  FormError(_error!),
                ],
                const SizedBox(height: AppSpacing.md),
                FilledButton(
                  onPressed: _busy || library == null || library.isEmpty
                      ? null
                      : () => _save(library),
                  child: _busy ? const ButtonSpinner() : const Text('Save'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
