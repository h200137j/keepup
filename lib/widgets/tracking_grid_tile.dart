import 'dart:ui';

import 'package:flutter/material.dart';

import '../models/media_item.dart';
import '../providers/media_provider.dart';
import '../screens/detail_screen.dart';
import 'days_remaining_pill.dart';
import 'fade_slide_in.dart';
import 'media_placeholder_art.dart';

class TrackingGridTile extends StatelessWidget {
  const TrackingGridTile({super.key, required this.entry});

  final MediaWithDate entry;

  @override
  Widget build(BuildContext context) {
    final item = entry.item;
    final heroTag = 'poster-${item.id}';
    final accent = accentColorForBaseType(item.baseType);
    final tv = item.baseType == MediaBaseType.tv ? item.tvData : null;
    final progress = (tv?.nextEpisodeNumber != null && tv?.totalEpisodes != null && tv!.totalEpisodes! > 0)
        ? (tv.nextEpisodeNumber! - 1).clamp(0, tv.totalEpisodes!) / tv.totalEpisodes!
        : null;

    return PressScale(
      onTap: () => Navigator.of(context).push(
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 320),
          pageBuilder: (_, animation, _) => FadeTransition(
            opacity: animation,
            child: DetailScreen(item: item, heroTag: heroTag),
          ),
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Hero(
                tag: heroTag,
                child: MediaPlaceholderArt(
                  baseType: item.baseType,
                  imagePath: item.posterImagePath,
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.55),
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.75),
                    ],
                    stops: const [0, 0.4, 1],
                  ),
                ),
              ),
              DecoratedBox(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              Positioned(
                left: 8,
                top: 8,
                child: _MiniBadge(baseType: item.baseType, accent: accent),
              ),
              Positioned(
                left: 8,
                right: 8,
                top: 34,
                child: Text(
                  item.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    shadows: [Shadow(blurRadius: 6, color: Colors.black)],
                  ),
                ),
              ),
              Positioned(
                left: 8,
                right: 8,
                bottom: 8,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (progress != null) ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 4,
                          backgroundColor: Colors.white.withValues(alpha: 0.15),
                          valueColor: AlwaysStoppedAnimation(accent),
                        ),
                      ),
                      const SizedBox(height: 6),
                    ],
                    Row(children: [Expanded(child: DaysRemainingPill(target: entry.nextDate))]),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniBadge extends StatelessWidget {
  const _MiniBadge({required this.baseType, required this.accent});

  final MediaBaseType baseType;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.32),
            shape: BoxShape.circle,
            border: Border.all(color: accent.withValues(alpha: 0.55)),
          ),
          child: Icon(iconForBaseType(baseType), size: 11, color: Colors.white),
        ),
      ),
    );
  }
}
