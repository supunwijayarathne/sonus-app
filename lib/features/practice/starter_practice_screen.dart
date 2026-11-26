import 'dart:math';

import 'package:material_ui/material_ui.dart';

import '../../models/practice_word.dart';
import '../../services/reference_audio.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../widgets/responsive_page.dart';
import '../../widgets/section_header.dart';
import '../../widgets/sonus_logo.dart';

/// "Practice" tab: the starter words, by sound group, for practice at any
/// time (also before a therapist is linked). Each word has a computer-voice
/// reference. Words a therapist assigns are on Home.
class StarterPracticeScreen extends StatelessWidget {
  const StarterPracticeScreen({
    super.key,
    required this.linked,
    this.onPractise,
    this.random,
  });

  /// Whether the user has a therapist (who then sees these results).
  final bool linked;

  /// Starts a practice session with these words.
  final ValueChanged<List<PracticeWord>>? onPractise;

  /// For tests (a fixed choice of words).
  final Random? random;

  /// Words per session, picked at random from the group.
  static const sessionLength = 5;

  void _practiseGroup(List<StarterWord> group) {
    final words = [...group]..shuffle(random ?? Random());
    onPractise?.call([for (final w in words.take(sessionLength)) w.word]);
  }

  @override
  Widget build(BuildContext context) {
    final groups = starterWords.groups;

    return ResponsivePage(
      builder: (context, scale) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: AppSpacing.md),
          const Align(alignment: Alignment.centerLeft, child: SonusLogo()),
          const SizedBox(height: AppSpacing.xxl),
          Text('PRACTICE', style: AppTypography.eyebrow),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Practise any time',
            style: AppTypography.scaled(AppTypography.headline, scale),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Choose a group of sounds. You get ${StarterPracticeScreen.sessionLength} '
            'words from it, each with a computer-voice reference to listen to '
            'first.',
            style: AppTypography.body,
          ),
          const SizedBox(height: AppSpacing.md),
          _PrivacyNote(linked: linked),
          const SizedBox(height: AppSpacing.xl),
          SectionHeader(
            'Starter words',
            trailing: Text(
              '${starterWords.words.length}',
              style: AppTypography.small,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          if (groups.isEmpty)
            Text('No starter words on this phone.', style: AppTypography.small)
          else
            Material(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.xl),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  for (final (i, entry) in groups.entries.indexed) ...[
                    if (i > 0)
                      const Divider(height: 1, color: AppColors.fieldBorder),
                    _GroupTile(
                      name: entry.key,
                      words: entry.value,
                      onTap: onPractise == null
                          ? null
                          : () => _practiseGroup(entry.value),
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

/// Who sees self-practice results.
class _PrivacyNote extends StatelessWidget {
  const _PrivacyNote({required this.linked});

  final bool linked;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          linked ? Icons.visibility_outlined : Icons.lock_outline,
          size: 18,
          color: AppColors.textSecondary,
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            linked
                ? 'Your therapist can see these results, marked '
                      '"Self-practice".'
                : 'Only you can see these results. If you link a therapist '
                      'later, they see your practice from then on.',
            style: AppTypography.small,
          ),
        ),
      ],
    );
  }
}

/// One sound group: name, word count and a few example words.
class _GroupTile extends StatelessWidget {
  const _GroupTile({required this.name, required this.words, this.onTap});

  final String name;
  final List<StarterWord> words;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final examples = words.take(4).map((w) => w.text).join('  ');
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md + 2,
        vertical: AppSpacing.xs,
      ),
      title: Text(name, style: AppTypography.sectionTitle.copyWith(fontSize: 17)),
      subtitle: Text(
        '${words.length} words · $examples',
        style: AppTypography.small,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Icon(
        Icons.arrow_forward,
        color: AppColors.accent,
        semanticLabel: 'Practise $name',
      ),
    );
  }
}
