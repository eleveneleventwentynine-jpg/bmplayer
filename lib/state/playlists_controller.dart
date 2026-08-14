import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/media_item.dart';
import '../models/playlist.dart';
import '../services/database_service.dart';

class PlaylistsController extends StateNotifier<List<BmPlaylist>> {
  PlaylistsController(this._db) : super(const []) {
    load();
  }

  final DatabaseService _db;

  Future<void> load() async {
    state = await _db.getAllPlaylists();
  }

  Future<void> create(String name) async {
    if (name.trim().isEmpty) return;
    await _db.createPlaylist(name.trim());
    await load();
  }

  Future<void> delete(String playlistId) async {
    await _db.deletePlaylist(playlistId);
    await load();
  }

  Future<void> rename(String playlistId, String newName) async {
    if (newName.trim().isEmpty) return;
    await _db.renamePlaylist(playlistId, newName.trim());
    await load();
  }

  Future<void> addTrack(String playlistId, BmMediaItem item) async {
    await _db.addTrackToPlaylist(playlistId, item);
    await load();
  }

  Future<void> removeTrack(String playlistId, String mediaId) async {
    await _db.removeTrackFromPlaylist(playlistId, mediaId);
    await load();
  }

  Future<void> reorderTracks(
      String playlistId, List<BmMediaItem> newOrder) async {
    // Optimistic local update so the drag feels instant, then persist.
    state = [
      for (final pl in state)
        if (pl.id == playlistId)
          BmPlaylist(
              id: pl.id, name: pl.name, items: newOrder, coverUri: pl.coverUri)
        else
          pl,
    ];
    await _db.reorderPlaylistTracks(playlistId, newOrder);
  }
}
