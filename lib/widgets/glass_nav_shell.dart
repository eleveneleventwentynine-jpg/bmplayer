import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/app_colors.dart';
import '../core/widgets/ambient_background.dart';
import '../core/widgets/glass_container.dart';
import '../features/discover/discover_screen.dart';
import '../features/home/home_screen.dart';
import '../features/library/library_screen.dart';
import '../features/now_playing/now_playing_screen.dart';
import '../state/library_controller.dart';
import '../state/providers.dart';
import 'mini_player.dart';

class GlassNavShell extends ConsumerStatefulWidget {
  const GlassNavShell({super.key});

  @override
  ConsumerState<GlassNavShell> createState() => _GlassNavShellState();
}

class _GlassNavShellState extends ConsumerState<GlassNavShell> {
  static const _pages = [
    HomeScreen(),
    LibraryScreen(),
    DiscoverScreen(),
  ];

  static const _navItems = [
    (icon: Icons.home_rounded, label: 'Home'),
    (icon: Icons.library_music_rounded, label: 'Library'),
    (icon: Icons.explore_rounded, label: 'Discover'),
  ];

  @override
  void initState() {
    super.initState();
    // Kick off the real device library scan once, right after first frame,
    // regardless of which tab the person lands on.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(libraryControllerProvider.notifier).load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final navIndex = ref.watch(navIndexProvider);
    final expanded = ref.watch(playerExpandedProvider);
    final playback = ref.watch(playerServiceProvider);
    final hasNowPlaying = playback.current != null;

    return AmbientBackground(
      tint: playback.ambientTint,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBody: true,
        body: Stack(
          children: [
            IndexedStack(index: navIndex, children: _pages),

            // Floating dock: mini-player + bottom nav, both glass.
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (hasNowPlaying) ...[
                    const MiniPlayer(),
                    const SizedBox(height: 10),
                  ],
                  GlassContainer(
                    borderRadius: 26,
                    strong: true,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: List.generate(_navItems.length, (i) {
                        final item = _navItems[i];
                        final active = i == navIndex;
                        return _NavButton(
                          icon: item.icon,
                          label: item.label,
                          active: active,
                          onTap: () =>
                              ref.read(navIndexProvider.notifier).state = i,
                        );
                      }),
                    ),
                  ),
                ],
              ),
            ),

            // Now-playing sheet, slides up from the bottom over everything.
            if (hasNowPlaying)
              AnimatedPositioned(
                duration: const Duration(milliseconds: 380),
                curve: Curves.easeOutCubic,
                left: 0,
                right: 0,
                top: expanded ? 0 : MediaQuery.of(context).size.height,
                bottom: 0,
                child: IgnorePointer(
                  ignoring: !expanded,
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 250),
                    opacity: expanded ? 1 : 0,
                    child: DecoratedBox(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [AppColors.void1, AppColors.void2],
                        ),
                      ),
                      child: const NowPlayingScreen(),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: active ? AppColors.glassFillStrong : Colors.transparent,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 22,
              color: active ? AppColors.driftAqua : AppColors.textMuted,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: active ? AppColors.driftAqua : AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
