import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';

/// Bottom sheet with the therapist's invite code. A user types this code in
/// Profile -> "Link your therapist" to be assigned to this therapist.
void showInviteCodeSheet(BuildContext context, String? code) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.surface,
    showDragHandle: true,
    builder: (sheetContext) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          0,
          AppSpacing.lg,
          AppSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('YOUR INVITE CODE', style: AppTypography.eyebrow),
            const SizedBox(height: AppSpacing.md),
            SelectableText(
              code ?? '—',
              textAlign: TextAlign.center,
              style: AppTypography.headline.copyWith(letterSpacing: 6),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Ask your user to open Profile → Link your therapist and '
              'enter this code. They will then appear in Assigned users.',
              textAlign: TextAlign.center,
              style: AppTypography.small,
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton.icon(
              onPressed: code == null
                  ? null
                  : () async {
                      await Clipboard.setData(ClipboardData(text: code));
                      if (sheetContext.mounted) {
                        Navigator.pop(sheetContext);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Invite code copied.')),
                        );
                      }
                    },
              icon: const Icon(Icons.copy),
              label: const Text('Copy code'),
            ),
          ],
        ),
      ),
    ),
  );
}
