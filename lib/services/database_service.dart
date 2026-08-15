import 'dart:convert';

import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../models/media_item.dart';
import '../models/playlist.dart';

/// Owns all local persistence for playlists and favorites. Tracks are
/// stored as JSON blobs (via [BmMediaItem.toJson]) rather than normalized
/// columns — a media item can come from very different sources (device
/// library, YouTube) with different fields, and a playlist is a small,
/// personal dataset where a flexible schema is worth more than strict
/// normalization here.
class DatabaseService {
  Database? _db;

  Future<Database> get _database async => _db ??= await _open();

  Future<Database> _open() async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, 'bmplayer.db');
    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE playlists (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            cover_uri TEXT,
            created_at INTEGER NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE playlist_tracks (
            playlist_id TEXT NOT NULL,
            position INTEGER NOT NULL,
            item_json TEXT NOT NULL,
            FOREIGN KEY (playlist_id) REFERENCES playlists (id) ON DELETE CASCADE
          )
        ''');
        await db.execute('''
          CREATE TABLE favorites (
            media_id TEXT PRIMARY KEY,
            item_json TEXT NOT NULL,
            added_at INTEGER NOT NULL
          )
        ''');
      },
    );
  }

  // --- Playlists ----------------------------------------------------

  Future<List<BmPlaylist>> getAllPlaylists() async {
    final db = await _database;
    final playlistRows = await db.query('playlists', orderBy: 'created_at ASC');

    final playlists = <BmPlaylist>[];
    for (final row in playlistRows) {
      final id = row['id'] as String;
      final trackRows = await db.query(
        'playlist_tracks',
        where: 'playlist_id = ?',
        whereArgs: [id],
        orderBy: 'position ASC',
      );
      final tracks = trackRows
          .map((t) => BmMediaItem.fromJson(
              jsonDecode(t['item_json'] as String) as Map<String, dynamic>))
          .toList();

      playlists.add(BmPlaylist(
        id: id,
        name: row['name'] as String,
        items: tracks,
        coverUri: row['cover_uri'] as String? ??
            (tracks.isNotEmpty ? tracks.first.artworkUri : null),
      ));
    }
    return playlists;
  }

  Future<void> createPlaylist(String name) async {
    final db = await _database;
    await db.insert('playlists', {
      'id': 'pl_${DateTime.now().microsecondsSinceEpoch}',
      'name': name,
      'cover_uri': null,
      'created_at': DateTime.now().millisecondsSinceEpoch,
    });
  }

  Future<void> deletePlaylist(String playlistId) async {
    final db = await _database;
    await db.delete('playlist_tracks',
        where: 'playlist_id = ?', whereArgs: [playlistId]);
    await db.delete('playlists', where: 'id = ?', whereArgs: [playlistId]);
  }

  Future<void> renamePlaylist(String playlistId, String newName) async {
    final db = await _database;
    await db.update('playlists', {'name': newName},
        where: 'id = ?', whereArgs: [playlistId]);
  }

  Future<void> addTrackToPlaylist(String playlistId, BmMediaItem item) async {
    final db = await _database;
    final countResult = await db.rawQuery(
      'SELECT COUNT(*) as c FROM playlist_tracks WHERE playlist_id = ?',
      [playlistId],
    );
    final nextPosition = Sqflite.firstIntValue(countResult) ?? 0;
    await db.insert('playlist_tracks', {
      'playlist_id': playlistId,
      'position': nextPosition,
      'item_json': jsonEncode(item.toJson()),
    });
  }

  Future<void> removeTrackFromPlaylist(
      String playlistId, String mediaId) async {
    final db = await _database;
    final rows = await db.query(
      'playlist_tracks',
      where: 'playlist_id = ?',
      whereArgs: [playlistId],
      orderBy: 'position ASC',
    );
    await db.delete('playlist_tracks',
        where: 'playlist_id = ?', whereArgs: [playlistId]);

    var position = 0;
    final batch = db.batch();
    for (final row in rows) {
      final item = BmMediaItem.fromJson(
          jsonDecode(row['item_json'] as String) as Map<String, dynamic>);
      if (item.id == mediaId) continue;
      batch.insert('playlist_tracks', {
        'playlist_id': playlistId,
        'position': position++,
        'item_json': row['item_json'],
      });
    }
    await batch.commit(noResult: true);
  }

  Future<void> reorderPlaylistTracks(
    String playlistId,
    List<BmMediaItem> newOrder,
  ) async {
    final db = await _database;
    await db.delete('playlist_tracks',
        where: 'playlist_id = ?', whereArgs: [playlistId]);
    final batch = db.batch();
    for (var i = 0; i < newOrder.length; i++) {
      batch.insert('playlist_tracks', {
        'playlist_id': playlistId,
        'position': i,
        'item_json': jsonEncode(newOrder[i].toJson()),
      });
    }
    await batch.commit(noResult: true);
  }

  // --- Favorites ------------------------------------------------------

  Future<List<BmMediaItem>> getFavorites() async {
    final db = await _database;
    final rows = await db.query('favorites', orderBy: 'added_at DESC');
    return rows
        .map((r) => BmMediaItem.fromJson(
            jsonDecode(r['item_json'] as String) as Map<String, dynamic>))
        .toList();
  }

  Future<bool> isFavorite(String mediaId) async {
    final db = await _database;
    final rows = await db
        .query('favorites', where: 'media_id = ?', whereArgs: [mediaId]);
    return rows.isNotEmpty;
  }

  Future<void> toggleFavorite(BmMediaItem item) async {
    final db = await _database;
    final exists = await isFavorite(item.id);
    if (exists) {
      await db.delete('favorites', where: 'media_id = ?', whereArgs: [item.id]);
    } else {
      await db.insert('favorites', {
        'media_id': item.id,
        'item_json': jsonEncode(item.toJson()),
        'added_at': DateTime.now().millisecondsSinceEpoch,
      });
    }
  }
}
