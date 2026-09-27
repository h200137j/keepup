import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/media_item.dart';
import '../providers/countdown_provider.dart';
import '../providers/media_provider.dart';
import '../theme/app_theme.dart';
import '../utils/media_text.dart';
import '../utils/time_format.dart';
import '../widgets/countdown.dart';
import '../widgets/episode_bar.dart';
import '../widgets/media_placeholder_art.dart';
import 'add_edit_screen.dart';

class DetailScreen extends ConsumerWidget {
  const DetailScreen({super.key, required this.item, required this.heroTag});

  final MediaItem item;
  final String heroTag;

  static void open(BuildContext context, MediaItem item, String heroTag) {
    Navigator.of(context).push(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 360),
        reverseTransitionDuration: const Duration(milliseconds: 280),
        pageBuilder: (_, animation, _) => FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
          child: DetailScreen(item: item, heroTag: heroTag),
        ),
      ),
    );
  }

  Future<void> _edit(BuildContext context) async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => AddEditScreen(item: item)));
    if (context.mounted) Navigator.of(context).pop();
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove this title?'),
        content: Text('“${item.title}” and its countdown will be removed from Keep Up. This can\'t be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Keep it')),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: KColors.danger,
              foregroundColor: KColors.inkDeep,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Remove'),
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
    final progress = episodeProgress(item);
    final facts = factsFor(item);
    final rescheduled = item.baseType == MediaBaseType.tv && item.tvData?.nextEpisodeDate != null;
    final backdrop = item.coverImagePath ?? item.posterImagePath;
    final topInset = MediaQuery.paddingOf(context).top;

    return Scaffold(
      body: Stack(
        children: [
          // Ambient backdrop: the art, blurred into a wash of colour that
          // fades into the page.
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            height: 420 + topInset,
            child: ShaderMask(
              shaderCallback: (r) => const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.white, Colors.transparent],
                stops: [0.3, 1],
              ).createShader(r),
              blendMode: BlendMode.dstIn,
              child: Opacity(
                opacity: 0.55,
                child: ImageFiltered(
                  imageFilter: ImageFilter.blur(sigmaX: 30, sigmaY: 30, tileMode: TileMode.decal),
                  child: MediaPlaceholderArt(baseType: item.baseType, imagePath: backdrop),
                ),
              ),
            ),
          ),
          CustomScrollView(
            slivers: [
              SliverAppBar(
                pinned: true,
                backgroundColor: Colors.transparent,
                leading: _RoundButton(
                  icon: Icons.arrow_back_rounded,
                  tooltip: 'Back',
                  onPressed: () => Navigator.of(context).pop(),
                ),
                actions: [
                  _RoundButton(
                    icon: Icons.delete_outline_rounded,
                    tooltip: 'Remove',
                    onPressed: () => _delete(context, ref),
                  ),
                  const SizedBox(width: 12),
                ],
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 40),
                sliver: SliverList.list(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        SizedBox(
                          width: 128,
                          child: AspectRatio(
                            aspectRatio: 2 / 3,
                            child: Hero(
                              tag: heroTag,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.5),
                                      blurRadius: 30,
                                      offset: const Offset(0, 14),
                                    ),
                                  ],
                                ),
                                child: MediaPlaceholderArt(
                                  baseType: item.baseType,
                                  imagePath: item.posterImagePath ?? item.coverImagePath,
                                  title: item.title,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 18),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(iconForBaseType(item.baseType), size: 16, color: accent),
                                  const SizedBox(width: 6),
                                  Text(
                                    labelForBaseType(item.baseType),
                                    style: KType.small.copyWith(color: accent, fontWeight: FontWeight.w700),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                metaLine(item),
                                style: KType.meta.copyWith(color: KColors.text.withValues(alpha: 0.8)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),
                    Text(item.title, style: KType.headline(46).copyWith(fontWeight: FontWeight.w800, height: 0.95)),
                    const SizedBox(height: 30),
                    if (nextDate != null) ...[
                      Text(
                        nextDate.isAfter(DateTime.now()) ? 'Out in' : 'Released',
                        style: KType.meta.copyWith(color: KColors.sodium, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 12),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: MarqueeCountdown(
                          target: nextDate,
                          size: 104,
                          arrivedLabel: dateOnly(nextDate) == dateOnly(DateTime.now()) ? 'Out today' : 'Out now',
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(whenLabel(nextDate), style: KType.bodyText),
                      if (rescheduled) ...[
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(Icons.event_repeat_rounded, size: 15, color: accent),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'Moved from the usual weekly slot',
                                style: KType.small.copyWith(color: accent),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ] else
                      Text('No release date yet', style: KType.headline(32).copyWith(color: KColors.muted)),
                    if (progress != null) ...[
                      const SizedBox(height: 32),
                      Row(
                        children: [
                          Expanded(child: Text('Episodes out', style: KType.meta)),
                          Text('${progress.$1} of ${progress.$2}', style: KType.meta.copyWith(color: KColors.text)),
                        ],
                      ),
                      const SizedBox(height: 10),
                      EpisodeBar(watched: progress.$1, total: progress.$2, accent: accent, height: 8),
                    ],
                    if (facts.isNotEmpty) ...[
                      const SizedBox(height: 32),
                      for (final (label, value) in facts) _FactRow(label: label, value: value),
                    ],
                    const SizedBox(height: 36),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () => _edit(context),
                        icon: const Icon(Icons.edit_rounded, size: 20),
                        label: const Text('Edit details'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FactRow extends StatelessWidget {
  const _FactRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: KColors.line)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            Expanded(child: Text(label, style: KType.meta)),
            Text(value, style: KType.title.copyWith(fontSize: 15)),
          ],
        ),
      ),
    );
  }
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({required this.icon, required this.onPressed, required this.tooltip});

  final IconData icon;
  final VoidCallback onPressed;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: IconButton(
        tooltip: tooltip,
        onPressed: onPressed,
        style: IconButton.styleFrom(
          backgroundColor: KColors.inkDeep.withValues(alpha: 0.45),
          fixedSize: const Size(44, 44),
        ),
        icon: Icon(icon, size: 22, color: KColors.text),
      ),
    );
  }
}
