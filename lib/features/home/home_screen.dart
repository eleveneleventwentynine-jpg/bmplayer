import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/glass_container.dart';
import '../../models/media_item.dart';
import '../../state/library_controller.dart';
import '../../state/providers.dart';
import 'widgets/continue_listening_carousel.dart';
import 'widgets/media_row.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final libraryState = ref.watch(libraryControllerProvider);
    final continueListening = libraryState.continueListening;
    final library = libraryState.items;
    final playlists = ref.watch(playlistsProvider);
    final playback = ref.watch(playerServiceProvider);
    final playerService = ref.read(playerServiceProvider.notifier);

    void play(BmMediaItem item, {required List<BmMediaItem> queue}) {
      playerService.playItemNow(item, queue: queue);
      ref.read(libraryControllerProvider.notifier).recordPlayed(item.id);
    }

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          pinned: false,
          floating: true,
          backgroundColor: Colors.transparent,
          elevation: 0,
          toolbarHeight: 76,
          title: Row(
            children: [
              Text('bmplayer', style: Theme.of(context).textTheme.displayMedium),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.search_rounded),
              onPressed: () => ref.read(navIndexProvider.notifier).state = 2,
            ),
            const SizedBox(width: 8),
          ],
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
            child: Text('Continue listening',
                style: Theme.of(context).textTheme.headlineMedium),
          ),
        ),
        SliverToBoxAdapter(
          child: ContinueListeningCarousel(
            items: continueListening,
            onTap: (item) => play(item, queue: continueListening),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 28, 20, 12),
            child: Text('Your library',
                style: Theme.of(context).textTheme.headlineMedium),
          ),
        ),
        if (libraryState.status == LibraryLoadStatus.permissionDenied)
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverToBoxAdapter(
              child: GlassContainer(
                borderRadius: 16,
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline_rounded,
                        color: AppColors.flareCoral, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Media access is off, so this shows sample tracks. '
                        'Enable it in system settings to see your own library.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverToBoxAdapter(
            child: GlassContainer(
              borderRadius: 20,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              child: Column(
                children: library
                    .map((item) => MediaRow(
                          item: item,
                          isCurrent: playback.current?.id == item.id,
                          isPlaying:
                              playback.isPlaying && playback.current?.id == item.id,
                          onTap: () => play(item, queue: library),
                        ))
                    .toList(),
              ),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 28, 20, 12),
            child: Text('Playlists',
                style: Theme.of(context).textTheme.headlineMedium),
          ),
        ),
        SliverToBoxAdapter(
          child: SizedBox(
            height: 168,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: playlists.length,
              separatorBuilder: (_, __) => const SizedBox(width: 14),
              itemBuilder: (context, i) {
                final pl = playlists[i];
                return GlassContainer(
                  borderRadius: 18,
                  onTap: () {
                    if (pl.items.isNotEmpty) {
                      play(pl.items.first, queue: pl.items);
                    }
                  },
                  child: SizedBox(
                    width: 128,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(18)),
                          child: pl.coverUri != null
                              ? CachedNetworkImage(
                                  imageUrl: pl.coverUri!,
                                  height: 100,
                                  width: 128,
                                  fit: BoxFit.cover,
                                )
                              : Container(
                                  height: 100,
                                  color: AppColors.glassFillStrong,
                                ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                pl.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.bodyLarge,
                              ),
                              Text('${pl.trackCount} tracks',
                                  style: Theme.of(context).textTheme.bodyMedium),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 140)),
      ],
    );
  }
}
