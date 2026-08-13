import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// A small bar-style waveform that animates continuously while [isPlaying]
/// is true, and freezes mid-motion when paused. This is bmplayer's
/// signature micro-detail — it appears anywhere a track is "alive": the
/// mini-player, the now-playing sheet, and library rows for the current
/// track.
class AnimatedWaveform extends StatefulWidget {
  const AnimatedWaveform({
    super.key,
    required this.isPlaying,
    this.barCount = 4,
    this.height = 18,
    this.color = AppColors.driftAqua,
  });

  final bool isPlaying;
  final int barCount;
  final double height;
  final Color color;

  @override
  State<AnimatedWaveform> createState() => _AnimatedWaveformState();
}

class _AnimatedWaveformState extends State<AnimatedWaveform>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<double> _seeds;

  @override
  void initState() {
    super.initState();
    final rnd = Random();
    _seeds = List.generate(widget.barCount, (_) => rnd.nextDouble() * pi * 2);
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = _controller.value * 2 * pi;
        return SizedBox(
          height: widget.height,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(widget.barCount, (i) {
              final phase = _seeds[i];
              final wave = widget.isPlaying
                  ? (sin(t + phase) + 1) / 2 // 0..1
                  : 0.25;
              final barHeight =
                  (widget.height * 0.25) + wave * (widget.height * 0.75);
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 1.5),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 120),
                  width: 3,
                  height: barHeight,
                  decoration: BoxDecoration(
                    color: widget.color,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              );
            }),
          ),
        );
      },
    );
  }
}
