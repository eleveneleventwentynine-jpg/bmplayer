import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/media_item.dart';
import '../models/playlist.dart';

enum DiscoverStatus { idle, searching, ready, error }

class DiscoverState {
  const DiscoverState({
    this.status = DiscoverStatus.idle,
    this.results = const [],
    this.resolvingItemId,
  });

  final DiscoverStatus status;
  final List<BmMediaItem> results;

  /// Id of the item currently being resolved to a playable URL, if any —
  /// lets a single row show a spinner while the rest of the list stays
  /// interactive.
  final String? resolvingItemId;

  DiscoverState copyWith({
    DiscoverStatus? status,
    List<BmMediaItem>? results,
    String? resolvingItemId,
    bool clearResolving = false,
  }) {
    return DiscoverState(
      status: status ?? this.status,
      results: results ?? this.results,
      resolvingItemId:
          clearResolving ? null : (resolvingItemId ?? this.resolvingItemId),
    );
  }
}

class DiscoverController extends StateNotifier<DiscoverState> {
  DiscoverController(this._source) : super(const DiscoverState());

  final StreamingSource _source;

  Future<void> search(String query) async {
    if (query.trim().isEmpty) {
      state = state.copyWith(status: DiscoverStatus.idle, results: []);
      return;
    }
    state = state.copyWith(status: DiscoverStatus.searching);
    try {
      final results = await _source.search(query);
      state = state.copyWith(status: DiscoverStatus.ready, results: results);
    } catch (_) {
      state = state.copyWith(status: DiscoverStatus.error, results: []);
    }
  }

  /// Resolves the item's real playable URL and returns an updated copy
  /// with [BmMediaItem.sourceUri] swapped in. Callers pass this resolved
  /// item straight to the player.
  Future<BmMediaItem> resolveForPlayback(BmMediaItem item) async {
    state = state.copyWith(resolvingItemId: item.id);
    try {
      final playableUri = await _source.resolvePlaybackUri(item);
      return BmMediaItem(
        id: item.id,
        title: item.title,
        artist: item.artist,
        album: item.album,
        kind: item.kind,
        origin: item.origin,
        sourceUri: playableUri,
        artworkUri: item.artworkUri,
        duration: item.duration,
        bitrateKbps: item.bitrateKbps,
        sizeBytes: item.sizeBytes,
        sourceLabel: item.sourceLabel,
      );
    } finally {
      state = state.copyWith(clearResolving: true);
    }
  }
}
