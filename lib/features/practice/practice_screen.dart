import 'dart:async';

import 'package:material_ui/material_ui.dart';

import '../../models/practice_word.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../widgets/circle_action_button.dart';
import '../../widgets/responsive_page.dart';
import '../../widgets/round_back_button.dart';
import 'listen_rings.dart';

/// One step of a practice session: show the target word, play the
/// reference audio, then record.
///
/// Reference playback is *simulated* with a timer for now
/// (replace with just_audio when real reference audio exists).
/// Recording is *simulated* too: [onRecord] runs the (mock) analysis.
/// Real recording is the next feature (record package + quality check).
class PracticeScreen extends StatefulWidget {
  const PracticeScreen({
    super.key,
    required this.words,
    this.index = 0,
    this.onRecord,
  });

  final List<PracticeWord> words;

  /// Which word of [words] is shown (0-based).
  final int index;

  /// Called when the record button is tapped. While its Future runs, the
  /// panel shows "Analysing…".
  final Future<void> Function()? onRecord;

  @override
  State<PracticeScreen> createState() => _PracticeScreenState();
}

class _PracticeScreenState extends State<PracticeScreen> {
  static const _referenceLength = Duration(milliseconds: 1600);

  bool _playing = false;
  bool _analysing = false;
  Timer? _timer;

  PracticeWord get _word => widget.words[widget.index];

  Future<void> _record() async {
    _pause();
    setState(() => _analysing = true);
    try {
      await widget.onRecord?.call();
    } finally {
      if (mounted) setState(() => _analysing = false);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _play() {
    _timer?.cancel();
    setState(() => _playing = true);
    _timer = Timer(_referenceLength, () {
      if (mounted) setState(() => _playing = false);
    });
  }

  void _pause() {
    _timer?.cancel();
    setState(() => _playing = false);
  }

  @override
  Widget build(BuildContext context) {
    final step = widget.index + 1;
    final total = widget.words.length;

    return ResponsivePage(
      fillHeight: true,
      builder: (context, scale) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: AppSpacing.sm),
          _TopBar(step: step, total: total),
          const SizedBox(height: AppSpacing.lg),
          // Progress through the session (2 of 5 = 40 %).
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: LinearProgressIndicator(
              value: step / total,
              minHeight: 2,
              color: AppColors.accent,
              backgroundColor: AppColors.fieldBorder,
              semanticsLabel: 'Session progress, word $step of $total',
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),
          Text(
            'TARGET WORD',
            textAlign: TextAlign.center,
            style: AppTypography.fieldLabel.copyWith(
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            _word.text,
            textAlign: TextAlign.center,
            style: AppTypography.scaled(AppTypography.sinhalaWord, scale),
          ),
          Text(
            _word.romanized,
            textAlign: TextAlign.center,
            style: AppTypography.body,
          ),
          const SizedBox(height: AppSpacing.md),
          Center(
            child: ListenRings(
              size: 178 * scale,
              child: CircleActionButton(
                icon: _playing ? Icons.pause : Icons.volume_up_outlined,
                tooltip: _playing ? 'Pause' : 'Play pronunciation',
                color: AppColors.accent,
                iconColor: AppColors.onAccent,
                size: 74 * scale,
                onPressed: _playing ? _pause : _play,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          // Announced by screen readers when it changes.
          Semantics(
            liveRegion: true,
            child: Text(
              _playing ? 'Playing reference' : 'Listen to the pronunciation',
              textAlign: TextAlign.center,
              style: AppTypography.status,
            ),
          ),
          Center(
            child: TextButton.icon(
              onPressed: _play,
              icon: const Icon(Icons.history, size: 20),
              label: const Text('Replay audio'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.textSecondary,
                textStyle: AppTypography.small.copyWith(fontSize: 15),
              ),
            ),
          ),
          const Spacer(),
          const SizedBox(height: AppSpacing.xl),
          _RecordPanel(
            analysing: _analysing,
            onRecord: widget.onRecord == null || _analysing ? null : _record,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Audio is simulated in this research prototype.',
            textAlign: TextAlign.center,
            style: AppTypography.caption.copyWith(fontSize: 11),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
      ),
    );
  }
}

/// Back button, centred title, "2 of 5".
class _TopBar extends StatelessWidget {
  const _TopBar({required this.step, required this.total});

  final int step;
  final int total;

  @override
  Widget build(BuildContext context) {
    // Equal-width sides keep the title exactly centred.
    const sideWidth = 64.0;
    return Row(
      children: [
        const SizedBox(
          width: sideWidth,
          child: Align(
            alignment: Alignment.centerLeft,
            child: RoundBackButton(),
          ),
        ),
        Expanded(
          child: Semantics(
            header: true,
            child: Text(
              'Practice',
              textAlign: TextAlign.center,
              style: AppTypography.barTitle,
            ),
          ),
        ),
        SizedBox(
          width: sideWidth,
          child: Text(
            '$step of $total',
            textAlign: TextAlign.right,
            style: AppTypography.small.copyWith(fontSize: 15),
          ),
        ),
      ],
    );
  }
}

/// Bottom card with the record button (or a spinner while analysing).
class _RecordPanel extends StatelessWidget {
  const _RecordPanel({required this.analysing, this.onRecord});

  final bool analysing;
  final VoidCallback? onRecord;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xl + AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: AppColors.fieldBorder),
      ),
      child: Column(
        children: [
          SizedBox.square(
            dimension: 62,
            child: analysing
                ? const Padding(
                    padding: EdgeInsets.all(AppSpacing.md),
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: AppColors.record,
                    ),
                  )
                : CircleActionButton(
                    icon: Icons.mic_none,
                    tooltip: 'Record',
                    color: AppColors.record,
                    iconColor: AppColors.onRecord,
                    size: 62,
                    onPressed: onRecord,
                  ),
          ),
          const SizedBox(height: AppSpacing.md + 4),
          Semantics(
            liveRegion: true,
            child: Text(
              analysing ? 'Analysing…' : 'Tap to record',
              textAlign: TextAlign.center,
              style: AppTypography.status.copyWith(fontSize: 20),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            analysing
                ? 'Comparing your sounds with the expected sounds.'
                : 'Speak clearly in a comfortable voice.',
            textAlign: TextAlign.center,
            style: AppTypography.small.copyWith(fontSize: 15),
          ),
        ],
      ),
    );
  }
}
