import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import '../models/media_item.dart';
import '../theme/app_theme.dart';

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

String labelForBaseType(MediaBaseType type) {
  switch (type) {
    case MediaBaseType.tv:
      return 'TV';
    case MediaBaseType.movie:
      return 'Movie';
    case MediaBaseType.anime:
      return 'Anime';
    case MediaBaseType.music:
      return 'Music';
  }
}

/// Deep backdrop pair behind placeholder art, tinted toward the category hue.
List<Color> gradientForBaseType(MediaBaseType type) {
  final accent = accentColorForBaseType(type);
  return [Color.lerp(KColors.raisedHi, accent, 0.35)!, KColors.inkDeep];
}

/// Per-category hue for timeline nodes, tags, and episode bars. Tuned to sit
/// together on the dusk-indigo background without competing with the
/// sodium "now" accent.
Color accentColorForBaseType(MediaBaseType type) {
  switch (type) {
    case MediaBaseType.tv:
      return const Color(0xff8fa8ff);
    case MediaBaseType.movie:
      return const Color(0xffff7a93);
    case MediaBaseType.anime:
      return const Color(0xff5ce6c0);
    case MediaBaseType.music:
      return const Color(0xffe58cff);
  }
}

/// Renders [imagePath] — a local file path or an http(s) URL (e.g. from
/// AniList) — if resolvable. Otherwise draws a typographic poster: the
/// [title] set in condensed display type over a category-tinted backdrop.
class MediaPlaceholderArt extends StatelessWidget {
  const MediaPlaceholderArt({
    super.key,
    required this.baseType,
    this.imagePath,
    this.title,
    this.borderRadius = BorderRadius.zero,
    this.iconSize = 40,
  });

  final MediaBaseType baseType;
  final String? imagePath;
  final String? title;
  final BorderRadius borderRadius;
  final double iconSize;

  /// Shrinks the type until the longest word fits on one line, so titles
  /// never break mid-word. Big Shoulders averages ~0.48em per glyph.
  static double _fitSize(String text, double width, double maxSize) {
    final longest = text.split(RegExp(r'\s+')).fold<int>(0, (m, w) => w.length > m ? w.length : m);
    if (longest == 0) return maxSize;
    return (width / (longest * 0.48)).clamp(6, maxSize);
  }

  Widget _placeholder() {
    final accent = accentColorForBaseType(baseType);
    final t = title?.trim();

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradientForBaseType(baseType),
        ),
      ),
      child: t == null || t.isEmpty
          ? Center(
              child: Icon(iconForBaseType(baseType), size: iconSize, color: accent.withValues(alpha: 0.6)),
            )
          : LayoutBuilder(
              builder: (context, c) => Padding(
                padding: EdgeInsets.all(c.maxWidth * 0.09),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(iconForBaseType(baseType), size: c.maxWidth * 0.14, color: accent),
                    const Spacer(),
                    Text(
                      t,
                      maxLines: 4,
                      overflow: TextOverflow.clip,
                      style: KType.headline(
                        _fitSize(t, c.maxWidth * 0.82, c.maxWidth * 0.2),
                        color: KColors.text.withValues(alpha: 0.92),
                      ).copyWith(fontWeight: FontWeight.w800, height: 0.92),
                    ),
                  ],
                ),
              ),
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
      child = Stack(
        fit: StackFit.expand,
        children: [
          _placeholder(),
          Image.network(
            path,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => const SizedBox.shrink(),
            frameBuilder: (context, img, frame, wasSynchronouslyLoaded) {
              if (wasSynchronouslyLoaded) return img;
              return AnimatedOpacity(
                opacity: frame == null ? 0 : 1,
                duration: const Duration(milliseconds: 350),
                curve: Curves.easeOut,
                child: img,
              );
            },
          ),
        ],
      );
    } else if (!kIsWeb && File(path).existsSync()) {
      child = Image.file(File(path), fit: BoxFit.cover);
    } else {
      child = _placeholder();
    }

    return ClipRRect(borderRadius: borderRadius, child: child);
  }
}
