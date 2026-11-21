import 'dart:async';

import 'package:just_audio/just_audio.dart';
import 'package:material_ui/material_ui.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../utils/format.dart';

/// Row with an icon, a title, a length ("0:03") and a play/pause button.
///
/// - With [filePath]: plays that file on this phone (just_audio).
/// - Without it but with [unavailableText]: the button is off and the text
///   says why ("Kept on the user's phone").
/// - Neither: playback is *simulated* with a timer (reference audio, which
///   does not exist yet).
class AudioRow extends StatefulWidget {
  const AudioRow({
    super.key,
    required this.icon,
    required this.title,
    required this.length,
    this.filePath,
    this.unavailableText,
  });

  final IconData icon;
  final String title;
  final Duration length;
  final String? filePath;
  final String? unavailableText;

  @override
  State<AudioRow> createState() => _AudioRowState();
}

class _AudioRowState extends State<AudioRow> {
  bool _playing = false;
  Timer? _timer;
  AudioPlayer? _player;
  StreamSubscription<PlayerState>? _playerState;

  bool get _available =>
      widget.filePath != null || widget.unavailableText == null;

  @override
  void dispose() {
    _timer?.cancel();
    _playerState?.cancel();
    _player?.dispose();
    super.dispose();
  }

  Future<void> _toggle() async {
    final path = widget.filePath;
    if (path == null) return _toggleSimulated();

    final player = _player ??= _createPlayer();
    if (_playing) {
      await player.pause();
      return;
    }
    try {
      if (player.audioSource == null ||
          player.processingState == ProcessingState.completed) {
        await player.setFilePath(path);
      }
      unawaited(player.play());
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('The recording could not be played.')),
      );
    }
  }

  AudioPlayer _createPlayer() {
    final player = AudioPlayer();
    _playerState = player.playerStateStream.listen((state) {
      final playing =
          state.playing && state.processingState != ProcessingState.completed;
      if (mounted && playing != _playing) setState(() => _playing = playing);
    });
    return player;
  }

  void _toggleSimulated() {
    _timer?.cancel();
    setState(() => _playing = !_playing);
    if (_playing) {
      _timer = Timer(widget.length, () {
        if (mounted) setState(() => _playing = false);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final subtitle = _available
        ? clockDuration(widget.length)
        : '${clockDuration(widget.length)} · ${widget.unavailableText}';

    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md - 2,
        AppSpacing.md - 2,
        AppSpacing.sm,
        AppSpacing.md - 2,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg + 4),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: const BoxDecoration(
              color: AppColors.accentSurface,
              shape: BoxShape.circle,
            ),
            child: Icon(widget.icon, color: AppColors.accent, size: 18),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.title,
                  style: AppTypography.sectionTitle.copyWith(fontSize: 16),
                ),
                Text(subtitle, style: AppTypography.caption),
              ],
            ),
          ),
          IconButton(
            tooltip: !_available
                ? '${widget.title}: ${widget.unavailableText}'
                : _playing
                ? 'Pause ${widget.title}'
                : 'Play ${widget.title}',
            onPressed: _available ? _toggle : null,
            color: AppColors.textPrimary,
            disabledColor: AppColors.textTertiary,
            icon: Icon(_playing ? Icons.pause : Icons.play_arrow_outlined),
          ),
        ],
      ),
    );
  }
}
