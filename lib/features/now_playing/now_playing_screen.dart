import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/animated_waveform.dart';
import '../../core/widgets/glass_container.dart';
import '../../core/widgets/media_artwork.dart';
import '../../models/media_item.dart';
import '../../services/player_service.dart';
import '../../state/providers.dart';
import 'queue_screen.dart';
import 'widgets/glass_seek_bar.dart';

class NowPlayingScreen extends ConsumerWidget {
  const NowPlayingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playback = ref.watch(playerServiceProvider);
    final playerService = ref.read(playerServiceProvider.notifier);
    final item = playback.current;
    final favorites = ref.watch(favoritesControllerProvider);
    final isFavorite = item != null && favorites.any((e) => e.id == item.id);

    if (item == null) {
      return const SizedBox.shrink();
    }

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 32),
                  onPressed: () =>
                      ref.read(playerExpandedProvider.notifier).state = false,
                ),
                Text(
                  item.sourceLabel ??
                      (item.origin == MediaOrigin.local
                          ? 'On this device'
                          : 'Streaming'),
                  style: Theme.of(context).textTheme.labelSmall,
                ),
                IconButton(
                  icon: const Icon(Icons.more_horiz_rounded),
                  onPressed: () => showQueueSheet(context),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: Center(
                child: item.kind == MediaKind.video &&
                        playback.videoController != null
                    ? _VideoStage(controller: playback.videoController!)
                    : _ArtworkStage(item: item),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.displayMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.subtitleLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ],
                  ),
                ),
                AnimatedWaveform(isPlaying: playback.isPlaying, height: 26),
                const SizedBox(width: 4),
                IconButton(
                  icon: Icon(
                    isFavorite
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    color: isFavorite ? AppColors.flareCoral : null,
                  ),
                  onPressed: () => ref
                      .read(favoritesControllerProvider.notifier)
                      .toggle(item),
                ),
              ],
            ),
            const SizedBox(height: 8),
            GlassSeekBar(
              position: playback.position,
              duration: playback.duration,
              onSeek: playerService.seek,
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: Icon(
                    Icons.shuffle_rounded,
                    color: playback.shuffle
                        ? AppColors.driftAqua
                        : AppColors.textMuted,
                  ),
                  onPressed: playerService.toggleShuffle,
                ),
                IconButton(
                  iconSize: 34,
                  icon: const Icon(Icons.skip_previous_rounded),
                  onPressed: playerService.previous,
                ),
                GestureDetector(
                  onTap: playerService.togglePlayPause,
                  child: GlassContainer(
                    borderRadius: 40,
                    strong: true,
                    padding: const EdgeInsets.all(18),
                    gradientOverlay: AppColors.pulseGradient,
                    child: Icon(
                      playback.isPlaying
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded,
                      size: 34,
                      color: Colors.white,
                    ),
                  ),
                ),
                IconButton(
                  iconSize: 34,
                  icon: const Icon(Icons.skip_next_rounded),
                  onPressed: playerService.next,
                ),
                IconButton(
                  icon: Icon(
                    switch (playback.repeatMode) {
                      RepeatMode.off => Icons.repeat_rounded,
                      RepeatMode.all => Icons.repeat_rounded,
                      RepeatMode.one => Icons.repeat_one_rounded,
                    },
                    color: playback.repeatMode == RepeatMode.off
                        ? AppColors.textMuted
                        : AppColors.driftAqua,
                  ),
                  onPressed: playerService.cycleRepeatMode,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ArtworkStage extends StatelessWidget {
  const _ArtworkStage({required this.item});
  final BmMediaItem item;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: GlassContainer(
        borderRadius: 28,
        strong: true,
        child: MediaArtwork(item: item, fit: BoxFit.cover),
      ),
    );
  }
}

class _VideoStage extends StatelessWidget {
  const _VideoStage({required this.controller});
  final VideoPlayerController controller;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: AspectRatio(
        aspectRatio: controller.value.isInitialized
            ? controller.value.aspectRatio
            : 16 / 9,
        child: VideoPlayer(controller),
      ),
    );
  }
}
