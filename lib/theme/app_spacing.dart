/// Spacing and size tokens (4-point grid).
class AppSpacing {
  AppSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;

  /// Side padding of a screen on a phone.
  static const double screenPadding = 24;

  /// Content never gets wider than this (tablets, landscape), so lines stay readable.
  static const double maxContentWidth = 480;

  /// Content width of the Figma frames (402 wide minus 2 x 24 padding).
  /// Large text scales relative to this.
  static const double designContentWidth = 354;

  /// Height of large buttons and text fields.
  static const double buttonHeight = 56;

  /// Size of round icon buttons (e.g. back).
  static const double iconButtonSize = 44;
}

/// Corner radius tokens.
class AppRadius {
  AppRadius._();

  static const double sm = 8;
  static const double md = 12;
  static const double lg = 20;
  static const double xl = 28; // cards
  static const double pill = 999;
}
