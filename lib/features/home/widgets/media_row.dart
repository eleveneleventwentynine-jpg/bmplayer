import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/animated_waveform.dart';
import '../../../core/widgets/media_artwork.dart';
import '../../../models/media_item.dart';

/// A single tappable row: artwork thumbnail, title/subtitle, and a
/// technical metadata chip in mono type. Shows a live waveform in place
/// of the thumbnail overlay when this row is the currently playing item.
class MediaRow extends StatelessWidget {
  const MediaRow({
    super.key,
    required this.item,
    required this.onTap,
    this.isCurrent = false,
    this.isPlaying = false,
  });

  final BmMediaItem item;
  final VoidCallback onTap;
  final bool isCurrent;
  final bool isPlaying;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Row(
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                MediaArtwork(
                  item: item,
                  width: 52,
                  height: 52,
                  borderRadius: 12,
                ),
                if (isCurrent)
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.45),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: AnimatedWaveform(
                        isPlaying: isPlaying,
                        barCount: 3,
                        height: 16,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: isCurrent
                              ? AppColors.driftAqua
                              : AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.subtitleLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(item.durationLabel, style: AppType.mono()),
          ],
        ),
      ),
    );
  }
}
