import '../models/media_item.dart';

/// Seed data: 3 items per category, spread across "dropping soon" (<24h)
/// and further-out release windows so both dashboard sections have content.
List<MediaItem> buildMockMediaItems() {
  final now = DateTime.now();

  return [
    // --- TV -----------------------------------------------------------
    // Airing on its normal weekly slot — no manual override, so the
    // countdown comes straight from releaseDayOfWeek.
    MediaItem()
      ..title = 'Stranger Things'
      ..baseType = MediaBaseType.tv
      ..posterImagePath = 'https://static.tvmaze.com/uploads/images/original_untouched/595/1489169.jpg'
      ..tvData = (TvData()
        ..currentSeason = 5
        ..status = TvStatus.airing
        ..releaseDayOfWeek = now.weekday
        ..nextEpisodeNumber = 3
        ..totalEpisodes = 8),
    // Already-watching example: added partway through, ep 7 of 10.
    MediaItem()
      ..title = 'Severance'
      ..baseType = MediaBaseType.tv
      ..posterImagePath = 'https://static.tvmaze.com/uploads/images/original_untouched/548/1371406.jpg'
      ..tvData = (TvData()
        ..currentSeason = 2
        ..status = TvStatus.airing
        ..releaseDayOfWeek = ((now.weekday + 3 - 1) % 7) + 1
        ..nextEpisodeNumber = 7
        ..totalEpisodes = 10),
    // Manual-delay example: normally Thursdays, but this week's episode
    // got pushed — nextEpisodeDate overrides the weekday countdown until
    // it's cleared.
    MediaItem()
      ..title = 'The Bear'
      ..baseType = MediaBaseType.tv
      ..posterImagePath = 'https://static.tvmaze.com/uploads/images/original_untouched/629/1574642.jpg'
      ..tvData = (TvData()
        ..currentSeason = 4
        ..status = TvStatus.airing
        ..releaseDayOfWeek = ((now.weekday + 6 - 1) % 7) + 1
        ..nextEpisodeNumber = 5
        ..totalEpisodes = 10
        ..nextEpisodeDate = now.add(const Duration(days: 9, hours: 3))),

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
