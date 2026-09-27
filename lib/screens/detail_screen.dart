import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:slide_countdown/slide_countdown.dart';

import '../models/media_item.dart';
import '../providers/countdown_provider.dart';
import '../providers/media_provider.dart';
import '../widgets/fade_slide_in.dart';
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
    final accent = accentColorForBaseType(item.baseType);
    final tv = item.baseType == MediaBaseType.tv ? item.tvData : null;
    final progress = (tv?.nextEpisodeNumber != null && tv?.totalEpisodes != null && tv!.totalEpisodes! > 0)
        ? (tv.nextEpisodeNumber! - 1).clamp(0, tv.totalEpisodes!) / tv.totalEpisodes!
        : null;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            stretch: true,
            expandedHeight: 360,
            backgroundColor: const Color(0xff0f0f13),
            leading: _BlurIconButton(icon: Icons.arrow_back_rounded, onPressed: () => Navigator.of(context).pop()),
            actions: [
              _BlurIconButton(icon: Icons.edit_outlined, onPressed: () => _edit(context)),
              const SizedBox(width: 8),
              _BlurIconButton(icon: Icons.delete_outline, onPressed: () => _delete(context, ref)),
              const SizedBox(width: 8),
            ],
            flexibleSpace: FlexibleSpaceBar(
              stretchModes: const [StretchMode.zoomBackground],
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Hero(
                    tag: heroTag,
                    child: MediaPlaceholderArt(
                      baseType: item.baseType,
                      imagePath: item.coverImagePath ?? item.posterImagePath,
                      iconSize: 72,
                    ),
                  ),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.45),
                          Colors.transparent,
                          const Color(0xff0f0f13),
                        ],
                        stops: const [0, 0.5, 1],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                FadeSlideIn(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: -0.3),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _badges(item, accent),
                      ),
                      if (progress != null) ...[
                        const SizedBox(height: 18),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(999),
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 6,
                            backgroundColor: Colors.white.withValues(alpha: 0.1),
                            valueColor: AlwaysStoppedAnimation(accent),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Episode ${tv!.nextEpisodeNumber} of ${tv.totalEpisodes}',
                          style: const TextStyle(color: Colors.white38, fontSize: 12),
                        ),
                      ],
                      const SizedBox(height: 28),
                      if (nextDate != null) ...[
                        Text(
                          nextDate.isBefore(DateTime.now()) ? 'Released' : 'Releasing in',
                          style: const TextStyle(color: Colors.white54, fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 10),
                        if (nextDate.isAfter(DateTime.now()))
                          SlideCountdown(
                            duration: nextDate.difference(DateTime.now()),
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                            decoration: BoxDecoration(
                              color: accent.withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: accent.withValues(alpha: 0.3)),
                            ),
                          )
                        else
                          Text(DateFormat.yMMMMd().format(nextDate), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 8),
                        Text(
                          DateFormat.yMMMMd().add_jm().format(nextDate),
                          style: const TextStyle(color: Colors.white38, fontSize: 12),
                        ),
                        if (tv?.nextEpisodeDate != null) ...[
                          const SizedBox(height: 10),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.event_repeat_rounded, size: 14, color: accent.withValues(alpha: 0.8)),
                              const SizedBox(width: 6),
                              Text(
                                'Manually rescheduled',
                                style: TextStyle(color: accent.withValues(alpha: 0.85), fontSize: 12, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ],
                      ] else
                        const Text('No upcoming release date', style: TextStyle(color: Colors.white54)),
                    ],
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _badges(MediaItem item, Color accent) {
    Widget pill(String label) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: accent.withValues(alpha: 0.3)),
          ),
          child: Text(label, style: TextStyle(color: accent, fontSize: 12, fontWeight: FontWeight.w700)),
        );

    switch (item.baseType) {
      case MediaBaseType.tv:
        final d = item.tvData;
        return [
          pill('TV'),
          if (d?.currentSeason != null) pill('Season ${d!.currentSeason}'),
          if (d?.nextEpisodeNumber != null) pill('Ep ${d!.nextEpisodeNumber}${d.totalEpisodes != null ? '/${d.totalEpisodes}' : ''}'),
          if (d != null) pill(d.status.name),
        ];
      case MediaBaseType.movie:
        final d = item.movieData;
        return [
          pill('Movie'),
          if (d?.runtimeMinutes != null) pill('${d!.runtimeMinutes} min'),
        ];
      case MediaBaseType.anime:
        final d = item.animeData;
        return [
          pill('Anime'),
          if (d != null) pill(d.format.name.toUpperCase()),
          if (d?.cour != null) pill('Cour ${d!.cour}'),
        ];
      case MediaBaseType.music:
        final d = item.musicData;
        return [
          pill('Music'),
          if (d?.trackCount != null) pill('${d!.trackCount} tracks'),
        ];
    }
  }
}

class _BlurIconButton extends StatelessWidget {
  const _BlurIconButton({required this.icon, required this.onPressed});

  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(999),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.32),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
            ),
            child: IconButton(icon: Icon(icon, size: 20), color: Colors.white, onPressed: onPressed),
          ),
        ),
      ),
    );
  }
}
