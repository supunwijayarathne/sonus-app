import 'package:material_ui/material_ui.dart';

/// Colour tokens for Sonus (taken from the Figma designs).
///
/// Screens never use raw hex values: they use these names, so a colour can be
/// changed in one place.
class AppColors {
  AppColors._();

  // Backgrounds
  static const Color background = Color(0xFF111317);
  static const Color surface = Color(0xFF1C1E23); // text fields, icon buttons
  static const Color surfaceSunken = Color(0xFF16181C); // toggle track
  // Selected toggle option.
  static const Color surfaceRaised = Color(0xFF24272D);
  static const Color glow = Color(0xFF2E3142); // soft light behind the logo

  // Brand
  static const Color accent = Color(0xFFA5B4FC); // periwinkle
  static const Color onAccent = Color(0xFF0E1013); // text on accent buttons
  static const Color accentMuted = Color(0xFF4A5070); // decorative strokes

  // Text
  static const Color textPrimary = Color(0xFFF4F4F5);
  static const Color textSecondary = Color(0xFFA1A1AA);
  static const Color textTertiary = Color(0xFF8B8B94);

  // Lines
  static const Color border = Color(0xFF34363D);
  static const Color fieldBorder = Color(0xFF2B2E35);

  // Feedback
  static const Color error = Color(0xFFFCA5A5);
  static const Color success = Color(0xFF7FCBA4); // completed day
  static const Color onSuccess = Color(0xFF10261B);
  static const Color warning = Color(0xFFF5B94A); // "1 possible difference"
  static const Color warningSurface = Color(0xFF2E281D); // changed sound chip
  static const Color warningBorder = Color(0xFF7A6235);
  static const Color noteSurface = Color(0xFF171A24); // result note box

  // Recording
  static const Color record = Color(0xFFE8898F);
  static const Color onRecord = Color(0xFF2A1215);

  // Destructive actions ("Sign out") use the record colour on a dark red surface.
  static const Color dangerSurface = Color(0xFF221B1E);

  // Accent-tinted surface (role pill, audio icon circles).
  static const Color accentSurface = Color(0xFF242839);

  // Cards
  static const Color heroCardTop = Color(0xFF2A2C37);
  static const Color heroCardBottom = Color(0xFF1D1F25);
  static const Color navBar = Color(0xFF111317);
}
