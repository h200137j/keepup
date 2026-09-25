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

  /// 1 = Monday .. 7 = Sunday, matches [DateTime.weekday].
  int? releaseDayOfWeek;
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
