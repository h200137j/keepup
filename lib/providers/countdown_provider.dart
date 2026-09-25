import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/media_item.dart';

/// Resolves the next release [DateTime] for any [MediaItem], regardless of
/// its [MediaBaseType]. Returns null when the item has no known upcoming date.
final nextReleaseDateProvider = Provider.family<DateTime?, MediaItem>((ref, item) {
  switch (item.baseType) {
    case MediaBaseType.tv:
      final day = item.tvData?.releaseDayOfWeek;
      if (item.tvData?.status == TvStatus.ended || day == null) return null;
      return nextWeekdayOccurrence(DateTime.now(), day);
    case MediaBaseType.anime:
      return item.animeData?.nextAiringEpisodeTimestamp;
    case MediaBaseType.movie:
      return item.movieData?.releaseDate;
    case MediaBaseType.music:
      return item.musicData?.releaseDate;
  }
});

/// Next calendar date (time-of-day stripped) matching [targetWeekday]
/// (1 = Monday .. 7 = Sunday, per [DateTime.weekday]), counting today as a match.
DateTime nextWeekdayOccurrence(DateTime from, int targetWeekday) {
  final today = DateTime(from.year, from.month, from.day);
  final diff = (targetWeekday - today.weekday + 7) % 7;
  return today.add(Duration(days: diff));
}
