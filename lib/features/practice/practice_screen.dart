import 'dart:async';

import 'package:material_ui/material_ui.dart';

import '../../models/analysis_result.dart';
import '../../models/practice_word.dart';
import '../../services/analysis_service.dart';
import '../../services/audio_quality.dart';
import '../../services/practice_repository.dart';
import '../../services/voice_recorder.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../utils/format.dart';
import '../../widgets/circle_action_button.dart';
import '../../widgets/responsive_page.dart';
import '../../widgets/round_back_button.dart';
import 'listen_rings.dart';

/// One step of a practice session: show the target word, play the
/// reference audio, then record.
///
/// Recording: tap the mic to start, tap again to stop (it also stops by
/// itself before 15 s). The quality check runs on the phone first; a
/// recording that fails it is deleted and the user is asked to record again.
/// Only a recording that passes is handed to [onRecorded] for analysis; if
/// that fails (e.g. the analysis service can't be reached) the user is told
/// and records again.
///
/// Reference playback is still *simulated* with a timer (there is no
/// reference audio yet).
class PracticeScreen extends StatefulWidget {
  const PracticeScreen({
    super.key,
    required this.words,
    this.index = 0,
    this.onRecorded,
  });

  final List<PracticeWord> words;

  /// Which word of [words] is shown (0-based).
  final int index;

  /// Called with a recording that passed the quality check. While its
  /// Future runs, the panel shows "Analysing…".
  final Future<void> Function(
    String attemptId,
    Recording recording,
    QualityCheck quality,
  )?
  onRecorded;

  @override
  State<PracticeScreen> createState() => _PracticeScreenState();
}

/// What the record panel is doing.
enum _Stage { idle, recording, analysing }

class _PracticeScreenState extends State<PracticeScreen> {
  static const _referenceLength = Duration(milliseconds: 1600);

  /// Stop a little before the 15 s limit, so the recording always fits.
  static final _autoStop = Duration(
    milliseconds: ((AudioQuality.maxSeconds - 0.5) * 1000).round(),
  );

  bool _playing = false;
  Timer? _timer;

  _Stage _stage = _Stage.idle;
  String? _attemptId;
  Duration _elapsed = Duration.zero;
  Timer? _ticker;

  /// Why the last recording was not used ("please record again").
  String? _problem;

  PracticeWord get _word => widget.words[widget.index];

  @override
  void dispose() {
    _timer?.cancel();
    _ticker?.cancel();
    // Leaving mid-recording: throw the recording away.
    if (_stage == _Stage.recording) voiceRecorder.cancel();
    super.dispose();
  }

  Future<void> _startRecording() async {
    _pause();
    setState(() => _problem = null);

    if (!await voiceRecorder.requestPermission()) {
      if (mounted) {
        setState(
          () => _problem =
              'Sonus needs the microphone to record. Please allow '
              "microphone access in your phone's settings.",
        );
      }
      return;
    }

    final id = practiceRepository.newAttemptId();
    try {
      await voiceRecorder.start(id);
    } catch (_) {
      if (mounted) {
        setState(
          () => _problem = 'Could not start recording. Please try again.',
        );
      }
      return;
    }
    if (!mounted) {
      voiceRecorder.cancel();
      return;
    }

    setState(() {
      _stage = _Stage.recording;
      _attemptId = id;
      _elapsed = Duration.zero;
    });
    const tick = Duration(milliseconds: 200);
    _ticker = Timer.periodic(tick, (_) {
      setState(() => _elapsed += tick);
      if (_elapsed >= _autoStop) _stopRecording();
    });
  }

  Future<void> _stopRecording() async {
    if (_stage != _Stage.recording) return;
    _ticker?.cancel();
    setState(() => _stage = _Stage.analysing);

    final recording = await voiceRecorder.stop();
    final quality = recording == null
        ? const QualityCheck(
            ok: false,
            reason: AudioQuality.unreadable,
            durationS: 0,
          )
        : AudioQuality.check(recording.bytes);

    if (!quality.ok) {
      if (recording != null) await voiceRecorder.discard(recording);
      if (mounted) {
        setState(() {
          _stage = _Stage.idle;
          _problem = quality.reason;
        });
      }
      return;
    }

    final kept = await voiceRecorder.keep(recording!);
    String? problem;
    try {
      await widget.onRecorded?.call(_attemptId!, kept, quality);
    } catch (e) {
      // No result (e.g. the service is down): nothing is saved, so the
      // recording is deleted and the user records again.
      await voiceRecorder.discard(kept);
      problem = e is AnalysisException ? e.message : AnalysisException.failed;
    }
    if (mounted) {
      setState(() {
        _stage = _Stage.idle;
        _problem = problem;
      });
    }
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
          if (_word.romanized.isNotEmpty)
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
            stage: _stage,
            elapsed: _elapsed,
            problem: _problem,
            onPressed: switch (_stage) {
              _Stage.idle when widget.onRecorded != null => _startRecording,
              _Stage.recording => _stopRecording,
              _ => null,
            },
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'The reference sound is simulated in this research prototype.',
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

/// Bottom card with the record / stop button, or a spinner while analysing.
class _RecordPanel extends StatelessWidget {
  const _RecordPanel({
    required this.stage,
    required this.elapsed,
    this.problem,
    this.onPressed,
  });

  final _Stage stage;
  final Duration elapsed;
  final String? problem;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final (title, subtitle) = switch (stage) {
      _Stage.idle => ('Tap to record', 'Speak clearly in a comfortable voice.'),
      _Stage.recording => (
        'Recording ${clockDuration(elapsed)}',
        "Tap to stop when you've finished.",
      ),
      _Stage.analysing => (
        'Analysing…',
        'Comparing your sounds with the expected sounds.',
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xl + AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(
          color: stage == _Stage.recording
              ? AppColors.record
              : AppColors.fieldBorder,
        ),
      ),
      child: Column(
        children: [
          SizedBox.square(
            dimension: 62,
            child: stage == _Stage.analysing
                ? const Padding(
                    padding: EdgeInsets.all(AppSpacing.md),
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: AppColors.record,
                    ),
                  )
                : CircleActionButton(
                    icon: stage == _Stage.recording
                        ? Icons.stop_rounded
                        : Icons.mic_none,
                    tooltip: stage == _Stage.recording
                        ? 'Stop recording'
                        : 'Record',
                    color: AppColors.record,
                    iconColor: AppColors.onRecord,
                    size: 62,
                    onPressed: onPressed,
                  ),
          ),
          const SizedBox(height: AppSpacing.md + 4),
          Semantics(
            liveRegion: true,
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: AppTypography.status.copyWith(fontSize: 20),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: AppTypography.small.copyWith(fontSize: 15),
          ),
          // Below the button, so the button never moves between taps.
          if (problem != null) ...[
            const SizedBox(height: AppSpacing.md),
            _Problem(problem!),
          ],
        ],
      ),
    );
  }
}

/// "Please record again" message (icon + text, not colour alone).
class _Problem extends StatelessWidget {
  const _Problem(this.message);

  final String message;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color: AppColors.warning,
            size: 20,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: AppTypography.small.copyWith(color: AppColors.warning),
            ),
          ),
        ],
      ),
    );
  }
}
