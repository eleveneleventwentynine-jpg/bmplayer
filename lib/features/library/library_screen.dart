import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/glass_container.dart';
import '../../models/media_item.dart';
import '../../state/library_controller.dart';
import '../../state/providers.dart';
import '../home/widgets/media_row.dart';

class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen> {
  @override
  void initState() {
    super.initState();
    // Kick off the real device scan once, the first time this tab mounts.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final status = ref.read(libraryControllerProvider).status;
      if (status == LibraryLoadStatus.initial) {
        ref.read(libraryControllerProvider.notifier).load();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final libraryState = ref.watch(libraryControllerProvider);
    final favorites = ref.watch(favoritesControllerProvider);
    final playback = ref.watch(playerServiceProvider);
    final playerService = ref.read(playerServiceProvider.notifier);

    final audio =
        libraryState.items.where((e) => e.kind == MediaKind.audio).toList();
    final video =
        libraryState.items.where((e) => e.kind == MediaKind.video).toList();

    void play(BmMediaItem item, List<BmMediaItem> queue) {
      playerService.playItemNow(item, queue: queue);
      ref.read(libraryControllerProvider.notifier).recordPlayed(item.id);
    }

    return RefreshIndicator(
      color: AppColors.driftAqua,
      backgroundColor: AppColors.void1,
      onRefresh: () => ref.read(libraryControllerProvider.notifier).load(),
      child: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: false,
            floating: true,
            backgroundColor: Colors.transparent,
            elevation: 0,
            toolbarHeight: 76,
            title: Text('Library',
                style: Theme.of(context).textTheme.displayMedium),
            actions: [
              if (libraryState.status == LibraryLoadStatus.loading)
                const Padding(
                  padding: EdgeInsets.only(right: 20),
                  child: Center(
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.driftAqua,
                      ),
                    ),
                  ),
                )
              else
                IconButton(
                  icon: const Icon(Icons.refresh_rounded),
                  onPressed: () =>
                      ref.read(libraryControllerProvider.notifier).load(),
                ),
            ],
          ),
          if (libraryState.status == LibraryLoadStatus.permissionDenied)
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              sliver: SliverToBoxAdapter(
                child: GlassContainer(
                  borderRadius: 16,
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      const Icon(Icons.lock_outline_rounded,
                          color: AppColors.flareCoral, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          "Media permission was denied — showing sample "
                          "tracks. Grant access in system settings to scan "
                          "your own library.",
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          _sectionHeader(context, 'Songs'),
          _sectionCard(audio, playback, play),
          _sectionHeader(context, 'Videos'),
          _sectionCard(video, playback, play),
          if (favorites.isNotEmpty) ...[
            _sectionHeader(context, 'Favorites'),
            _sectionCard(favorites, playback, play),
          ],
          const SliverToBoxAdapter(child: SizedBox(height: 140)),
        ],
      ),
    );
  }

  SliverToBoxAdapter _sectionHeader(BuildContext context, String label) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
        child: Text(label, style: Theme.of(context).textTheme.headlineMedium),
      ),
    );
  }

  SliverPadding _sectionCard(
    List<BmMediaItem> items,
    dynamic playback,
    void Function(BmMediaItem, List<BmMediaItem>) onPlay,
  ) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      sliver: SliverToBoxAdapter(
        child: GlassContainer(
          borderRadius: 20,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          child: items.isEmpty
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Text('Nothing here yet.'),
                )
              : Column(
                  children: items
                      .map<Widget>((item) => MediaRow(
                            item: item,
                            isCurrent: playback.current?.id == item.id,
                            isPlaying: playback.isPlaying &&
                                playback.current?.id == item.id,
                            onTap: () => onPlay(item, items),
                          ))
                      .toList(),
                ),
        ),
      ),
    );
  }
}
