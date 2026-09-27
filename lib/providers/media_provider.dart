import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:isar/isar.dart';

import '../data/mock_media.dart';
import '../models/media_item.dart';
import 'countdown_provider.dart';
import 'isar_provider.dart';

/// Flip to true to repopulate an empty DB with demo titles on first launch.
/// Off while testing against a genuinely empty DB.
const _seedMockDataOnEmpty = false;

/// Seeds mock data on first launch (if enabled), then exposes the live
/// collection. Depending on this provider guarantees the DB is ready.
final mediaListProvider = StreamProvider<List<MediaItem>>((ref) async* {
  final isar = await ref.watch(isarProvider.future);

  if (_seedMockDataOnEmpty && await isar.mediaItems.count() == 0) {
    await isar.writeTxn(() => isar.mediaItems.putAll(buildMockMediaItems()));
  }

  yield* isar.mediaItems.where().watch(fireImmediately: true);
});

class MediaWithDate {
  const MediaWithDate(this.item, this.nextDate);

  final MediaItem item;
  final DateTime nextDate;
}

/// Free-text title filter for the dashboard.
final searchQueryProvider = StateProvider<String>((ref) => '');

/// Category filter for the dashboard; null means "all".
final categoryFilterProvider = StateProvider<MediaBaseType?>((ref) => null);

Iterable<MediaItem> _filteredItems(Ref ref) {
  final items = ref.watch(mediaListProvider).value ?? [];
  final query = ref.watch(searchQueryProvider).trim().toLowerCase();
  final category = ref.watch(categoryFilterProvider);

  return items.where((item) {
    if (category != null && item.baseType != category) return false;
    if (query.isNotEmpty && !item.title.toLowerCase().contains(query)) return false;
    return true;
  });
}

List<MediaWithDate> _datedEntries(Ref ref) {
  final dated = <MediaWithDate>[];
  for (final item in _filteredItems(ref)) {
    final next = ref.watch(nextReleaseDateProvider(item));
    if (next != null) dated.add(MediaWithDate(item, next));
  }
  return dated..sort((a, b) => a.nextDate.compareTo(b.nextDate));
}

DateTime _startOfToday() {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
}

/// Everything releasing today or later, soonest first — the time rail.
/// Uses start-of-day rather than "now" so a weekly show whose date is
/// today (stored as midnight) still counts as upcoming tonight.
final timelineProvider = Provider<List<MediaWithDate>>((ref) {
  final today = _startOfToday();
  return _datedEntries(ref).where((m) => !m.nextDate.isBefore(today)).toList();
});

/// The next release that still has time left on the clock — the hero.
final nextUpProvider = Provider<MediaWithDate?>((ref) {
  final now = DateTime.now();
  for (final m in ref.watch(timelineProvider)) {
    if (m.nextDate.isAfter(now)) return m;
  }
  return null;
});

/// Dated before today, most recent first.
final releasedProvider = Provider<List<MediaWithDate>>((ref) {
  final today = _startOfToday();
  return _datedEntries(ref).where((m) => m.nextDate.isBefore(today)).toList().reversed.toList();
});

/// Tracked items with no known next date (ended shows, unannounced dates).
final undatedProvider = Provider<List<MediaItem>>((ref) {
  return _filteredItems(ref).where((item) => ref.watch(nextReleaseDateProvider(item)) == null).toList();
});

/// Item counts per category (ignoring the category filter itself) for the
/// filter bar.
final categoryCountsProvider = Provider<Map<MediaBaseType?, int>>((ref) {
  final items = ref.watch(mediaListProvider).value ?? [];
  final counts = <MediaBaseType?, int>{null: items.length};
  for (final item in items) {
    counts[item.baseType] = (counts[item.baseType] ?? 0) + 1;
  }
  return counts;
});

/// True once the DB has resolved and genuinely has zero items (not just
/// zero items matching the current filter) — drives the "add your first
/// title" empty state instead of the "no results" one.
final hasAnyMediaProvider = Provider<bool>((ref) {
  return (ref.watch(mediaListProvider).value ?? const []).isNotEmpty;
});

Future<void> saveMediaItem(WidgetRef ref, MediaItem item) async {
  final isar = await ref.read(isarProvider.future);
  await isar.writeTxn(() => isar.mediaItems.put(item));
}

Future<void> deleteMediaItem(WidgetRef ref, int id) async {
  final isar = await ref.read(isarProvider.future);
  await isar.writeTxn(() => isar.mediaItems.delete(id));
}
