import 'package:material_ui/material_ui.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// Coloured text label for a word's status, e.g. "Possible difference" (amber)
/// or "Sounds matched" (green). Always text + colour, never colour alone.
class StatusLabel extends StatelessWidget {
  const StatusLabel({
    super.key,
    required this.hasDifference,
    this.showDot = false,
  });

  final bool hasDifference;

  /// Adds a small dot before the text (used at the top of the result screen).
  final bool showDot;

  @override
  Widget build(BuildContext context) {
    final color = hasDifference ? AppColors.warning : AppColors.success;
    final text = hasDifference
        ? (showDot ? 'Review suggested' : 'Possible difference')
        : 'Sounds matched';

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showDot) ...[
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
        ],
        Flexible(
          child: Text(
            text,
            style: AppTypography.small.copyWith(color: color),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
