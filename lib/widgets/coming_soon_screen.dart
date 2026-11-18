import 'package:material_ui/material_ui.dart';

import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// Temporary placeholder for screens that are not built yet.
class ComingSoon extends StatelessWidget {
  const ComingSoon(this.title, {super.key});

  final String title;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(title, style: AppTypography.title),
              const SizedBox(height: AppSpacing.sm),
              Text('Coming soon.', style: AppTypography.body),
            ],
          ),
        ),
      ),
    );
  }
}
