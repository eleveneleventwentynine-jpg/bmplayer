import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/animated_waveform.dart';
import '../../core/widgets/media_artwork.dart';
import '../../state/providers.dart';

/// Opens the queue as a glass bottom sheet. Called from the now-playing
/// screen's "more" action.
Future<void> showQueueSheet(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) => const _QueueSheet(),
  );
}

class _QueueSheet extends ConsumerWidget {
  const _QueueSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playback = ref.watch(playerServiceProvider);
    final playerService = ref.read(playerServiceProvider.notifier);
    final queue = playback.queue;

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      expand: false,
      builder: (context, scrollController) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [AppColors.void1, AppColors.void2],
              ),
            ),
            child: Column(
              children: [
                const SizedBox(height: 10),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.glassBorderStrong,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Up next', style: Theme.of(context).textTheme.headlineMedium),
                      Text(
                        '${queue.length} ${queue.length == 1 ? 'item' : 'items'}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: queue.isEmpty
                      ? Center(
                          child: Text('Queue is empty',
                              style: Theme.of(context).textTheme.bodyMedium),
                        )
                      : ReorderableListView.builder(
                          scrollController: scrollController,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          itemCount: queue.length,
                          onReorder: playerService.reorderQueue,
                          itemBuilder: (context, i) {
                            final item = queue[i];
                            final isCurrent = i == playback.currentIndex;
                            return Padding(
                              key: ValueKey(item.id),
                              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                              child: Material(
                                color: isCurrent
                                    ? AppColors.glassFillStrong
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(14),
                                child: ListTile(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  onTap: () => playerService.jumpTo(i),
                                  leading: MediaArtwork(
                                    item: item,
                                    width: 44,
                                    height: 44,
                                    borderRadius: 10,
                                  ),
                                  title: Text(
                                    item.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: isCurrent
                                          ? AppColors.driftAqua
                                          : AppColors.textPrimary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  subtitle: Text(
                                    item.artist,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (isCurrent)
                                        Padding(
                                          padding: const EdgeInsets.only(right: 10),
                                          child: AnimatedWaveform(
                                            isPlaying: playback.isPlaying,
                                            barCount: 3,
                                            height: 14,
                                          ),
                                        ),
                                      IconButton(
                                        icon: const Icon(Icons.close_rounded, size: 18),
                                        onPressed: () => playerService.removeFromQueue(i),
                                      ),
                                      const Icon(Icons.drag_handle_rounded,
                                          color: AppColors.textFaint),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
