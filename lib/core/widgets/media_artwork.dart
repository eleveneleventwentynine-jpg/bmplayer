import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:photo_manager/photo_manager.dart' as pm;

import '../../models/media_item.dart';
import '../theme/app_colors.dart';

/// Renders a [BmMediaItem]'s artwork regardless of where it came from.
///
/// [BmMediaItem.artworkUri] carries one of:
///  - `http(s)://...`        network image (streaming sources, demo data)
///  - `audioquery://<id>`    local song artwork, resolved via on_audio_query
///  - `videothumb://<id>`    local video thumbnail, resolved via photo_manager
///  - null                    falls back to a kind-appropriate glyph
///
/// Every screen uses this instead of talking to CachedNetworkImage,
/// QueryArtworkWidget, or photo_manager directly, so adding a new source
/// later only means adding one more case here.
class MediaArtwork extends StatelessWidget {
  const MediaArtwork({
    super.key,
    required this.item,
    this.width,
    this.height,
    this.borderRadius = 0,
    this.fit = BoxFit.cover,
  });

  final BmMediaItem item;
  final double? width;
  final double? height;
  final double borderRadius;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final uri = item.artworkUri;
    final radius = BorderRadius.circular(borderRadius);

    Widget content;
    if (uri == null) {
      content = _fallback();
    } else if (uri.startsWith('http')) {
      content = CachedNetworkImage(
        imageUrl: uri,
        width: width,
        height: height,
        fit: fit,
        placeholder: (_, __) => _fallback(),
        errorWidget: (_, __, ___) => _fallback(),
      );
    } else if (uri.startsWith('audioquery://')) {
      final id = int.tryParse(uri.substring('audioquery://'.length));
      content = id == null
          ? _fallback()
          : QueryArtworkWidget(
              id: id,
              type: ArtworkType.AUDIO,
              artworkWidth: width,
              artworkHeight: height,
              artworkFit: fit,
              artworkBorder: BorderRadius.zero,
              nullArtworkWidget: _fallback(),
              keepOldArtwork: true,
            );
    } else if (uri.startsWith('videothumb://')) {
      final id = uri.substring('videothumb://'.length);
      content = _VideoThumb(assetId: id, width: width, height: height, fit: fit);
    } else {
      content = _fallback();
    }

    return borderRadius > 0
        ? ClipRRect(borderRadius: radius, child: content)
        : content;
  }

  Widget _fallback() {
    return Container(
      width: width,
      height: height,
      color: AppColors.glassFillStrong,
      alignment: Alignment.center,
      child: Icon(
        item.kind == MediaKind.video
            ? Icons.movie_creation_rounded
            : Icons.music_note_rounded,
        color: AppColors.textMuted,
      ),
    );
  }
}

class _VideoThumb extends StatelessWidget {
  const _VideoThumb({
    required this.assetId,
    required this.width,
    required this.height,
    required this.fit,
  });

  final String assetId;
  final double? width;
  final double? height;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<pm.AssetEntity?>(
      future: pm.AssetEntity.fromId(assetId),
      builder: (context, assetSnap) {
        final asset = assetSnap.data;
        if (asset == null) {
          return Container(width: width, height: height, color: AppColors.glassFillStrong);
        }
        return FutureBuilder<Uint8List?>(
          future: asset.thumbnailDataWithSize(
            const pm.ThumbnailSize(400, 400),
          ),
          builder: (context, thumbSnap) {
            final bytes = thumbSnap.data;
            if (bytes == null) {
              return Container(width: width, height: height, color: AppColors.glassFillStrong);
            }
            return Image.memory(bytes, width: width, height: height, fit: fit);
          },
        );
      },
    );
  }
}
