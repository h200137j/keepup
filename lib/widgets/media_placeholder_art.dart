import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import '../models/media_item.dart';

IconData iconForBaseType(MediaBaseType type) {
  switch (type) {
    case MediaBaseType.tv:
      return Icons.live_tv_rounded;
    case MediaBaseType.movie:
      return Icons.movie_rounded;
    case MediaBaseType.anime:
      return Icons.auto_awesome_rounded;
    case MediaBaseType.music:
      return Icons.album_rounded;
  }
}

List<Color> gradientForBaseType(MediaBaseType type) {
  switch (type) {
    case MediaBaseType.tv:
      return const [Color(0xff2b2e6b), Color(0xff141626)];
    case MediaBaseType.movie:
      return const [Color(0xff6b1f3a), Color(0xff1c1020)];
    case MediaBaseType.anime:
      return const [Color(0xff1f6b5f), Color(0xff0f1e1c)];
    case MediaBaseType.music:
      return const [Color(0xff6b4f1f), Color(0xff1e180f)];
  }
}

/// Renders [imagePath] — a local file path or an http(s) URL (e.g. from
/// AniList) — if resolvable, otherwise a themed gradient placeholder keyed
/// off the item's [baseType].
class MediaPlaceholderArt extends StatelessWidget {
  const MediaPlaceholderArt({
    super.key,
    required this.baseType,
    this.imagePath,
    this.borderRadius = BorderRadius.zero,
    this.iconSize = 40,
  });

  final MediaBaseType baseType;
  final String? imagePath;
  final BorderRadius borderRadius;
  final double iconSize;

  Widget _placeholder() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradientForBaseType(baseType),
        ),
      ),
      alignment: Alignment.center,
      child: Icon(
        iconForBaseType(baseType),
        size: iconSize,
        color: Colors.white.withValues(alpha: 0.55),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final path = imagePath;

    Widget child;
    if (path == null || path.isEmpty) {
      child = _placeholder();
    } else if (path.startsWith('http://') || path.startsWith('https://')) {
      child = Image.network(
        path,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _placeholder(),
        loadingBuilder: (context, child, progress) =>
            progress == null ? child : _placeholder(),
      );
    } else if (!kIsWeb && File(path).existsSync()) {
      child = Image.file(File(path), fit: BoxFit.cover);
    } else {
      child = _placeholder();
    }

    return ClipRRect(borderRadius: borderRadius, child: child);
  }
}
