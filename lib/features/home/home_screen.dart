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
    final playlists = ref.watch(playlistsControllerProvider);
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
              itemCount: playlists.length + 1,
              separatorBuilder: (_, __) => const SizedBox(width: 14),
              itemBuilder: (context, i) {
                if (i == playlists.length) {
                  return _CreatePlaylistCard(
                    onCreate: (name) =>
                        ref.read(playlistsControllerProvider.notifier).create(name),
                  );
                }
                final pl = playlists[i];
                return GestureDetector(
                  onLongPress: () => _showPlaylistOptions(context, ref, pl.id, pl.name),
                  child: GlassContainer(
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

class _CreatePlaylistCard extends StatelessWidget {
  const _CreatePlaylistCard({required this.onCreate});
  final ValueChanged<String> onCreate;

  Future<void> _openDialog(BuildContext context) async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.void1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('New playlist'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Playlist name'),
          onSubmitted: (v) => Navigator.pop(context, v),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Create'),
          ),
        ],
      ),
    );
    if (name != null && name.trim().isNotEmpty) onCreate(name.trim());
  }

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      borderRadius: 18,
      onTap: () => _openDialog(context),
      child: const SizedBox(
        width: 128,
        height: 168,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.add_rounded, color: AppColors.driftAqua, size: 28),
              SizedBox(height: 6),
              Text('New playlist', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
            ],
          ),
        ),
      ),
    );
  }
}

Future<void> _showPlaylistOptions(
  BuildContext context,
  WidgetRef ref,
  String playlistId,
  String currentName,
) async {
  await showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (context) => Padding(
      padding: const EdgeInsets.all(16),
      child: GlassContainer(
        borderRadius: 20,
        strong: true,
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit_rounded),
              title: const Text('Rename'),
              onTap: () async {
                Navigator.pop(context);
                final controller = TextEditingController(text: currentName);
                final name = await showDialog<String>(
                  context: context,
                  builder: (context) => AlertDialog(
                    backgroundColor: AppColors.void1,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20)),
                    title: const Text('Rename playlist'),
                    content: TextField(controller: controller, autofocus: true),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel')),
                      FilledButton(
                          onPressed: () => Navigator.pop(context, controller.text),
                          child: const Text('Save')),
                    ],
                  ),
                );
                if (name != null && name.trim().isNotEmpty) {
                  ref
                      .read(playlistsControllerProvider.notifier)
                      .rename(playlistId, name.trim());
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline_rounded, color: AppColors.danger),
              title: const Text('Delete playlist'),
              onTap: () {
                Navigator.pop(context);
                ref.read(playlistsControllerProvider.notifier).delete(playlistId);
              },
            ),
          ],
        ),
      ),
    ),
  );
}
