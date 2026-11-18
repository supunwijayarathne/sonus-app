import 'package:material_ui/material_ui.dart';

/// Filled round button with one icon (play, record, "go" arrow).
/// [tooltip] is also what screen readers say, since there is no visible text.
class CircleActionButton extends StatelessWidget {
  const CircleActionButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.color,
    required this.iconColor,
    this.size = 64,
    this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final Color color;
  final Color iconColor;
  final double size;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton.filled(
      onPressed: onPressed,
      tooltip: tooltip,
      icon: Icon(icon, size: size * 0.4),
      style: IconButton.styleFrom(
        backgroundColor: color,
        foregroundColor: iconColor,
        fixedSize: Size.square(size),
      ),
    );
  }
}
