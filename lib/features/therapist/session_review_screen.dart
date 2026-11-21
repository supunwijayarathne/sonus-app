import 'package:material_ui/material_ui.dart';

import '../../models/patient_record.dart';
import '../../models/review.dart';
import '../../services/review_store.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../utils/format.dart';
import '../../widgets/audio_row.dart';
import '../../widgets/labeled_text_field.dart';
import '../../widgets/observation_card.dart';
import '../../widgets/responsive_page.dart';
import '../../widgets/round_back_button.dart';
import '../result/phoneme_comparison.dart';
import '../result/result_text.dart';

/// Therapist reviews one recorded word: replay audio, see the automated
/// result, then confirm or reject it and add an optional note.
///
/// CLAUDE.md rule 2: the automated result is only *displayed* here. Saving
/// adds a separate [Review] record; it never changes the attempt's result.
class SessionReviewScreen extends StatefulWidget {
  const SessionReviewScreen({
    super.key,
    required this.observation,
    required this.therapistName,
  });

  final Observation observation;
  final String therapistName;

  @override
  State<SessionReviewScreen> createState() => _SessionReviewScreenState();
}

class _SessionReviewScreenState extends State<SessionReviewScreen> {
  final _note = TextEditingController();
  ReviewDecision? _decision;

  String get _attemptId => widget.observation.attempt.id;

  @override
  void initState() {
    super.initState();
    // Start from the latest review, if there is one.
    final latest = reviewStore.latestFor(_attemptId);
    _decision = latest?.decision;
    _note.text = latest?.note ?? '';
  }

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  void _save() {
    reviewStore.add(
      Review(
        attemptId: _attemptId,
        therapistName: widget.therapistName,
        decision: _decision!,
        note: _note.text.trim(),
        createdAt: DateTime.now(),
      ),
    );
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Review saved.')));
    Navigator.maybePop(context);
  }

  @override
  Widget build(BuildContext context) {
    final observation = widget.observation;
    final attempt = observation.attempt;
    final latest = reviewStore.latestFor(_attemptId);

    return ResponsivePage(
      builder: (context, scale) => Column(
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
                    'Session review',
                    textAlign: TextAlign.center,
                    style: AppTypography.barTitle,
                  ),
                ),
              ),
              const SizedBox(width: 64),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          _InfoCard(
            user: observation.patient.profile.name,
            session: sessionTime(observation.session.at),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            'TARGET WORD',
            textAlign: TextAlign.center,
            style: AppTypography.fieldLabel.copyWith(
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            attempt.word.text,
            textAlign: TextAlign.center,
            style: AppTypography.scaled(
              AppTypography.sinhalaWord,
              scale * 0.85,
            ),
          ),
          if (attempt.word.romanized.isNotEmpty)
            Text(
              attempt.word.romanized,
              textAlign: TextAlign.center,
              style: AppTypography.body,
            ),
          const SizedBox(height: AppSpacing.lg),
          AudioRow(
            icon: Icons.volume_up_outlined,
            title: 'Reference audio',
            length: attempt.referenceLength,
          ),
          const SizedBox(height: AppSpacing.md - 4),
          // Recordings stay on the user's phone (no upload yet).
          AudioRow(
            icon: Icons.mic_none,
            title: 'User recording',
            length: attempt.recordingLength,
            filePath: attempt.audioPath,
            unavailableText: "Kept on the user's phone",
          ),
          const SizedBox(height: AppSpacing.xl),
          Text('MODEL PREDICTION', style: AppTypography.eyebrow),
          const SizedBox(height: AppSpacing.md),
          PhonemeComparison(ops: attempt.result.ops),
          const SizedBox(height: AppSpacing.md - 4),
          _PreliminaryBox(text: ResultText.preliminary(attempt.result)),
          const SizedBox(height: AppSpacing.xl),
          Row(
            children: [
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text('Your review', style: AppTypography.sectionTitle),
                ),
              ),
              latest == null
                  ? const _GreyStatus('Not reviewed')
                  : ReviewStatusLabel(
                      text: 'Reviewed · ${latest.decision.label}',
                      awaiting: false,
                    ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: _ChoiceButton(
                  icon: Icons.check,
                  label: 'Confirm observation',
                  selected: _decision == ReviewDecision.confirmed,
                  onTap: () =>
                      setState(() => _decision = ReviewDecision.confirmed),
                ),
              ),
              const SizedBox(width: AppSpacing.sm + 2),
              Expanded(
                child: _ChoiceButton(
                  icon: Icons.close,
                  label: 'Mark as incorrect',
                  selected: _decision == ReviewDecision.rejected,
                  onTap: () =>
                      setState(() => _decision = ReviewDecision.rejected),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          LabeledTextField(
            label: 'Review note',
            controller: _note,
            hint: 'Add an optional clinical note…',
            maxLines: 3,
            textCapitalization: TextCapitalization.sentences,
          ),
          const SizedBox(height: AppSpacing.lg),
          // Enabled once a decision is chosen.
          FilledButton(
            onPressed: _decision == null ? null : _save,
            child: const Text('Save review'),
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }
}

/// "Adult user | Session" card at the top.
class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.user, required this.session});

  final String user;
  final String session;

  @override
  Widget build(BuildContext context) {
    Widget cell(String label, String value) => Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTypography.caption),
          const SizedBox(height: AppSpacing.xs),
          Text(value, style: AppTypography.sectionTitle.copyWith(fontSize: 16)),
        ],
      ),
    );

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md + 2),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg + 4),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            cell('Adult user', user),
            const VerticalDivider(
              width: AppSpacing.xl,
              color: AppColors.fieldBorder,
            ),
            cell('Session', session),
          ],
        ),
      ),
    );
  }
}

class _PreliminaryBox extends StatelessWidget {
  const _PreliminaryBox({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md + 2),
      decoration: BoxDecoration(
        color: AppColors.warningSurface.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Preliminary observation',
            style: AppTypography.small.copyWith(color: AppColors.warning),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(text, style: AppTypography.small.copyWith(fontSize: 13)),
        ],
      ),
    );
  }
}

class _GreyStatus extends StatelessWidget {
  const _GreyStatus(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: const BoxDecoration(
            color: AppColors.textTertiary,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 10),
        Text(text, style: AppTypography.small),
      ],
    );
  }
}

/// One of the two review choices. Selected = accent border + tinted fill
/// + bright text, and announced as selected (not colour alone).
class _ChoiceButton extends StatelessWidget {
  const _ChoiceButton({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppRadius.lg);
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: selected ? AppColors.accentSurface : AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: BorderSide(
            color: selected ? AppColors.accent : AppColors.border,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: InkWell(
          borderRadius: radius,
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(minHeight: 60),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.md,
            ),
            alignment: Alignment.center,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: selected ? AppColors.accent : AppColors.textSecondary,
                ),
                const SizedBox(width: AppSpacing.sm),
                Flexible(
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    style: AppTypography.small.copyWith(
                      color: selected
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
