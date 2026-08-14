import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/media_item.dart';
import '../services/database_service.dart';

class FavoritesController extends StateNotifier<List<BmMediaItem>> {
  FavoritesController(this._db) : super(const []) {
    load();
  }

  final DatabaseService _db;

  bool isFavorite(String mediaId) => state.any((e) => e.id == mediaId);

  Future<void> load() async {
    state = await _db.getFavorites();
  }

  Future<void> toggle(BmMediaItem item) async {
    // Optimistic update — flips instantly in the UI, then persists.
    if (isFavorite(item.id)) {
      state = state.where((e) => e.id != item.id).toList();
    } else {
      state = [item, ...state];
    }
    await _db.toggleFavorite(item);
  }
}
