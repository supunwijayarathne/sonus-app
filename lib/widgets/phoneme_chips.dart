import 'package:material_ui/material_ui.dart';

import '../services/g2p.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// Expected sounds as chips in IPA, one group per word. Long-press (or hover)
/// a chip to see its ASCII name ("ə" -> "ax").
class PhonemeChips extends StatelessWidget {
  const PhonemeChips({super.key, required this.words, this.dense = false});

  /// Phonemes per word, e.g. [[m, a, l, ə]].
  final List<List<String>> words;

  /// Smaller chips, for lists.
  final bool dense;

  @override
  Widget build(BuildContext context) {
    // Screen readers read the ASCII names (IPA symbols are read badly).
    final ascii = [for (final w in words) w.map(SinhalaG2p.asciiOf).join(' ')]
        .join(', ');

    return Semantics(
      label: 'Expected sounds: $ascii',
      excludeSemantics: true,
      child: Wrap(
        spacing: AppSpacing.lg - 4, // between words
        runSpacing: AppSpacing.sm,
        children: [
          for (final word in words)
            Wrap(
              spacing: dense ? 4 : 6,
              runSpacing: dense ? 4 : 6,
              children: [for (final p in word) _chip(p)],
            ),
        ],
      ),
    );
  }

  Widget _chip(String phoneme) {
    final size = dense ? 24.0 : 32.0;
    return Tooltip(
      message: SinhalaG2p.asciiOf(phoneme),
      child: Container(
        height: size,
        constraints: BoxConstraints(minWidth: size),
        padding: EdgeInsets.symmetric(horizontal: dense ? 6 : AppSpacing.sm),
        decoration: BoxDecoration(
          color: AppColors.surfaceRaised,
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        // widthFactor 1: as wide as the text. (Container's own `alignment`
        // would stretch every chip to the full width of the Wrap.)
        child: Center(
          widthFactor: 1,
          child: Text(
            phoneme,
            style: AppTypography.option.copyWith(fontSize: dense ? 13 : 16),
          ),
        ),
      ),
    );
  }
}
