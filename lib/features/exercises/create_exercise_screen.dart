import 'package:material_ui/material_ui.dart';

import '../../services/g2p.dart';
import '../../services/practice_repository.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../widgets/labeled_text_field.dart';
import '../../widgets/phoneme_chips.dart';
import '../../widgets/responsive_page.dart';
import '../../widgets/round_back_button.dart';
import '../auth/auth_common.dart';

/// Therapist creates an exercise: types a Sinhala word or short phrase and
/// sees the expected sounds (G2P) appear while typing.
class CreateExerciseScreen extends StatefulWidget {
  const CreateExerciseScreen({super.key, required this.therapistId});

  final String therapistId;

  /// A word or a short phrase, not a sentence.
  static const maxWords = 4;
  static const maxLength = 40;

  @override
  State<CreateExerciseScreen> createState() => _CreateExerciseScreenState();
}

class _CreateExerciseScreenState extends State<CreateExerciseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _text = TextEditingController();
  final _romanized = TextEditingController();
  G2pResult? _preview;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    // Live preview: convert on every change (the rules are instant).
    _text.addListener(() {
      final text = _text.text;
      setState(
        () => _preview = text.trim().isEmpty ? null : SinhalaG2p.convert(text),
      );
    });
  }

  @override
  void dispose() {
    _text.dispose();
    _romanized.dispose();
    super.dispose();
  }

  String? _validateText(String? value) {
    final result = SinhalaG2p.convert(value ?? '');
    if (!result.ok) return result.problem;
    if (result.words.length > CreateExerciseScreen.maxWords) {
      return 'Please use a word or a short phrase '
          '(up to ${CreateExerciseScreen.maxWords} words).';
    }
    if (result.text.length > CreateExerciseScreen.maxLength) {
      return 'That is too long for one exercise.';
    }
    return null;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final result = SinhalaG2p.convert(_text.text);
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await practiceRepository.createExercise(
        therapistId: widget.therapistId,
        text: result.text,
        romanized: _romanized.text.trim(),
        expectedPhonemes: result.phonemes,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Exercise saved.')));
      Navigator.pop(context);
    } on DataFailure catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ResponsivePage(
        builder: (context, scale) => Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  const SizedBox(
                    width: 64,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: RoundBackButton(),
                    ),
                  ),
                  Expanded(
                    child: Semantics(
                      header: true,
                      child: Text(
                        'New exercise',
                        textAlign: TextAlign.center,
                        style: AppTypography.barTitle,
                      ),
                    ),
                  ),
                  const SizedBox(width: 64),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
              Text(
                'Type a Sinhala word or short phrase. The expected sounds '
                'appear as you type.',
                style: AppTypography.body,
              ),
              const SizedBox(height: AppSpacing.xl),
              LabeledTextField(
                label: 'Sinhala word or phrase',
                controller: _text,
                hint: 'මල',
                textInputAction: TextInputAction.next,
                validator: _validateText,
              ),
              const SizedBox(height: AppSpacing.lg),
              LabeledTextField(
                label: 'Reading aid (optional)',
                controller: _romanized,
                hint: 'mala',
                textInputAction: TextInputAction.done,
                validator: (v) => (v ?? '').trim().length > 60
                    ? 'Please keep it shorter.'
                    : null,
              ),
              const SizedBox(height: AppSpacing.xl),
              _PreviewCard(preview: _preview),
              const SizedBox(height: AppSpacing.xl),
              if (_error != null) ...[
                FormError(_error!),
                const SizedBox(height: AppSpacing.md),
              ],
              FilledButton(
                onPressed: _busy ? null : _save,
                child: _busy
                    ? const ButtonSpinner()
                    : const Text('Save exercise'),
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }
}

/// "Expected sounds" box under the form.
class _PreviewCard extends StatelessWidget {
  const _PreviewCard({required this.preview});

  final G2pResult? preview;

  @override
  Widget build(BuildContext context) {
    final preview = this.preview;
    final Widget body;
    if (preview == null) {
      body = Text(
        'Sounds appear here as you type.',
        style: AppTypography.small,
      );
    } else if (!preview.ok) {
      body = Text(
        preview.problem!,
        style: AppTypography.small.copyWith(color: AppColors.warning),
      );
    } else {
      body = PhonemeChips(words: preview.words);
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg - 4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('EXPECTED SOUNDS', style: AppTypography.fieldLabel),
          const SizedBox(height: AppSpacing.md),
          // Announce changes to screen readers as the therapist types.
          Semantics(liveRegion: true, child: body),
          const SizedBox(height: AppSpacing.md),
          Text(
            'From the Sonus pronunciation rules (inventory v1.1). '
            'Please check them before saving.',
            style: AppTypography.caption,
          ),
        ],
      ),
    );
  }
}
