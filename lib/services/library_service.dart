import 'dart:io';

import 'package:on_audio_query/on_audio_query.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:photo_manager/photo_manager.dart' as pm;

import '../models/media_item.dart';

enum LibraryPermissionStatus { unknown, granted, denied, permanentlyDenied }

/// Scans the device for playable audio and video and maps everything into
/// [BmMediaItem]. This is the only place in the app that talks to
/// `on_audio_query` / `photo_manager` directly — everything above it
/// (providers, screens) only ever sees [BmMediaItem].
class LibraryService {
  final OnAudioQuery _audioQuery = OnAudioQuery();

  /// Requests whatever media permissions the platform needs. Handles the
  /// Android 13+ granular media permissions as well as the legacy
  /// storage permission for older OS versions.
  Future<LibraryPermissionStatus> requestPermissions() async {
    if (Platform.isAndroid) {
      final audioStatus = await Permission.audio.request();
      final videoStatus = await Permission.videos.request();

      final granted = audioStatus.isGranted || videoStatus.isGranted;
      if (granted) return LibraryPermissionStatus.granted;

      if (audioStatus.isPermanentlyDenied ||
          videoStatus.isPermanentlyDenied) {
        return LibraryPermissionStatus.permanentlyDenied;
      }

      // Fallback for Android 12 and below.
      final storageStatus = await Permission.storage.request();
      if (storageStatus.isGranted) return LibraryPermissionStatus.granted;
      return storageStatus.isPermanentlyDenied
          ? LibraryPermissionStatus.permanentlyDenied
          : LibraryPermissionStatus.denied;
    }

    if (Platform.isIOS) {
      // iOS treats the audio (Apple Music / MPMediaLibrary) and video
      // (Photos) libraries as two separate permission grants — request
      // both, and treat it as usable if either succeeds, since
      // `scanAudio`/`scanVideos` already degrade gracefully to an empty
      // list for whichever half wasn't granted.
      final audioStatus = await _audioQuery.permissionsStatus();
      final audioGranted =
          audioStatus ? true : await _audioQuery.permissionsRequest();
      final photoResult = await pm.PhotoManager.requestPermissionExtend();

      if (audioGranted || photoResult.isAuth) {
        return LibraryPermissionStatus.granted;
      }
      return LibraryPermissionStatus.denied;
    }

    return LibraryPermissionStatus.granted;
  }

  Future<List<BmMediaItem>> scanAudio() async {
    final songs = await _audioQuery.querySongs(
      sortType: SongSortType.DATE_ADDED,
      orderType: OrderType.DESC_OR_GREATER,
      uriType: UriType.EXTERNAL,
      ignoreCase: true,
    );

    return songs
        .where((s) => s.isMusic ?? true)
        .map((s) => BmMediaItem(
              id: 'audio_${s.id}',
              title: s.title,
              artist: (s.artist == null || s.artist == '<unknown>')
                  ? 'Unknown artist'
                  : s.artist!,
              album: s.album,
              kind: MediaKind.audio,
              origin: MediaOrigin.local,
              sourceUri: s.uri ?? s.data,
              // on_audio_query exposes artwork via a widget keyed on song id
              // rather than a plain file URI. We encode that id into a
              // pseudo-URI here; MediaArtwork (core/widgets) knows how to
              // resolve the `audioquery://` scheme at render time.
              artworkUri: 'audioquery://${s.id}',
              duration: s.duration != null
                  ? Duration(milliseconds: s.duration!)
                  : null,
              bitrateKbps: null,
              sizeBytes: s.size,
            ))
        .toList();
  }

  /// Videos are read through `photo_manager`'s media store access rather
  /// than on_audio_query (which is audio-only). This picks up anything in
  /// the device's video collection, not just a single app-specific folder.
  Future<List<BmMediaItem>> scanVideos() async {
    final albums = await pm.PhotoManager.getAssetPathList(
      type: pm.RequestType.video,
    );
    if (albums.isEmpty) return [];

    final List<BmMediaItem> items = [];
    for (final album in albums) {
      final count = await album.assetCountAsync;
      final assets = await album.getAssetListRange(start: 0, end: count);
      for (final asset in assets) {
        final file = await asset.file;
        if (file == null) continue;
        items.add(BmMediaItem(
          id: 'video_${asset.id}',
          title: asset.title ?? file.uri.pathSegments.last,
          artist: album.name,
          kind: MediaKind.video,
          origin: MediaOrigin.local,
          sourceUri: file.path,
          // Same pattern as audio artwork: encode the asset id and let
          // MediaArtwork fetch a thumbnail from photo_manager on demand,
          // instead of generating and storing thumbnail files ourselves.
          artworkUri: 'videothumb://${asset.id}',
          duration: Duration(seconds: asset.duration),
          sizeBytes: await file.length(),
        ));
      }
    }
    return items;
  }

  Future<List<BmMediaItem>> scanAll() async {
    // Scan independently and tolerate one half failing (e.g. iOS with only
    // audio or only photo-library access granted) rather than letting one
    // rejected permission wipe out both.
    final results = await Future.wait([
      scanAudio().catchError((_) => <BmMediaItem>[]),
      scanVideos().catchError((_) => <BmMediaItem>[]),
    ]);
    return [...results[0], ...results[1]];
  }
}
