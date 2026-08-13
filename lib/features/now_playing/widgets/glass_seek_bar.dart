import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

class GlassSeekBar extends StatefulWidget {
  const GlassSeekBar({
    super.key,
    required this.position,
    required this.duration,
    required this.onSeek,
  });

  final Duration position;
  final Duration duration;
  final ValueChanged<Duration> onSeek;

  @override
  State<GlassSeekBar> createState() => _GlassSeekBarState();
}

class _GlassSeekBarState extends State<GlassSeekBar> {
  double? _dragValue;

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final totalMs = widget.duration.inMilliseconds;
    final value = _dragValue ??
        (totalMs > 0
            ? (widget.position.inMilliseconds / totalMs).clamp(0.0, 1.0)
            : 0.0);

    return Column(
      children: [
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 4,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
            activeTrackColor: AppColors.driftAqua,
            inactiveTrackColor: AppColors.glassBorderStrong,
            thumbColor: Colors.white,
          ),
          child: Slider(
            value: value,
            onChanged: (v) => setState(() => _dragValue = v),
            onChangeEnd: (v) {
              final newPos = Duration(
                milliseconds: (v * totalMs).round(),
              );
              widget.onSeek(newPos);
              setState(() => _dragValue = null);
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(_fmt(widget.position), style: AppType.mono()),
              Text(_fmt(widget.duration), style: AppType.mono()),
            ],
          ),
        ),
      ],
    );
  }
}
