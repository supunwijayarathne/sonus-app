import 'package:material_ui/material_ui.dart';

import 'app_colors.dart';

/// Type tokens.
///
/// Inter is a *variable* font: one file holds every weight. Flutter needs the
/// weight as a font variation ('wght' axis) as well as a FontWeight, so every
/// style is built with [_style], which sets both.
/// Sinhala text falls back to Noto Sans Sinhala automatically.
class AppTypography {
  AppTypography._();

  static const String fontFamily = 'Inter';
  static const String sinhalaFamily = 'NotoSansSinhala';
  static const List<String> fallback = [sinhalaFamily];

  static TextStyle _style({
    required double size,
    required int weight,
    double height = 1.4,
    double letterSpacing = 0,
    Color color = AppColors.textPrimary,
    String family = fontFamily,
  }) {
    return TextStyle(
      fontFamily: family,
      fontFamilyFallback: fallback,
      fontSize: size,
      fontWeight: FontWeight.values[(weight ~/ 100) - 1],
      fontVariations: _variations(size, weight),
      height: height,
      letterSpacing: letterSpacing,
      color: color,
    );
  }

  /// Variable-font axes: 'wght' = weight, 'opsz' = optical size.
  /// Inter's opsz axis (14-32) switches big text to the tighter "Inter Display" design.
  static List<FontVariation> _variations(double size, int weight) {
    return [
      FontVariation('wght', weight.toDouble()),
      FontVariation('opsz', size.clamp(14, 32).toDouble()),
    ];
  }

  /// Big hero headline ("Find clarity in every sound.").
  /// The size is a base value; screens scale it with [scaled].
  static final TextStyle display = _style(
    size: 52,
    weight: 500,
    height: 1.02,
    letterSpacing: -3.1, // -6 %: the tight look from Figma
  );

  /// Page headline ("Continue your practice.").
  static final TextStyle headline = _style(
    size: 44,
    weight: 500,
    height: 1.05,
    letterSpacing: -2.4,
  );

  static final TextStyle title = _style(
    size: 24,
    weight: 600,
    height: 1.2,
    letterSpacing: -0.5,
  );

  /// Wordmark next to the logo.
  static final TextStyle brand = _style(
    size: 24,
    weight: 500,
    letterSpacing: -0.8,
    height: 1.0,
  );

  static final TextStyle body = _style(
    size: 15,
    weight: 400,
    height: 1.5,
    letterSpacing: -0.2,
    color: AppColors.textSecondary,
  );

  static final TextStyle button = _style(
    size: 16,
    weight: 500,
    letterSpacing: -0.1,
  );

  /// Small uppercase label ("SPEECH, UNDERSTOOD.").
  static final TextStyle eyebrow = _style(
    size: 12,
    weight: 500,
    letterSpacing: 1.4,
    color: AppColors.accent,
  );

  /// Large card title ("Start practice").
  static final TextStyle cardTitle = _style(
    size: 32,
    weight: 500,
    height: 1.1,
    letterSpacing: -1.4,
  );

  /// Section heading ("This week", "Recent session").
  static final TextStyle sectionTitle = _style(
    size: 18,
    weight: 500,
    letterSpacing: -0.3,
  );

  /// Screen title in a top bar ("Practice").
  static final TextStyle barTitle = _style(
    size: 18,
    weight: 500,
    letterSpacing: -0.2,
  );

  /// Status line under a control ("Listen to the pronunciation").
  static final TextStyle status = _style(
    size: 22,
    weight: 400,
    letterSpacing: -0.4,
  );

  /// The Sinhala word being practised (Noto Sans Sinhala, large).
  static final TextStyle sinhalaWord = _style(
    size: 48,
    weight: 500,
    height: 1.3,
    family: sinhalaFamily,
  );

  /// Smaller secondary text (list subtitles, "3 of 4 sessions").
  static final TextStyle small = _style(
    size: 14,
    weight: 400,
    letterSpacing: -0.1,
    color: AppColors.textSecondary,
  );

  /// Uppercase label above a text field ("EMAIL").
  static final TextStyle fieldLabel = _style(
    size: 12,
    weight: 500,
    letterSpacing: 1.0,
    color: AppColors.textSecondary,
  );

  /// Text typed into a text field.
  static final TextStyle input = _style(size: 17, weight: 400);

  /// Option text in a toggle ("Adult user").
  static final TextStyle option = _style(size: 16, weight: 400);

  /// Small print (disclaimers).
  static final TextStyle caption = _style(
    size: 12,
    weight: 400,
    height: 1.6,
    color: AppColors.textTertiary,
  );

  /// Text inside small pills/badges ("RESEARCH PROTOTYPE").
  static final TextStyle badge = _style(
    size: 10,
    weight: 400,
    letterSpacing: 0.8,
    color: AppColors.textSecondary,
  );

  /// Returns [style] with its size (and letter spacing) multiplied by [factor].
  static TextStyle scaled(TextStyle style, double factor) {
    return style.copyWith(
      fontSize: style.fontSize! * factor,
      letterSpacing: (style.letterSpacing ?? 0) * factor,
    );
  }
}
