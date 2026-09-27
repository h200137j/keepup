import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:slide_countdown/slide_countdown.dart';

import '../models/media_item.dart';
import '../providers/media_provider.dart';
import '../screens/detail_screen.dart';
import 'fade_slide_in.dart';
import 'media_placeholder_art.dart';

class DroppingSoonCard extends StatelessWidget {
  const DroppingSoonCard({super.key, required this.entry});

  final MediaWithDate entry;

  @override
  Widget build(BuildContext context) {
    final item = entry.item;
    final heroTag = 'cover-${item.id}';
    final accent = accentColorForBaseType(item.baseType);

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
        width: 280,
        margin: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: accent.withValues(alpha: 0.28),
              blurRadius: 28,
              spreadRadius: -6,
              offset: const Offset(0, 14),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.45),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Hero(
              tag: heroTag,
              child: MediaPlaceholderArt(
                baseType: item.baseType,
                imagePath: item.coverImagePath,
                borderRadius: BorderRadius.circular(20),
                iconSize: 56,
              ),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.88),
                  ],
                  stops: const [0.35, 1],
                ),
              ),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
            ),
            Positioned(
              left: 14,
              top: 14,
              child: _CategoryBadge(baseType: item.baseType, accent: accent),
            ),
            Positioned(
              left: 16,
              right: 16,
              bottom: 14,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SlideCountdown(
                    duration: entry.nextDate.difference(DateTime.now()),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                    separatorStyle: const TextStyle(color: Colors.white70, fontSize: 15),
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.28),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: accent.withValues(alpha: 0.4)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryBadge extends StatelessWidget {
  const _CategoryBadge({required this.baseType, required this.accent});

  final MediaBaseType baseType;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.3),
            shape: BoxShape.circle,
            border: Border.all(color: accent.withValues(alpha: 0.55)),
          ),
          child: Icon(iconForBaseType(baseType), size: 14, color: Colors.white),
        ),
      ),
    );
  }
}
