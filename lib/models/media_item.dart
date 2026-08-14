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

  /// Serialized for storage (playlists, favorites) in [DatabaseService].
  /// Network items are safe to persist this way even though their
  /// [sourceUri] may go stale — playback call sites re-resolve network
  /// items through their [StreamingSource] before playing rather than
  /// trusting a stored URI.
  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'artist': artist,
        'album': album,
        'kind': kind.name,
        'origin': origin.name,
        'sourceUri': sourceUri,
        'artworkUri': artworkUri,
        'durationMs': duration?.inMilliseconds,
        'bitrateKbps': bitrateKbps,
        'sizeBytes': sizeBytes,
        'sourceLabel': sourceLabel,
      };

  factory BmMediaItem.fromJson(Map<String, dynamic> json) => BmMediaItem(
        id: json['id'] as String,
        title: json['title'] as String,
        artist: json['artist'] as String,
        album: json['album'] as String?,
        kind: MediaKind.values.byName(json['kind'] as String),
        origin: MediaOrigin.values.byName(json['origin'] as String),
        sourceUri: json['sourceUri'] as String,
        artworkUri: json['artworkUri'] as String?,
        duration: json['durationMs'] != null
            ? Duration(milliseconds: json['durationMs'] as int)
            : null,
        bitrateKbps: json['bitrateKbps'] as int?,
        sizeBytes: json['sizeBytes'] as int?,
        sourceLabel: json['sourceLabel'] as String?,
      );
}
