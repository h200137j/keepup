import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:isar/isar.dart';

import '../data/mock_media.dart';
import '../models/media_item.dart';
import 'countdown_provider.dart';
import 'isar_provider.dart';

/// Seeds mock data on first launch, then exposes the live collection.
/// Depending on this provider guarantees the DB is ready and non-empty.
final mediaListProvider = StreamProvider<List<MediaItem>>((ref) async* {
  final isar = await ref.watch(isarProvider.future);

  if (await isar.mediaItems.count() == 0) {
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

List<MediaWithDate> _datedEntries(Ref ref) {
  final items = ref.watch(mediaListProvider).value ?? [];
  final query = ref.watch(searchQueryProvider).trim().toLowerCase();
  final category = ref.watch(categoryFilterProvider);

  final filtered = items.where((item) {
    if (category != null && item.baseType != category) return false;
    if (query.isNotEmpty && !item.title.toLowerCase().contains(query)) return false;
    return true;
  });

  final dated = <MediaWithDate>[];
  for (final item in filtered) {
    final next = ref.watch(nextReleaseDateProvider(item));
    if (next != null) dated.add(MediaWithDate(item, next));
  }
  return dated..sort((a, b) => a.nextDate.compareTo(b.nextDate));
}

/// Items releasing inside the next 24h, soonest first — hero carousel feed.
final droppingSoonProvider = Provider<List<MediaWithDate>>((ref) {
  final now = DateTime.now();
  return _datedEntries(ref)
      .where((m) => !m.nextDate.isBefore(now) && m.nextDate.difference(now) < const Duration(hours: 24))
      .toList();
});

/// Everything releasing 24h+ out, soonest first — tracking grid feed.
final trackingGridProvider = Provider<List<MediaWithDate>>((ref) {
  final now = DateTime.now();
  return _datedEntries(ref).where((m) => m.nextDate.difference(now) >= const Duration(hours: 24)).toList();
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
