import '../models/media_item.dart';

/// Seed data: 3 items per category, spread across "dropping soon" (<24h)
/// and further-out release windows so both dashboard sections have content.
List<MediaItem> buildMockMediaItems() {
  final now = DateTime.now();

  return [
    // --- TV -----------------------------------------------------------
    MediaItem()
      ..title = 'Nocturne City'
      ..baseType = MediaBaseType.tv
      ..tvData = (TvData()
        ..currentSeason = 3
        ..status = TvStatus.airing
        ..releaseDayOfWeek = now.weekday),
    MediaItem()
      ..title = 'The Long Signal'
      ..baseType = MediaBaseType.tv
      ..tvData = (TvData()
        ..currentSeason = 1
        ..status = TvStatus.airing
        ..releaseDayOfWeek = ((now.weekday + 3 - 1) % 7) + 1),
    MediaItem()
      ..title = 'Harbor Lights'
      ..baseType = MediaBaseType.tv
      ..tvData = (TvData()
        ..currentSeason = 5
        ..status = TvStatus.hiatus
        ..releaseDayOfWeek = ((now.weekday + 6 - 1) % 7) + 1),

    // --- Movie ----------------------------------------------------------
    MediaItem()
      ..title = 'Glass Horizon'
      ..baseType = MediaBaseType.movie
      ..movieData = (MovieData()
        ..releaseDate = now.add(const Duration(hours: 6))
        ..runtimeMinutes = 128),
    MediaItem()
      ..title = 'Six Rivers'
      ..baseType = MediaBaseType.movie
      ..movieData = (MovieData()
        ..releaseDate = now.add(const Duration(days: 12))
        ..runtimeMinutes = 104),
    MediaItem()
      ..title = 'The Last Cartographer'
      ..baseType = MediaBaseType.movie
      ..movieData = (MovieData()
        ..releaseDate = now.add(const Duration(days: 45))
        ..runtimeMinutes = 137),

    // --- Anime ------------------------------------------------------------
    MediaItem()
      ..title = 'Starforge Academy'
      ..baseType = MediaBaseType.anime
      ..animeData = (AnimeData()
        ..format = AnimeFormat.tv
        ..cour = 2
        ..nextAiringEpisodeTimestamp = now.add(const Duration(hours: 18))
        ..aniListId = '100001'),
    MediaItem()
      ..title = 'Wandering Blade: Requiem'
      ..baseType = MediaBaseType.anime
      ..animeData = (AnimeData()
        ..format = AnimeFormat.tv
        ..cour = 1
        ..nextAiringEpisodeTimestamp = now.add(const Duration(days: 4))
        ..aniListId = '100002'),
    MediaItem()
      ..title = 'Paper Moon OVA'
      ..baseType = MediaBaseType.anime
      ..animeData = (AnimeData()
        ..format = AnimeFormat.ova
        ..nextAiringEpisodeTimestamp = now.add(const Duration(days: 21))
        ..aniListId = '100003'),

    // --- Music --------------------------------------------------------
    MediaItem()
      ..title = 'Afterglow (Deluxe)'
      ..baseType = MediaBaseType.music
      ..musicData = (MusicData()
        ..releaseDate = now.add(const Duration(hours: 2))
        ..trackCount = 14),
    MediaItem()
      ..title = 'Static & Salt'
      ..baseType = MediaBaseType.music
      ..musicData = (MusicData()
        ..releaseDate = now.add(const Duration(days: 8))
        ..trackCount = 10),
    MediaItem()
      ..title = 'Low Orbit'
      ..baseType = MediaBaseType.music
      ..musicData = (MusicData()
        ..releaseDate = now.add(const Duration(days: 60))
        ..trackCount = 8),
  ];
}
