/// The kind of media a [BmMediaItem] represents. Determines which player
/// engine [PlayerService] routes it to (just_audio vs video_player).
enum MediaKind { audio, video }

/// Where a [BmMediaItem] came from. Local items are read from the device
/// library; network items come from a [StreamingSource].
enum MediaOrigin { local, network }

/// A single playable unit — a song, a video, a podcast episode, a stream.
/// This is the one model every screen in bmplayer works with, regardless
/// of whether it came from the local library or a streaming source.
class BmMediaItem {
  const BmMediaItem({
    required this.id,
    required this.title,
    required this.artist,
    required this.kind,
    required this.origin,
    required this.sourceUri,
    this.album,
    this.artworkUri,
    this.duration,
    this.bitrateKbps,
    this.sizeBytes,
    this.sourceLabel,
  });

  final String id;
  final String title;
  final String artist;
  final String? album;
  final MediaKind kind;
  final MediaOrigin origin;

  /// Local file path or network URL, depending on [origin].
  final String sourceUri;

  /// Local file path or network URL for cover/thumbnail art.
  final String? artworkUri;

  final Duration? duration;
  final int? bitrateKbps;
  final int? sizeBytes;

  /// Human-readable name of the streaming source this came from, e.g.
  /// "SoundCloud" or "Direct link" — shown as a metadata chip.
  final String? sourceLabel;

  String get durationLabel {
    if (duration == null) return '--:--';
    final m = duration!.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = duration!.inSeconds.remainder(60).toString().padLeft(2, '0');
    final h = duration!.inHours;
    return h > 0 ? '$h:$m:$s' : '$m:$s';
  }

  String get subtitleLabel => album != null ? '$artist · $album' : artist;

  BmMediaItem copyWith({
    String? title,
    String? artist,
    String? album,
    String? artworkUri,
    Duration? duration,
  }) {
    return BmMediaItem(
      id: id,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      album: album ?? this.album,
      kind: kind,
      origin: origin,
      sourceUri: sourceUri,
      artworkUri: artworkUri ?? this.artworkUri,
      duration: duration ?? this.duration,
      bitrateKbps: bitrateKbps,
      sizeBytes: sizeBytes,
      sourceLabel: sourceLabel,
    );
  }
}
