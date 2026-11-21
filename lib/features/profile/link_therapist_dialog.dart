import 'package:material_ui/material_ui.dart';

import '../../services/auth_repository.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../auth/auth_common.dart';

/// Asks for the therapist's invite code and links the signed-in user.
/// Used from Profile and from the Home empty state.
Future<void> showLinkTherapistDialog(BuildContext context) async {
  final linked = await showDialog<bool>(
    context: context,
    builder: (_) => const LinkTherapistDialog(),
  );
  if (linked == true && context.mounted) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Linked to your therapist.')));
  }
}

/// Dialog where an adult user types their therapist's invite code.
class LinkTherapistDialog extends StatefulWidget {
  const LinkTherapistDialog({super.key});

  @override
  State<LinkTherapistDialog> createState() => _LinkTherapistDialogState();
}

class _LinkTherapistDialogState extends State<LinkTherapistDialog> {
  final _code = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _link() async {
    if (_code.text.trim().isEmpty) {
      setState(() => _error = 'Please enter the code.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await authRepository.linkTherapist(_code.text);
      if (mounted) Navigator.pop(context, true);
    } on AuthFailure catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      title: Text('Link your therapist', style: AppTypography.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Your therapist can see your practice sessions and review them. '
            'Ask them for their 6-character invite code.',
            style: AppTypography.small,
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _code,
            autofocus: true,
            textCapitalization: TextCapitalization.characters,
            style: AppTypography.input.copyWith(letterSpacing: 3),
            decoration: const InputDecoration(hintText: 'K7MPQ4'),
            onSubmitted: (_) => _link(),
          ),
          if (_error != null) ...[
            const SizedBox(height: AppSpacing.md),
            FormError(_error!),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: _busy ? null : _link,
          style: TextButton.styleFrom(foregroundColor: AppColors.accent),
          child: const Text('Link'),
        ),
      ],
    );
  }
}
