import 'package:material_ui/material_ui.dart';

import '../theme/app_typography.dart';

/// Section title on the left, optional widget on the right ("3 of 4 sessions", "View history").
class SectionHeader extends StatelessWidget {
  const SectionHeader(this.title, {super.key, this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Semantics(
            header: true,
            child: Text(title, style: AppTypography.sectionTitle),
          ),
        ),
        ?trailing, // "?" = only added when not null
      ],
    );
  }
}
