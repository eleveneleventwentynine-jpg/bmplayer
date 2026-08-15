import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/media_item.dart';
import '../services/demo_data.dart';
import '../services/library_service.dart';

enum LibraryLoadStatus { initial, loading, ready, permissionDenied, error }

class LibraryState {
  const LibraryState({
    this.status = LibraryLoadStatus.initial,
    this.items = const [],
    this.recentlyPlayedIds = const [],
  });

  final LibraryLoadStatus status;
  final List<BmMediaItem> items;

  /// Most-recently-played ids, newest first — drives the home screen's
  /// "Continue listening" row.
  final List<String> recentlyPlayedIds;

  List<BmMediaItem> get audio =>
      items.where((e) => e.kind == MediaKind.audio).toList();
  List<BmMediaItem> get video =>
      items.where((e) => e.kind == MediaKind.video).toList();

  List<BmMediaItem> get continueListening {
    final byId = {for (final i in items) i.id: i};
    final recent = recentlyPlayedIds
        .map((id) => byId[id])
        .whereType<BmMediaItem>()
        .toList();
    if (recent.isNotEmpty) return recent.take(8).toList();
    // Nothing played yet this session — surface the most recently added
    // items instead of an empty row.
    return items.take(8).toList();
  }

  LibraryState copyWith({
    LibraryLoadStatus? status,
    List<BmMediaItem>? items,
    List<String>? recentlyPlayedIds,
  }) {
    return LibraryState(
      status: status ?? this.status,
      items: items ?? this.items,
      recentlyPlayedIds: recentlyPlayedIds ?? this.recentlyPlayedIds,
    );
  }
}

/// Owns the local-library lifecycle: request permission, scan, hold
/// results, and track play history for "Continue listening". Starts on
/// [LibraryLoadStatus.initial] with demo items visible so the UI never
/// renders empty while the first scan runs.
class LibraryController extends StateNotifier<LibraryState> {
  LibraryController(this._service) : super(LibraryState(items: demoLibrary));

  final LibraryService _service;

  Future<void> load() async {
    state = state.copyWith(status: LibraryLoadStatus.loading);
    try {
      final permission = await _service.requestPermissions();
      if (permission == LibraryPermissionStatus.denied ||
          permission == LibraryPermissionStatus.permanentlyDenied) {
        state = state.copyWith(status: LibraryLoadStatus.permissionDenied);
        return;
      }
      final items = await _service.scanAll();
      state = state.copyWith(
        status: LibraryLoadStatus.ready,
        // Fall back to demo data only if the device genuinely has nothing,
        // so a fresh install still looks intentional.
        items: items.isEmpty ? demoLibrary : items,
      );
    } catch (_) {
      state = state.copyWith(status: LibraryLoadStatus.error);
    }
  }

  void recordPlayed(String mediaId) {
    final updated = [
      mediaId,
      ...state.recentlyPlayedIds.where((id) => id != mediaId),
    ].take(20).toList();
    state = state.copyWith(recentlyPlayedIds: updated);
  }
}
