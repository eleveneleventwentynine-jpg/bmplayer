import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// The living backdrop behind every screen.
///
/// bmplayer never sits on flat black. This widget animates smoothly between
/// [AppColors.voidGradient] and a muted tint of whatever color is currently
/// playing (passed in as [tint]), so the whole app's mood shifts gently
/// per-track instead of staying static. Pass `null` to fall back to the
/// resting void gradient.
class AmbientBackground extends StatefulWidget {
  const AmbientBackground({
    super.key,
    required this.child,
    this.tint,
    this.duration = const Duration(milliseconds: 1200),
  });

  final Widget child;
  final Color? tint;
  final Duration duration;

  @override
  State<AmbientBackground> createState() => _AmbientBackgroundState();
}

class _AmbientBackgroundState extends State<AmbientBackground> {
  @override
  Widget build(BuildContext context) {
    final tint = widget.tint != null
        ? AppColors.ambientTint(widget.tint!)
        : AppColors.void1;

    return AnimatedContainer(
      duration: widget.duration,
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: const Alignment(0, -0.6),
          radius: 1.4,
          colors: [tint, AppColors.void2],
          stops: const [0.0, 1.0],
        ),
      ),
      child: DecoratedBox(
        decoration: const BoxDecoration(),
        child: widget.child,
      ),
    );
  }
}
