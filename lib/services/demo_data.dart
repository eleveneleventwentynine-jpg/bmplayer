import '../models/media_item.dart';
import '../models/playlist.dart';

/// Placeholder catalogue so every screen has real-looking content to
/// render out of the box. Swap [demoLibrary] for `on_audio_query` results
/// and [demoStreamingResults] for a real [StreamingSource] implementation
/// when wiring this up to actual media.
final List<BmMediaItem> demoLibrary = [
  const BmMediaItem(
    id: 'a1',
    title: 'Night Drive',
    artist: 'Kelora',
    album: 'Afterglow',
    kind: MediaKind.audio,
    origin: MediaOrigin.local,
    sourceUri: '/storage/emulated/0/Music/night_drive.mp3',
    artworkUri: 'https://picsum.photos/seed/bm-a1/600/600',
    duration: const Duration(minutes: 3, seconds: 42),
    bitrateKbps: 320,
  ),
  const BmMediaItem(
    id: 'a2',
    title: 'Glass Cities',
    artist: 'Fault Line',
    album: 'Glass Cities EP',
    kind: MediaKind.audio,
    origin: MediaOrigin.local,
    sourceUri: '/storage/emulated/0/Music/glass_cities.mp3',
    artworkUri: 'https://picsum.photos/seed/bm-a2/600/600',
    duration: const Duration(minutes: 4, seconds: 5),
    bitrateKbps: 256,
  ),
  const BmMediaItem(
    id: 'a3',
    title: 'Low Orbit',
    artist: 'Halide',
    album: 'Low Orbit',
    kind: MediaKind.audio,
    origin: MediaOrigin.local,
    sourceUri: '/storage/emulated/0/Music/low_orbit.mp3',
    artworkUri: 'https://picsum.photos/seed/bm-a3/600/600',
    duration: const Duration(minutes: 2, seconds: 58),
    bitrateKbps: 320,
  ),
  const BmMediaItem(
    id: 'v1',
    title: 'Dar es Salaam Timelapse',
    artist: 'Field Notes Studio',
    kind: MediaKind.video,
    origin: MediaOrigin.local,
    sourceUri: '/storage/emulated/0/Movies/dar_timelapse.mp4',
    artworkUri: 'https://picsum.photos/seed/bm-v1/800/450',
    duration: const Duration(minutes: 6, seconds: 21),
  ),
  const BmMediaItem(
    id: 'a4',
    title: 'Paper Moons',
    artist: 'Kelora',
    album: 'Afterglow',
    kind: MediaKind.audio,
    origin: MediaOrigin.local,
    sourceUri: '/storage/emulated/0/Music/paper_moons.mp3',
    artworkUri: 'https://picsum.photos/seed/bm-a4/600/600',
    duration: const Duration(minutes: 3, seconds: 15),
    bitrateKbps: 320,
  ),
  const BmMediaItem(
    id: 'v2',
    title: 'Studio Session — Live Cut',
    artist: 'Fault Line',
    kind: MediaKind.video,
    origin: MediaOrigin.local,
    sourceUri: '/storage/emulated/0/Movies/studio_session.mp4',
    artworkUri: 'https://picsum.photos/seed/bm-v2/800/450',
    duration: const Duration(minutes: 12, seconds: 4),
  ),
];

final List<BmPlaylist> demoPlaylists = [
  BmPlaylist(
    id: 'p1',
    name: 'Late Night Build Sessions',
    items: demoLibrary.where((e) => e.kind == MediaKind.audio).toList(),
    coverUri: 'https://picsum.photos/seed/bm-p1/600/600',
  ),
  BmPlaylist(
    id: 'p2',
    name: 'Reference Footage',
    items: demoLibrary.where((e) => e.kind == MediaKind.video).toList(),
    coverUri: 'https://picsum.photos/seed/bm-p2/600/600',
  ),
];

/// Stand-in for results returned by a real [StreamingSource].
final List<BmMediaItem> demoStreamingResults = [
  const BmMediaItem(
    id: 's1',
    title: 'Open Water',
    artist: 'Marrow',
    kind: MediaKind.audio,
    origin: MediaOrigin.network,
    sourceUri: 'https://example-cdn.com/stream/open-water.mp3',
    artworkUri: 'https://picsum.photos/seed/bm-s1/600/600',
    duration: const Duration(minutes: 3, seconds: 51),
    sourceLabel: 'Direct link',
  ),
  const BmMediaItem(
    id: 's2',
    title: 'Concrete Bloom',
    artist: 'Halide',
    kind: MediaKind.audio,
    origin: MediaOrigin.network,
    sourceUri: 'https://example-cdn.com/stream/concrete-bloom.mp3',
    artworkUri: 'https://picsum.photos/seed/bm-s2/600/600',
    duration: const Duration(minutes: 4, seconds: 22),
    sourceLabel: 'SoundCloud',
  ),
  const BmMediaItem(
    id: 's3',
    title: 'Rooftop Sessions Vol. 3',
    artist: 'Various Artists',
    kind: MediaKind.video,
    origin: MediaOrigin.network,
    sourceUri: 'https://example-cdn.com/stream/rooftop-sessions-3.mp4',
    artworkUri: 'https://picsum.photos/seed/bm-s3/800/450',
    duration: const Duration(minutes: 28, seconds: 10),
    sourceLabel: 'Direct link',
  ),
];
