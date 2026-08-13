import 'media_item.dart';

class BmPlaylist {
  const BmPlaylist({
    required this.id,
    required this.name,
    required this.items,
    this.coverUri,
  });

  final String id;
  final String name;
  final List<BmMediaItem> items;
  final String? coverUri;

  int get trackCount => items.length;

  Duration get totalDuration => items.fold(
        Duration.zero,
        (sum, item) => sum + (item.duration ?? Duration.zero),
      );
}

/// A pluggable network source (SoundCloud, a self-hosted server, a direct
/// link resolver, yt-dlp-backed extractor, etc). Implement this to add a
/// new streaming backend without touching any UI code — screens only ever
/// talk to [BmMediaItem] and this interface.
abstract class StreamingSource {
  String get id;
  String get displayName;

  Future<List<BmMediaItem>> search(String query);

  /// Resolve a possibly-expiring playable URL right before playback starts.
  Future<String> resolvePlaybackUri(BmMediaItem item);
}
