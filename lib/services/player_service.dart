import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:video_player/video_player.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:photo_manager/photo_manager.dart' as pm;

import '../models/media_item.dart';

enum RepeatMode { off, all, one }

/// Immutable snapshot of everything the UI needs to render playback state.
@immutable
class PlaybackState {
  const PlaybackState({
    this.queue = const [],
    this.currentIndex = -1,
    this.isPlaying = false,
    this.isBuffering = false,
    this.position = Duration.zero,
    this.bufferedPosition = Duration.zero,
    this.shuffle = false,
    this.repeatMode = RepeatMode.off,
    this.ambientTint,
    this.videoController,
  });

  final List<BmMediaItem> queue;
  final int currentIndex;
  final bool isPlaying;
  final bool isBuffering;
  final Duration position;
  final Duration bufferedPosition;
  final bool shuffle;
  final RepeatMode repeatMode;

  /// Dominant color pulled from the current item's artwork, used to drive
  /// the Ambient Bloom background.
  final Color? ambientTint;

  /// Live video controller when [current]?.kind == MediaKind.video.
  final VideoPlayerController? videoController;

  BmMediaItem? get current =>
      (currentIndex >= 0 && currentIndex < queue.length)
          ? queue[currentIndex]
          : null;

  Duration get duration => current?.duration ?? Duration.zero;

  double get progress {
    final total = duration.inMilliseconds;
    if (total <= 0) return 0;
    return (position.inMilliseconds / total).clamp(0.0, 1.0);
  }

  PlaybackState copyWith({
    List<BmMediaItem>? queue,
    int? currentIndex,
    bool? isPlaying,
    bool? isBuffering,
    Duration? position,
    Duration? bufferedPosition,
    bool? shuffle,
    RepeatMode? repeatMode,
    Color? ambientTint,
    VideoPlayerController? videoController,
    bool clearVideoController = false,
  }) {
    return PlaybackState(
      queue: queue ?? this.queue,
      currentIndex: currentIndex ?? this.currentIndex,
      isPlaying: isPlaying ?? this.isPlaying,
      isBuffering: isBuffering ?? this.isBuffering,
      position: position ?? this.position,
      bufferedPosition: bufferedPosition ?? this.bufferedPosition,
      shuffle: shuffle ?? this.shuffle,
      repeatMode: repeatMode ?? this.repeatMode,
      ambientTint: ambientTint ?? this.ambientTint,
      videoController: clearVideoController
          ? null
          : (videoController ?? this.videoController),
    );
  }
}

/// Single source of truth for playback. Screens read [PlaybackState] via
/// [playerServiceProvider] and never touch just_audio / video_player
/// directly — this keeps the audio and video engines fully interchangeable
/// behind one API.
class PlayerService extends StateNotifier<PlaybackState> {
  PlayerService() : super(const PlaybackState()) {
    _audioPlayer.playerStateStream.listen(_onAudioPlayerState);
    _audioPlayer.positionStream.listen((p) {
      if (state.current?.kind == MediaKind.audio) {
        state = state.copyWith(position: p);
      }
    });
    _audioPlayer.bufferedPositionStream.listen((p) {
      if (state.current?.kind == MediaKind.audio) {
        state = state.copyWith(bufferedPosition: p);
      }
    });
  }

  final AudioPlayer _audioPlayer = AudioPlayer();
  VideoPlayerController? _videoController;

  void _onAudioPlayerState(PlayerState s) {
    state = state.copyWith(
      isPlaying: s.playing,
      isBuffering: s.processingState == ProcessingState.buffering ||
          s.processingState == ProcessingState.loading,
    );
    if (s.processingState == ProcessingState.completed) {
      _onTrackFinished();
    }
  }

  Future<void> setQueue(List<BmMediaItem> items, {int startIndex = 0}) async {
    state = state.copyWith(queue: items, currentIndex: startIndex);
    await _loadCurrent();
  }

  Future<void> playItemNow(BmMediaItem item, {List<BmMediaItem>? queue}) async {
    final q = queue ?? [item];
    final idx = q.indexWhere((e) => e.id == item.id);
    state = state.copyWith(queue: q, currentIndex: idx < 0 ? 0 : idx);
    await _loadCurrent();
  }

  Future<void> _loadCurrent() async {
    final item = state.current;
    if (item == null) return;

    // Tear down whichever engine isn't needed for this item.
    await _videoController?.dispose();
    _videoController = null;
    state = state.copyWith(clearVideoController: true, position: Duration.zero);

    if (item.kind == MediaKind.audio) {
      // Local audio from on_audio_query comes back as a content:// URI on
      // Android, not a bare file path — parse rather than assume a file
      // scheme so both cases work.
      final uri = item.origin == MediaOrigin.network
          ? Uri.parse(item.sourceUri)
          : (Uri.tryParse(item.sourceUri)?.hasScheme ?? false)
              ? Uri.parse(item.sourceUri)
              : Uri.file(item.sourceUri);
      await _audioPlayer.setAudioSource(AudioSource.uri(uri));
      await _audioPlayer.play();
    } else {
      final controller = item.origin == MediaOrigin.network
          ? VideoPlayerController.networkUrl(Uri.parse(item.sourceUri))
          : VideoPlayerController.file(File(item.sourceUri));
      await controller.initialize();
      controller.addListener(_onVideoTick);
      await controller.play();
      _videoController = controller;
      state = state.copyWith(videoController: controller, isPlaying: true);
    }

    unawaited(_extractAmbientTint(item));
  }

  void _onVideoTick() {
    final c = _videoController;
    if (c == null || !c.value.isInitialized) return;
    state = state.copyWith(
      position: c.value.position,
      isPlaying: c.value.isPlaying,
      isBuffering: c.value.isBuffering,
    );
    if (c.value.position >= c.value.duration &&
        c.value.duration > Duration.zero) {
      _onTrackFinished();
    }
  }

  final OnAudioQuery _audioQuery = OnAudioQuery();

  /// Resolves whichever artwork scheme the item uses (network URL,
  /// on_audio_query id, or a photo_manager video thumbnail) into an
  /// [ImageProvider], then extracts its dominant color for the Ambient
  /// Bloom background. Mirrors the scheme handling in [MediaArtwork] so
  /// the tint always matches what's actually rendered on screen.
  Future<void> _extractAmbientTint(BmMediaItem item) async {
    final uri = item.artworkUri;
    if (uri == null) return;
    try {
      ImageProvider? provider;

      if (uri.startsWith('http')) {
        provider = NetworkImage(uri);
      } else if (uri.startsWith('audioquery://')) {
        final id = int.tryParse(uri.substring('audioquery://'.length));
        if (id != null) {
          final bytes = await _audioQuery.queryArtwork(id, ArtworkType.AUDIO);
          if (bytes != null) provider = MemoryImage(bytes);
        }
      } else if (uri.startsWith('videothumb://')) {
        final id = uri.substring('videothumb://'.length);
        final asset = await pm.AssetEntity.fromId(id);
        final bytes = await asset?.thumbnailDataWithSize(
          const pm.ThumbnailSize(200, 200),
        );
        if (bytes != null) provider = MemoryImage(bytes);
      }

      if (provider == null) return;
      final palette = await PaletteGenerator.fromImageProvider(provider);
      final color = palette.dominantColor?.color ?? palette.vibrantColor?.color;
      if (color != null && state.current?.id == item.id) {
        state = state.copyWith(ambientTint: color);
      }
    } catch (_) {
      // Artwork unavailable or not decodable — keep the resting gradient.
    }
  }

  void _onTrackFinished() {
    if (state.repeatMode == RepeatMode.one) {
      seek(Duration.zero);
      _audioPlayer.play();
      return;
    }
    next();
  }

  Future<void> togglePlayPause() async {
    if (state.current?.kind == MediaKind.audio) {
      state.isPlaying ? await _audioPlayer.pause() : await _audioPlayer.play();
    } else {
      final c = _videoController;
      if (c == null) return;
      state.isPlaying ? await c.pause() : await c.play();
      state = state.copyWith(isPlaying: !state.isPlaying);
    }
  }

  Future<void> seek(Duration position) async {
    if (state.current?.kind == MediaKind.audio) {
      await _audioPlayer.seek(position);
    } else {
      await _videoController?.seekTo(position);
    }
    state = state.copyWith(position: position);
  }

  Future<void> next() async {
    if (state.queue.isEmpty) return;
    int nextIndex = state.currentIndex + 1;
    if (nextIndex >= state.queue.length) {
      if (state.repeatMode == RepeatMode.all) {
        nextIndex = 0;
      } else {
        return;
      }
    }
    state = state.copyWith(currentIndex: nextIndex);
    await _loadCurrent();
  }

  Future<void> previous() async {
    if (state.queue.isEmpty) return;
    // Restart current track if we're more than 3s in, like most players.
    if (state.position > const Duration(seconds: 3)) {
      await seek(Duration.zero);
      return;
    }
    final prevIndex = state.currentIndex - 1;
    if (prevIndex < 0) return;
    state = state.copyWith(currentIndex: prevIndex);
    await _loadCurrent();
  }

  void toggleShuffle() => state = state.copyWith(shuffle: !state.shuffle);

  void cycleRepeatMode() {
    final next = switch (state.repeatMode) {
      RepeatMode.off => RepeatMode.all,
      RepeatMode.all => RepeatMode.one,
      RepeatMode.one => RepeatMode.off,
    };
    state = state.copyWith(repeatMode: next);
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _videoController?.dispose();
    super.dispose();
  }
}

void unawaited(Future<void> future) {}
