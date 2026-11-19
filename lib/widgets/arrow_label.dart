import 'package:material_ui/material_ui.dart';

import '../theme/app_spacing.dart';

/// Button label "Text  →". The text shrinks (ellipsis) instead of
/// overflowing on very narrow screens or with large system text.
class ArrowLabel extends StatelessWidget {
  const ArrowLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Flexible(child: Text(text, overflow: TextOverflow.ellipsis)),
        const SizedBox(width: AppSpacing.md),
        const Icon(Icons.arrow_forward, size: 20),
      ],
    );
  }
}
