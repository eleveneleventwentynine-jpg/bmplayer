import 'package:youtube_explode_dart/youtube_explode_dart.dart';

import '../models/media_item.dart';
import '../models/playlist.dart';

/// A [StreamingSource] backed by `youtube_explode_dart` — a pure-Dart
/// YouTube client, so no platform-specific yt-dlp binary needs to be
/// bundled into the app. Search results carry metadata immediately;
/// the actual playable stream URL is resolved lazily in
/// [resolvePlaybackUri], right before playback, since YouTube's direct
/// media URLs are signed and expire.
class YoutubeStreamingSource implements StreamingSource {
  YoutubeStreamingSource() : _yt = YoutubeExplode();

  final YoutubeExplode _yt;

  @override
  String get id => 'youtube';

  @override
  String get displayName => 'YouTube';

  @override
  Future<List<BmMediaItem>> search(String query) async {
    if (query.trim().isEmpty) return [];
    final results = await _yt.search.search(query);

    return results.whereType<Video>().map((video) {
      return BmMediaItem(
        id: 'yt_${video.id.value}',
        title: video.title,
        artist: video.author,
        kind: MediaKind.video,
        origin: MediaOrigin.network,
        // Not directly playable yet — resolvePlaybackUri() swaps this for
        // a real, signed media URL right before playback starts. We keep
        // the watch URL here so it's still meaningful in the meantime
        // (e.g. for a "open in browser" fallback action).
        sourceUri: video.url,
        artworkUri: video.thumbnails.highResUrl,
        duration: video.duration,
        sourceLabel: 'YouTube',
      );
    }).toList();
  }

  @override
  Future<String> resolvePlaybackUri(BmMediaItem item) async {
    final videoId = VideoId(item.id.replaceFirst('yt_', ''));
    final manifest = await _yt.videos.streamsClient.getManifest(videoId);

    // Prefer a muxed (audio+video) stream so a single URL plays cleanly
    // in video_player without needing to merge separate audio/video
    // tracks client-side.
    if (manifest.muxed.isNotEmpty) {
      final stream = manifest.muxed.withHighestBitrate();
      return stream.url.toString();
    }

    // Fall back to the best audio-only stream (e.g. for audio-first
    // content where YouTube doesn't offer a muxed option).
    final audioStream = manifest.audioOnly.withHighestBitrate();
    return audioStream.url.toString();
  }

  void dispose() => _yt.close();
}
