import 'package:flutter/material.dart';

import '../models/media_item.dart';
import '../theme/app_theme.dart';

/// (watched, total) for a TV item when both episode fields are known.
(int, int)? episodeProgress(MediaItem item) {
  final tv = item.baseType == MediaBaseType.tv ? item.tvData : null;
  final next = tv?.nextEpisodeNumber;
  final total = tv?.totalEpisodes;
  if (next == null || total == null || total <= 0) return null;
  return ((next - 1).clamp(0, total), total);
}

/// One tick per episode: aired ones filled, the next one outlined in the
/// accent, the rest faint. Falls back to a continuous bar past ~40 episodes
/// where individual ticks would be too thin to read.
class EpisodeBar extends StatelessWidget {
  const EpisodeBar({super.key, required this.watched, required this.total, required this.accent, this.height = 6});

  final int watched;
  final int total;
  final Color accent;
  final double height;

  @override
  Widget build(BuildContext context) {
    if (total > 40) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(height),
        child: LinearProgressIndicator(
          value: watched / total,
          minHeight: height,
          backgroundColor: KColors.line,
          valueColor: AlwaysStoppedAnimation(accent),
        ),
      );
    }

    return Semantics(
      label: '$watched of $total episodes out',
      excludeSemantics: true,
      child: Row(
        children: [
          for (var i = 0; i < total; i++) ...[
            if (i > 0) SizedBox(width: height * 0.5),
            Expanded(
              child: Container(
                height: height,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(height),
                  color: i < watched ? accent : (i == watched ? Colors.transparent : KColors.line),
                  border: i == watched ? Border.all(color: accent, width: 1.2) : null,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
