import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/glass_container.dart';
import '../../models/media_item.dart';
import '../../state/discover_controller.dart';
import '../../state/library_controller.dart';
import '../../state/providers.dart';
import '../home/widgets/media_row.dart';

class DiscoverScreen extends ConsumerStatefulWidget {
  const DiscoverScreen({super.key});

  @override
  ConsumerState<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends ConsumerState<DiscoverScreen> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _playResolved(BmMediaItem item) async {
    final resolved = await ref
        .read(discoverControllerProvider.notifier)
        .resolveForPlayback(item);
    ref
        .read(playerServiceProvider.notifier)
        .playItemNow(resolved, queue: [resolved]);
    ref.read(libraryControllerProvider.notifier).recordPlayed(resolved.id);
  }

  @override
  Widget build(BuildContext context) {
    final discover = ref.watch(discoverControllerProvider);
    final playback = ref.watch(playerServiceProvider);

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          pinned: false,
          floating: true,
          backgroundColor: Colors.transparent,
          elevation: 0,
          toolbarHeight: 76,
          title: Text('Discover', style: Theme.of(context).textTheme.displayMedium),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
          sliver: SliverToBoxAdapter(
            child: GlassContainer(
              borderRadius: 16,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: TextField(
                controller: _controller,
                textInputAction: TextInputAction.search,
                onSubmitted: (query) =>
                    ref.read(discoverControllerProvider.notifier).search(query),
                style: Theme.of(context).textTheme.bodyLarge,
                decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Search YouTube…',
                  hintStyle: TextStyle(color: AppColors.textFaint),
                  icon: const Icon(Icons.search_rounded, color: AppColors.textMuted),
                  suffixIcon: discover.status == DiscoverStatus.searching
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.driftAqua,
                            ),
                          ),
                        )
                      : null,
                ),
              ),
            ),
          ),
        ),
        if (discover.status == DiscoverStatus.error)
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverToBoxAdapter(
              child: GlassContainer(
                borderRadius: 16,
                padding: const EdgeInsets.all(14),
                child: Text(
                  "Couldn't reach YouTube — check your connection and try again.",
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ),
          ),
        if (discover.status == DiscoverStatus.idle)
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Text(
                  'Search for a song, artist, or video to stream.',
                  style: Theme.of(context).textTheme.bodyMedium,
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
                children: discover.results.map((item) {
                  final isResolving = discover.resolvingItemId == item.id;
                  return Stack(
                    alignment: Alignment.centerRight,
                    children: [
                      MediaRow(
                        item: item,
                        isCurrent: playback.current?.id == item.id,
                        isPlaying: playback.isPlaying &&
                            playback.current?.id == item.id,
                        onTap: isResolving ? () {} : () => _playResolved(item),
                      ),
                      if (isResolving)
                        const Padding(
                          padding: EdgeInsets.only(right: 44),
                          child: SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.driftAqua,
                            ),
                          ),
                        ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 140)),
      ],
    );
  }
}
