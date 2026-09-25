import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:slide_countdown/slide_countdown.dart';

import '../models/media_item.dart';
import '../providers/countdown_provider.dart';
import '../providers/media_provider.dart';
import '../widgets/media_placeholder_art.dart';
import 'add_edit_screen.dart';

class DetailScreen extends ConsumerWidget {
  const DetailScreen({super.key, required this.item, required this.heroTag});

  final MediaItem item;
  final String heroTag;

  Future<void> _edit(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => AddEditScreen(item: item)),
    );
    if (context.mounted) Navigator.of(context).pop();
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete title?'),
        content: Text('"${item.title}" will be removed and can\'t be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await deleteMediaItem(ref, item.id);
    if (context.mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nextDate = ref.watch(nextReleaseDateProvider(item));

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 340,
            backgroundColor: const Color(0xff0f0f13),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                onPressed: () => _edit(context),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () => _delete(context, ref),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Hero(
                tag: heroTag,
                child: MediaPlaceholderArt(
                  baseType: item.baseType,
                  imagePath: item.coverImagePath ?? item.posterImagePath,
                  iconSize: 72,
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                Text(
                  item.title,
                  style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 6),
                Text(
                  _subtitle(item),
                  style: const TextStyle(color: Colors.white60, fontSize: 14),
                ),
                const SizedBox(height: 28),
                if (nextDate != null) ...[
                  Text(
                    nextDate.isBefore(DateTime.now()) ? 'Released' : 'Releasing in',
                    style: const TextStyle(color: Colors.white54, fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  if (nextDate.isAfter(DateTime.now()))
                    SlideCountdown(
                      duration: nextDate.difference(DateTime.now()),
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    )
                  else
                    Text(DateFormat.yMMMMd().format(nextDate)),
                  const SizedBox(height: 6),
                  Text(
                    DateFormat.yMMMMd().add_jm().format(nextDate),
                    style: const TextStyle(color: Colors.white38, fontSize: 12),
                  ),
                ] else
                  const Text('No upcoming release date', style: TextStyle(color: Colors.white54)),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  String _subtitle(MediaItem item) {
    switch (item.baseType) {
      case MediaBaseType.tv:
        final d = item.tvData;
        return 'TV · Season ${d?.currentSeason ?? '?'} · ${d?.status.name ?? ''}';
      case MediaBaseType.movie:
        final d = item.movieData;
        return 'Movie${d?.runtimeMinutes != null ? ' · ${d!.runtimeMinutes} min' : ''}';
      case MediaBaseType.anime:
        final d = item.animeData;
        return 'Anime · ${d?.format.name ?? ''}${d?.cour != null ? ' · Cour ${d!.cour}' : ''}';
      case MediaBaseType.music:
        final d = item.musicData;
        return 'Music${d?.trackCount != null ? ' · ${d!.trackCount} tracks' : ''}';
    }
  }
}
