import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keep_up/models/media_item.dart';
import 'package:keep_up/providers/countdown_provider.dart';

void main() {
  group('nextWeekdayOccurrence', () {
    test('returns today when weekday matches', () {
      final monday = DateTime(2026, 9, 21); // a Monday
      expect(nextWeekdayOccurrence(monday, DateTime.monday), monday);
    });

    test('returns the upcoming date within the week', () {
      final monday = DateTime(2026, 9, 21);
      final result = nextWeekdayOccurrence(monday, DateTime.thursday);
      expect(result, DateTime(2026, 9, 24));
    });

    test('wraps to next week when the target day already passed', () {
      final friday = DateTime(2026, 9, 25);
      final result = nextWeekdayOccurrence(friday, DateTime.monday);
      expect(result, DateTime(2026, 9, 28));
    });

    test('strips time-of-day from the input', () {
      final withTime = DateTime(2026, 9, 21, 14, 30);
      expect(nextWeekdayOccurrence(withTime, DateTime.monday), DateTime(2026, 9, 21));
    });
  });

  group('nextReleaseDateProvider', () {
    test('TV: resolves next air date from releaseDayOfWeek', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final item = MediaItem()
        ..title = 'Test Show'
        ..baseType = MediaBaseType.tv
        ..tvData = (TvData()
          ..status = TvStatus.airing
          ..releaseDayOfWeek = DateTime.now().weekday);

      final result = container.read(nextReleaseDateProvider(item));
      expect(result, isNotNull);
      expect(result!.weekday, DateTime.now().weekday);
    });

    test('TV: ended shows have no next date even with a release day set', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final item = MediaItem()
        ..title = 'Cancelled Show'
        ..baseType = MediaBaseType.tv
        ..tvData = (TvData()
          ..status = TvStatus.ended
          ..releaseDayOfWeek = DateTime.now().weekday);

      expect(container.read(nextReleaseDateProvider(item)), isNull);
    });

    test('TV: nextEpisodeDate overrides the weekday-based countdown', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final delayed = DateTime.now().add(const Duration(days: 9));
      final item = MediaItem()
        ..title = 'Delayed Show'
        ..baseType = MediaBaseType.tv
        ..tvData = (TvData()
          ..status = TvStatus.airing
          ..releaseDayOfWeek = DateTime.now().weekday
          ..nextEpisodeDate = delayed);

      expect(container.read(nextReleaseDateProvider(item)), delayed);
    });

    test('Movie: resolves the configured releaseDate', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final date = DateTime(2030, 1, 1);
      final item = MediaItem()
        ..title = 'Future Film'
        ..baseType = MediaBaseType.movie
        ..movieData = (MovieData()..releaseDate = date);

      expect(container.read(nextReleaseDateProvider(item)), date);
    });

    test('Anime: resolves nextAiringEpisodeTimestamp', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final airing = DateTime(2030, 1, 1, 12);
      final item = MediaItem()
        ..title = 'Test Anime'
        ..baseType = MediaBaseType.anime
        ..animeData = (AnimeData()..nextAiringEpisodeTimestamp = airing);

      expect(container.read(nextReleaseDateProvider(item)), airing);
    });

    test('Music: resolves the configured releaseDate', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final date = DateTime(2030, 6, 1);
      final item = MediaItem()
        ..title = 'Test Album'
        ..baseType = MediaBaseType.music
        ..musicData = (MusicData()..releaseDate = date);

      expect(container.read(nextReleaseDateProvider(item)), date);
    });

    test('missing embedded data resolves to null instead of throwing', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final item = MediaItem()
        ..title = 'No data'
        ..baseType = MediaBaseType.movie;

      expect(container.read(nextReleaseDateProvider(item)), isNull);
    });
  });
}
