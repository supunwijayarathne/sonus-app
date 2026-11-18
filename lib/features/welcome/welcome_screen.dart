import 'package:material_ui/material_ui.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../widgets/outline_pill.dart';
import '../../widgets/responsive_page.dart';
import '../../widgets/sonus_logo.dart';
import 'sound_dashes.dart';

/// First screen: brand, tagline, "Get started" (sign up) and "I already have
/// an account" (log in).
///
/// Responsive behaviour comes from [ResponsivePage].
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key, this.onGetStarted, this.onLogIn});

  final VoidCallback? onGetStarted;
  final VoidCallback? onLogIn;

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.sizeOf(context);

    return ResponsivePage(
      // Top bar at the top, text block at the bottom, Spacer in between.
      fillHeight: true,
      background: [
        const Positioned.fill(child: _Glow()),
        // Decorative dashes: only when there is enough height for them.
        if (screen.height > 640)
          Positioned(
            left: 0,
            top: screen.height * 0.36,
            width: screen.width * 0.43,
            height: 12,
            child: const SoundDashes(),
          ),
      ],
      builder: (context, scale) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: AppSpacing.md),
          const _TopBar(),
          const Spacer(),
          const SizedBox(height: AppSpacing.xxl),
          Text('SPEECH, UNDERSTOOD.', style: AppTypography.eyebrow),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Find clarity\nin every sound.',
            style: AppTypography.scaled(AppTypography.display, scale),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'AI-assisted Sinhala pronunciation practice, designed for '
            'focused learning and thoughtful clinical review.',
            style: AppTypography.body,
          ),
          const SizedBox(height: AppSpacing.xl + AppSpacing.sm),
          FilledButton(
            onPressed: onGetStarted,
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Get started'),
                SizedBox(width: AppSpacing.md),
                Icon(Icons.arrow_forward, size: 20),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Center(
            child: TextButton(
              onPressed: onLogIn,
              child: const Text('I already have an account'),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const SonusLogo(),
        const SizedBox(width: AppSpacing.md),
        // Flexible: on very narrow screens the badge shrinks instead of overflowing.
        const Flexible(child: OutlinePill('Research prototype')),
      ],
    );
  }
}

/// Soft light in the top-left corner, behind the logo.
class _Glow extends StatelessWidget {
  const _Glow();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.background,
        gradient: RadialGradient(
          center: Alignment(-0.45, -0.9),
          radius: 0.75,
          colors: [AppColors.glow, AppColors.background],
        ),
      ),
    );
  }
}
