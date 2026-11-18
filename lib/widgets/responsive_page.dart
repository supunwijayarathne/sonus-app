import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../theme/app_spacing.dart';

/// Page layout shared by every screen, so they all behave the same:
/// - content is a centred column, at most [AppSpacing.maxContentWidth] wide,
/// - the page scrolls when it does not fit (small phones, landscape, keyboard open),
/// - [builder] gets a `scale` factor (about 1.0 on a normal phone) for large text.
///
/// With [fillHeight] the column is at least as tall as the screen, so a
/// `Spacer()` inside it pushes content to the bottom (used on the welcome screen).
class ResponsivePage extends StatelessWidget {
  const ResponsivePage({
    super.key,
    required this.builder,
    this.fillHeight = false,
    this.background = const [],
  });

  final Widget Function(BuildContext context, double scale) builder;
  final bool fillHeight;

  /// Decorations drawn behind the content (gradients, shapes).
  final List<Widget> background;

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light, // white status bar icons
      child: Scaffold(
        body: Stack(
          children: [
            ...background,
            SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) =>
                    _scrollable(context, constraints),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _scrollable(BuildContext context, BoxConstraints constraints) {
    final contentWidth = (constraints.maxWidth - 2 * AppSpacing.screenPadding)
        .clamp(0.0, AppSpacing.maxContentWidth);
    final scale = (contentWidth / AppSpacing.designContentWidth).clamp(
      0.75,
      1.25,
    );
    final sidePadding = (constraints.maxWidth - contentWidth) / 2;

    Widget content = builder(context, scale);
    if (fillHeight) {
      content = ConstrainedBox(
        constraints: BoxConstraints(minHeight: constraints.maxHeight),
        child: IntrinsicHeight(child: content),
      );
    }

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: sidePadding),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      child: content,
    );
  }
}
