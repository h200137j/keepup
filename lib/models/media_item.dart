import 'package:isar/isar.dart';

part 'media_item.g.dart';

enum MediaBaseType { tv, movie, anime, music }

enum TvStatus { airing, hiatus, ended }

enum AnimeFormat { tv, movie, ova }

@collection
class MediaItem {
  Id id = Isar.autoIncrement;

  @Index()
  late String title;

  @Enumerated(EnumType.name)
  late MediaBaseType baseType;

  String? posterImagePath;
  String? coverImagePath;

  DateTime createdAt = DateTime.now();

  TvData? tvData;
  AnimeData? animeData;
  MovieData? movieData;
  MusicData? musicData;
}

@embedded
class TvData {
  int? currentSeason;

  @Enumerated(EnumType.name)
  TvStatus status = TvStatus.airing;

  /// 1 = Monday .. 7 = Sunday, matches [DateTime.weekday]. Drives the
  /// recurring weekly countdown when [nextEpisodeDate] isn't set.
  int? releaseDayOfWeek;

  /// Episode number the user is waiting on next — lets a show already in
  /// progress be added partway through instead of always starting at 1.
  int? nextEpisodeNumber;

  /// Total episode count for the season/series, if known.
  int? totalEpisodes;

  /// Manual override for exactly when the next episode airs. Takes
  /// priority over [releaseDayOfWeek] so a one-off delay (a missed week,
  /// a schedule shuffle) can be reflected without losing the recurring
  /// pattern — clear it to fall back to the weekday-based countdown.
  DateTime? nextEpisodeDate;
}

@embedded
class AnimeData {
  @Enumerated(EnumType.name)
  AnimeFormat format = AnimeFormat.tv;

  int? cour;
  DateTime? nextAiringEpisodeTimestamp;
  String? aniListId;
}

@embedded
class MovieData {
  DateTime? releaseDate;
  int? runtimeMinutes;
}

@embedded
class MusicData {
  DateTime? releaseDate;
  int? trackCount;
}
