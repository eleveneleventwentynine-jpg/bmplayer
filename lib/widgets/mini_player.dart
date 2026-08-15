import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/widgets/animated_waveform.dart';
import '../core/widgets/glass_container.dart';
import '../core/widgets/media_artwork.dart';
import '../state/providers.dart';

class MiniPlayer extends ConsumerWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playback = ref.watch(playerServiceProvider);
    final playerService = ref.read(playerServiceProvider.notifier);
    final item = playback.current;

    if (item == null) return const SizedBox.shrink();

    return GestureDetector(
      onTap: () => ref.read(playerExpandedProvider.notifier).state = true,
      child: GlassContainer(
        borderRadius: 22,
        strong: true,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        child: Row(
          children: [
            MediaArtwork(item: item, width: 44, height: 44, borderRadius: 14),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  Text(
                    item.artist,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            AnimatedWaveform(isPlaying: playback.isPlaying, height: 18),
            const SizedBox(width: 10),
            IconButton(
              icon: Icon(
                playback.isPlaying
                    ? Icons.pause_rounded
                    : Icons.play_arrow_rounded,
              ),
              onPressed: playerService.togglePlayPause,
            ),
          ],
        ),
      ),
    );
  }
}
