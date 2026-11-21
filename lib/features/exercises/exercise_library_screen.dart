import 'package:material_ui/material_ui.dart';

import '../../models/exercise.dart';
import '../../services/practice_repository.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../widgets/dashed_action_card.dart';
import '../../widgets/phoneme_chips.dart';
import '../../widgets/responsive_page.dart';
import '../../widgets/sonus_logo.dart';

/// "Exercises" tab: the therapist's words and phrases, and "New exercise".
/// Exercises are assigned from a user's profile.
class ExerciseLibraryScreen extends StatelessWidget {
  const ExerciseLibraryScreen({
    super.key,
    required this.exercises,
    this.onCreate,
  });

  /// Null while loading.
  final List<Exercise>? exercises;
  final VoidCallback? onCreate;

  Future<void> _delete(BuildContext context, Exercise exercise) async {
    final sure = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('Delete exercise?', style: AppTypography.title),
        content: Text(
          '"${exercise.text}" will also be removed from every user it is '
          'assigned to. Their past results are kept.',
          style: AppTypography.small,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.record),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (sure != true || !context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await practiceRepository.deleteExercise(exercise);
      messenger.showSnackBar(
        const SnackBar(content: Text('Exercise deleted.')),
      );
    } on DataFailure catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final exercises = this.exercises;

    return ResponsivePage(
      builder: (context, scale) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SonusLogo(),
              IconButton.filled(
                onPressed: onCreate,
                tooltip: 'New exercise',
                icon: const Icon(Icons.add),
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.surface,
                  foregroundColor: AppColors.textPrimary,
                  fixedSize: const Size.square(AppSpacing.iconButtonSize),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xxl),
          Text('EXERCISE LIBRARY', style: AppTypography.eyebrow),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Exercises',
            style: AppTypography.scaled(AppTypography.headline, scale),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Sinhala words and short phrases. Assign them from a user\'s '
            'profile.',
            style: AppTypography.body,
          ),
          const SizedBox(height: AppSpacing.xl),
          DashedActionCard(
            title: 'New exercise',
            subtitle: 'Type a Sinhala word or phrase',
            onTap: onCreate,
          ),
          const SizedBox(height: AppSpacing.md + 4),
          if (exercises == null)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(AppSpacing.lg),
                child: CircularProgressIndicator(color: AppColors.accent),
              ),
            )
          else if (exercises.isEmpty)
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Text(
                'No exercises yet. Create your first word above.',
                textAlign: TextAlign.center,
                style: AppTypography.small,
              ),
            )
          else
            Material(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.xl),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  for (var i = 0; i < exercises.length; i++) ...[
                    if (i > 0)
                      const Divider(height: 1, color: AppColors.fieldBorder),
                    ExerciseTile(
                      exercise: exercises[i],
                      trailing: IconButton(
                        onPressed: () => _delete(context, exercises[i]),
                        tooltip: 'Delete ${exercises[i].text}',
                        icon: const Icon(
                          Icons.delete_outline,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }
}

/// One exercise: Sinhala text, reading aid and expected sounds.
class ExerciseTile extends StatelessWidget {
  const ExerciseTile({super.key, required this.exercise, this.trailing});

  final Exercise exercise;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md + 2,
        AppSpacing.md,
        AppSpacing.xs,
        AppSpacing.md,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  exercise.text,
                  style: AppTypography.scaled(AppTypography.sinhalaWord, 0.5),
                ),
                if (exercise.romanized.isNotEmpty)
                  Text(exercise.romanized, style: AppTypography.small),
                const SizedBox(height: AppSpacing.sm),
                PhonemeChips(words: [exercise.expectedPhonemes], dense: true),
              ],
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}
