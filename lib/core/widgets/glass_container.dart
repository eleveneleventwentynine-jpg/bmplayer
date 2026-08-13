import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// The single building block behind every surface in bmplayer: a blurred,
/// semi-transparent panel with a hairline border and a soft inner highlight.
///
/// Use [strong] for panels that need to stand out more (now-playing sheet,
/// active cards); leave it false for ambient/background panels.
class GlassContainer extends StatelessWidget {
  const GlassContainer({
    super.key,
    required this.child,
    this.borderRadius = 24,
    this.blurSigma = 24,
    this.strong = false,
    this.padding,
    this.margin,
    this.border,
    this.gradientOverlay,
    this.onTap,
  });

  final Widget child;
  final double borderRadius;
  final double blurSigma;
  final bool strong;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Border? border;
  final Gradient? gradientOverlay;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(borderRadius);

    Widget content = ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: strong ? AppColors.glassFillStrong : AppColors.glassFill,
            borderRadius: radius,
            border: border ??
                Border.all(
                  color: strong
                      ? AppColors.glassBorderStrong
                      : AppColors.glassBorder,
                  width: 1,
                ),
            gradient: gradientOverlay,
            boxShadow: strong
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.35),
                      blurRadius: 30,
                      offset: const Offset(0, 12),
                    ),
                  ]
                : null,
          ),
          child: child,
        ),
      ),
    );

    if (onTap != null) {
      content = Material(
        color: Colors.transparent,
        borderRadius: radius,
        child: InkWell(
          borderRadius: radius,
          onTap: onTap,
          child: content,
        ),
      );
    }

    if (margin != null) {
      content = Padding(padding: margin!, child: content);
    }

    return content;
  }
}
