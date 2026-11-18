import 'dart:async';

import 'package:material_ui/material_ui.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../utils/format.dart';

/// Row with an icon, a title, a length ("0:03") and a play/pause button.
///
/// Playback is *simulated* for now (a timer as long as the clip);
/// it switches to just_audio when real audio files exist.
class AudioRow extends StatefulWidget {
  const AudioRow({
    super.key,
    required this.icon,
    required this.title,
    required this.length,
  });

  final IconData icon;
  final String title;
  final Duration length;

  @override
  State<AudioRow> createState() => _AudioRowState();
}

class _AudioRowState extends State<AudioRow> {
  bool _playing = false;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _toggle() {
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
                Text(
                  clockDuration(widget.length),
                  style: AppTypography.caption,
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: _playing
                ? 'Pause ${widget.title}'
                : 'Play ${widget.title}',
            onPressed: _toggle,
            color: AppColors.textPrimary,
            icon: Icon(_playing ? Icons.pause : Icons.play_arrow_outlined),
          ),
        ],
      ),
    );
  }
}
