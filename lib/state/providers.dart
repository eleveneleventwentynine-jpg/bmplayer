import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/playlist.dart';
import '../services/demo_data.dart';
import '../services/library_service.dart';
import '../services/player_service.dart';
import '../services/youtube_streaming_source.dart';
import 'discover_controller.dart';
import 'library_controller.dart';

final playerServiceProvider =
    StateNotifierProvider<PlayerService, PlaybackState>(
  (ref) => PlayerService(),
);

// --- Local library -----------------------------------------------------

final libraryServiceProvider = Provider<LibraryService>((ref) => LibraryService());

final libraryControllerProvider =
    StateNotifierProvider<LibraryController, LibraryState>(
  (ref) => LibraryController(ref.read(libraryServiceProvider)),
);

final playlistsProvider = Provider<List<BmPlaylist>>((ref) => demoPlaylists);

// --- Streaming / discover -----------------------------------------------

final streamingSourceProvider = Provider<StreamingSource>((ref) {
  final source = YoutubeStreamingSource();
  ref.onDispose(source.dispose);
  return source;
});

final discoverControllerProvider =
    StateNotifierProvider<DiscoverController, DiscoverState>(
  (ref) => DiscoverController(ref.read(streamingSourceProvider)),
);

// --- Navigation / UI state ----------------------------------------------

/// Which bottom-nav tab is active.
final navIndexProvider = StateProvider<int>((ref) => 0);

/// Whether the now-playing sheet is expanded to full screen.
final playerExpandedProvider = StateProvider<bool>((ref) => false);
