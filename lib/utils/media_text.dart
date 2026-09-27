import '../models/media_item.dart';

const weekdayNames = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];

String _runtime(int minutes) {
  final h = minutes ~/ 60;
  final m = minutes % 60;
  if (h == 0) return '${m}m';
  return m == 0 ? '${h}h' : '${h}h ${m}m';
}

String tvStatusLabel(TvStatus s) {
  switch (s) {
    case TvStatus.airing:
      return 'Airing';
    case TvStatus.hiatus:
      return 'On hiatus';
    case TvStatus.ended:
      return 'Ended';
  }
}

String animeFormatLabel(AnimeFormat f) {
  switch (f) {
    case AnimeFormat.tv:
      return 'Series';
    case AnimeFormat.movie:
      return 'Film';
    case AnimeFormat.ova:
      return 'OVA';
  }
}

/// One plain-language line describing what's coming, e.g.
/// "Season 5, episode 3" or "Album, 14 tracks".
String metaLine(MediaItem item) {
  switch (item.baseType) {
    case MediaBaseType.tv:
      final d = item.tvData;
      if (d == null) return 'TV';
      if (d.status == TvStatus.ended) return 'Ended';
      final parts = <String>[
        if (d.currentSeason != null) 'Season ${d.currentSeason}',
        if (d.nextEpisodeNumber != null)
          d.currentSeason != null ? 'episode ${d.nextEpisodeNumber}' : 'Episode ${d.nextEpisodeNumber}',
      ];
      if (d.status == TvStatus.hiatus) parts.add(parts.isEmpty ? 'On hiatus' : 'on hiatus');
      return parts.isEmpty ? 'TV series' : parts.join(', ');
    case MediaBaseType.movie:
      final m = item.movieData?.runtimeMinutes;
      return m == null ? 'Film' : 'Film, ${_runtime(m)}';
    case MediaBaseType.anime:
      final d = item.animeData;
      if (d == null) return 'Anime';
      final format = d.format == AnimeFormat.tv ? 'Anime series' : 'Anime ${animeFormatLabel(d.format)}';
      return d.cour == null ? format : '$format, cour ${d.cour}';
    case MediaBaseType.music:
      final t = item.musicData?.trackCount;
      return t == null ? 'Album' : 'Album, $t tracks';
  }
}

/// Label/value pairs for the detail screen's fact list.
List<(String, String)> factsFor(MediaItem item) {
  switch (item.baseType) {
    case MediaBaseType.tv:
      final d = item.tvData;
      if (d == null) return const [];
      return [
        ('Status', tvStatusLabel(d.status)),
        if (d.currentSeason != null) ('Season', '${d.currentSeason}'),
        if (d.nextEpisodeNumber != null)
          (
            'Next episode',
            d.totalEpisodes != null ? '${d.nextEpisodeNumber} of ${d.totalEpisodes}' : '${d.nextEpisodeNumber}',
          ),
        if (d.releaseDayOfWeek != null && d.status != TvStatus.ended)
          ('New episodes', 'Every ${weekdayNames[d.releaseDayOfWeek! - 1]}'),
      ];
    case MediaBaseType.movie:
      final d = item.movieData;
      return [if (d?.runtimeMinutes != null) ('Runtime', _runtime(d!.runtimeMinutes!))];
    case MediaBaseType.anime:
      final d = item.animeData;
      if (d == null) return const [];
      return [
        ('Format', animeFormatLabel(d.format)),
        if (d.cour != null) ('Cour', '${d.cour}'),
        if (d.aniListId != null) ('AniList', '#${d.aniListId}'),
      ];
    case MediaBaseType.music:
      final d = item.musicData;
      return [if (d?.trackCount != null) ('Tracks', '${d!.trackCount}')];
  }
}
