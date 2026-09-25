import 'package:flutter/material.dart';

import '../providers/media_provider.dart';
import '../screens/detail_screen.dart';
import 'days_remaining_pill.dart';
import 'media_placeholder_art.dart';

class TrackingGridTile extends StatelessWidget {
  const TrackingGridTile({super.key, required this.entry});

  final MediaWithDate entry;

  @override
  Widget build(BuildContext context) {
    final item = entry.item;
    final heroTag = 'poster-${item.id}';

    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => DetailScreen(item: item, heroTag: heroTag)),
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
            Positioned(
              left: 8,
              right: 8,
              bottom: 8,
              child: Row(
                children: [Expanded(child: DaysRemainingPill(target: entry.nextDate))],
              ),
            ),
            Positioned(
              left: 8,
              right: 8,
              top: 8,
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
          ],
        ),
      ),
    );
  }
}
