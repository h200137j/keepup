import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../models/media_item.dart';
import '../providers/media_provider.dart';
import '../theme/app_theme.dart';
import '../utils/media_text.dart';
import '../utils/time_format.dart';
import '../widgets/countdown.dart';
import '../widgets/episode_bar.dart';
import '../widgets/fade_slide_in.dart';
import '../widgets/media_placeholder_art.dart';
import 'add_edit_screen.dart';
import 'detail_screen.dart';

const _gutter = 20.0;
const _railX = 11.0;

void _openAdd(BuildContext context) {
  Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AddEditScreen()));
}

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mediaState = ref.watch(mediaListProvider);

    return Scaffold(
      floatingActionButton: mediaState.hasValue && ref.watch(hasAnyMediaProvider)
          ? FloatingActionButton.extended(
              onPressed: () => _openAdd(context),
              backgroundColor: KColors.sodium,
              foregroundColor: KColors.inkDeep,
              shape: const StadiumBorder(),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add title', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
            )
          : null,
      body: mediaState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Text(
              'Your library couldn\'t be opened. Restart the app to try again.\n\n$err',
              textAlign: TextAlign.center,
              style: KType.meta,
            ),
          ),
        ),
        data: (_) => const _DashboardBody(),
      ),
    );
  }
}

class _DashboardBody extends ConsumerWidget {
  const _DashboardBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(hasAnyMediaProvider)) {
      return const SafeArea(child: _EmptyLibrary());
    }

    final nextUp = ref.watch(nextUpProvider);
    final timeline = ref.watch(timelineProvider).where((m) => m.item.id != nextUp?.item.id).toList();
    final released = ref.watch(releasedProvider);
    final undated = ref.watch(undatedProvider);
    final nothingMatches = nextUp == null && timeline.isEmpty && released.isEmpty && undated.isEmpty;

    return SafeArea(
      bottom: false,
      child: CustomScrollView(
        slivers: [
          const SliverToBoxAdapter(child: _Header()),
          if (nextUp != null)
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(_gutter, 8, _gutter, 8),
              sliver: SliverToBoxAdapter(
                child: FadeSlideIn(child: _NextUpHero(entry: nextUp)),
              ),
            ),
          const SliverPersistentHeader(pinned: true, delegate: _FilterBarDelegate()),
          if (nothingMatches)
            const SliverFillRemaining(hasScrollBody: false, child: _NoMatches())
          else ...[
            const SliverToBoxAdapter(child: _NowMarker()),
            ..._railGroups(timeline),
            if (released.isNotEmpty) ...[
              const SliverToBoxAdapter(child: _GroupHeading('Already out', dim: true)),
              SliverList.builder(
                itemCount: released.length,
                itemBuilder: (_, i) => _RailEntry(item: released[i].item, date: released[i].nextDate, dim: true),
              ),
            ],
            if (undated.isNotEmpty) ...[
              const SliverToBoxAdapter(child: _GroupHeading('No date yet', dim: true)),
              SliverList.builder(
                itemCount: undated.length,
                itemBuilder: (_, i) => _RailEntry(item: undated[i], date: null, dim: true),
              ),
            ],
            const SliverToBoxAdapter(child: _RailEnd()),
          ],
        ],
      ),
    );
  }

  List<Widget> _railGroups(List<MediaWithDate> entries) {
    final now = DateTime.now();
    final groups = <String, List<MediaWithDate>>{};
    for (final e in entries) {
      groups.putIfAbsent(railBucket(e.nextDate, now), () => []).add(e);
    }
    return [
      for (final g in groups.entries) ...[
        SliverToBoxAdapter(child: _GroupHeading(g.key)),
        SliverList.builder(
          itemCount: g.value.length,
          itemBuilder: (_, i) => _RailEntry(item: g.value[i].item, date: g.value[i].nextDate),
        ),
      ],
    ];
  }
}

// ---------------------------------------------------------------------------
// Header + search

class _Header extends ConsumerStatefulWidget {
  const _Header();

  @override
  ConsumerState<_Header> createState() => _HeaderState();
}

class _HeaderState extends ConsumerState<_Header> {
  late final _controller = TextEditingController(text: ref.read(searchQueryProvider));
  final _focus = FocusNode();
  late bool _searching = _controller.text.isNotEmpty;

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() => _searching = !_searching);
    if (_searching) {
      _focus.requestFocus();
    } else {
      _controller.clear();
      ref.read(searchQueryProvider.notifier).state = '';
      _focus.unfocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final part = now.hour < 12
        ? 'morning'
        : now.hour < 17
        ? 'afternoon'
        : 'evening';

    return Padding(
      padding: const EdgeInsets.fromLTRB(_gutter, 12, 8, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Keep Up', style: KType.headline(40).copyWith(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 2),
                    Text(
                      '${DateFormat('EEEE').format(now)} $part, ${DateFormat('d MMMM').format(now)}',
                      style: KType.meta,
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: _toggle,
                tooltip: _searching ? 'Close search' : 'Search your titles',
                iconSize: 24,
                style: IconButton.styleFrom(
                  backgroundColor: _searching ? KColors.raisedHi : Colors.transparent,
                  fixedSize: const Size(48, 48),
                ),
                icon: Icon(_searching ? Icons.close_rounded : Icons.search_rounded, color: KColors.text),
              ),
            ],
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 240),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: _searching
                ? Padding(
                    padding: const EdgeInsets.only(top: 14, right: 12),
                    child: TextField(
                      controller: _controller,
                      focusNode: _focus,
                      textInputAction: TextInputAction.search,
                      onChanged: (v) => ref.read(searchQueryProvider.notifier).state = v,
                      style: KType.bodyText.copyWith(fontSize: 16),
                      decoration: const InputDecoration(
                        hintText: 'Search your titles',
                        prefixIcon: Icon(Icons.search_rounded, size: 20, color: KColors.muted),
                      ),
                    ),
                  )
                : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Next up hero

class _NextUpHero extends StatelessWidget {
  const _NextUpHero({required this.entry});

  final MediaWithDate entry;

  @override
  Widget build(BuildContext context) {
    final item = entry.item;
    final accent = accentColorForBaseType(item.baseType);
    final art = item.coverImagePath ?? item.posterImagePath;
    final heroTag = 'art-${item.id}';
    final progress = episodeProgress(item);

    return PressScale(
      onTap: () => DetailScreen.open(context, item, heroTag),
      child: Semantics(
        button: true,
        label: 'Next up: ${item.title}',
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: Stack(
            children: [
              // Blurred art as ambient light, not as a picture.
              Positioned.fill(
                child: ImageFiltered(
                  imageFilter: ImageFilter.blur(sigmaX: 36, sigmaY: 36, tileMode: TileMode.decal),
                  child: MediaPlaceholderArt(baseType: item.baseType, imagePath: art),
                ),
              ),
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topRight,
                      end: Alignment.bottomLeft,
                      colors: [
                        Color.lerp(KColors.raised, accent, 0.18)!.withValues(alpha: 0.55),
                        KColors.inkDeep.withValues(alpha: 0.92),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 22, 18, 22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  _PulseDot(color: KColors.sodium),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Next up',
                                    style: KType.small.copyWith(color: KColors.sodium, fontWeight: FontWeight.w700),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                item.title,
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                                style: KType.headline(34).copyWith(fontWeight: FontWeight.w800),
                              ),
                              const SizedBox(height: 6),
                              Text(metaLine(item), style: KType.meta.copyWith(color: accent)),
                            ],
                          ),
                        ),
                        const SizedBox(width: 14),
                        SizedBox(
                          width: 84,
                          child: AspectRatio(
                            aspectRatio: 2 / 3,
                            child: Hero(
                              tag: heroTag,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: const [
                                    BoxShadow(color: Colors.black54, blurRadius: 18, offset: Offset(0, 8)),
                                  ],
                                ),
                                child: MediaPlaceholderArt(
                                  baseType: item.baseType,
                                  imagePath: item.posterImagePath ?? item.coverImagePath,
                                  title: item.title,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 26),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: MarqueeCountdown(target: entry.nextDate, size: 92),
                    ),
                    const SizedBox(height: 18),
                    if (progress != null) ...[
                      EpisodeBar(watched: progress.$1, total: progress.$2, accent: accent, height: 5),
                      const SizedBox(height: 12),
                    ],
                    Text(
                      whenLabel(entry.nextDate),
                      style: KType.meta.copyWith(color: KColors.text.withValues(alpha: 0.8)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PulseDot extends StatefulWidget {
  const _PulseDot({required this.color});

  final Color color;

  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1600));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduce = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (reduce) {
      _c.stop();
    } else if (!_c.isAnimating) {
      _c.repeat();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 10,
      height: 10,
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, _) => CustomPaint(painter: _PulsePainter(widget.color, _c.value)),
      ),
    );
  }
}

class _PulsePainter extends CustomPainter {
  _PulsePainter(this.color, this.t);

  final Color color;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    canvas.drawCircle(c, 4 + 8 * t, Paint()..color = color.withValues(alpha: 0.45 * (1 - t)));
    canvas.drawCircle(c, 4, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_PulsePainter old) => old.t != t || old.color != color;
}

// ---------------------------------------------------------------------------
// Filter bar

class _FilterBarDelegate extends SliverPersistentHeaderDelegate {
  const _FilterBarDelegate();

  @override
  double get minExtent => 60;
  @override
  double get maxExtent => 60;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return ColoredBox(
      color: KColors.ink,
      child: Column(
        children: [
          const Expanded(child: _FilterBar()),
          AnimatedOpacity(
            opacity: overlapsContent || shrinkOffset > 0 ? 1 : 0,
            duration: const Duration(milliseconds: 150),
            child: const Divider(),
          ),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(_FilterBarDelegate oldDelegate) => false;
}

class _FilterBar extends ConsumerWidget {
  const _FilterBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(categoryFilterProvider);
    final counts = ref.watch(categoryCountsProvider);

    Widget tab(MediaBaseType? type, String label) {
      final isSelected = selected == type;
      final count = counts[type] ?? 0;
      final accent = type == null ? KColors.sodium : accentColorForBaseType(type);
      return Semantics(
        selected: isSelected,
        button: true,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => ref.read(categoryFilterProvider.notifier).state = type,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 180),
                      style: KType.headline(22)
                          .copyWith(color: isSelected ? KColors.text : KColors.faint, fontWeight: FontWeight.w700),
                      child: Text(label),
                    ),
                    const SizedBox(width: 3),
                    Text(
                      '$count',
                      style: KType.small.copyWith(fontSize: 11, color: isSelected ? accent : KColors.faint),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  height: 3,
                  width: isSelected ? 18 : 0,
                  decoration: BoxDecoration(color: accent, borderRadius: BorderRadius.circular(3)),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return ListView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: _gutter - 10),
      children: [
        tab(null, 'All'),
        for (final t in MediaBaseType.values)
          if ((counts[t] ?? 0) > 0 || selected == t) tab(t, t == MediaBaseType.movie ? 'Movies' : labelForBaseType(t)),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Time rail

/// Paints the rail segment in a row's left gutter, with an optional node.
class _RailPainter extends CustomPainter {
  _RailPainter({this.nodeY, this.nodeColor, this.nodeRadius = 4, this.fadeOut = false, this.startY = 0});

  final double? nodeY;
  final Color? nodeColor;
  final double nodeRadius;

  final bool fadeOut;
  final double startY;

  static const lineColor = KColors.line;

  @override
  void paint(Canvas canvas, Size size) {
    final line = Paint()
      ..strokeWidth = 2
      ..color = lineColor;
    if (fadeOut) {
      line.shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [lineColor, lineColor.withValues(alpha: 0)],
      ).createShader(Offset.zero & size);
    }
    canvas.drawLine(Offset(_railX, startY), Offset(_railX, size.height), line);
    if (nodeY != null && nodeColor != null) {
      canvas.drawCircle(Offset(_railX, nodeY!), nodeRadius + 3, Paint()..color = KColors.ink);
      canvas.drawCircle(Offset(_railX, nodeY!), nodeRadius, Paint()..color = nodeColor!);
    }
  }

  @override
  bool shouldRepaint(_RailPainter old) => old.nodeY != nodeY || old.nodeColor != nodeColor || old.fadeOut != fadeOut;
}

class _RailRow extends StatelessWidget {
  const _RailRow({required this.painter, required this.child});

  final CustomPainter painter;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: _gutter - _railX + 1, right: _gutter),
      child: CustomPaint(
        painter: painter,
        child: Padding(padding: const EdgeInsets.only(left: 34), child: child),
      ),
    );
  }
}

class _NowMarker extends StatelessWidget {
  const _NowMarker();

  @override
  Widget build(BuildContext context) {
    return _RailRow(
      painter: _RailPainter(startY: 30),
      child: Padding(
        padding: const EdgeInsets.only(top: 18, bottom: 10),
        child: Ticker(
          builder: (context, now) => Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: -34 + _railX - 5,
                top: 3,
                child: const _PulseDot(color: KColors.sodium),
              ),
              Text(
                'Now, ${DateFormat.jm().format(now)}',
                style: KType.small.copyWith(color: KColors.sodium, fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GroupHeading extends StatelessWidget {
  const _GroupHeading(this.label, {this.dim = false});

  final String label;
  final bool dim;

  @override
  Widget build(BuildContext context) {
    return _RailRow(
      painter: _RailPainter(nodeY: 34, nodeColor: dim ? KColors.faint : KColors.text, nodeRadius: 5),
      child: Padding(
        padding: const EdgeInsets.only(top: 18, bottom: 12),
        child: Text(label, style: KType.headline(30).copyWith(color: dim ? KColors.muted : KColors.text)),
      ),
    );
  }
}

class _RailEntry extends StatelessWidget {
  const _RailEntry({required this.item, required this.date, this.dim = false});

  final MediaItem item;
  final DateTime? date;
  final bool dim;

  @override
  Widget build(BuildContext context) {
    final accent = accentColorForBaseType(item.baseType);
    final heroTag = 'art-${item.id}';
    final progress = episodeProgress(item);
    final d = date;

    return _RailRow(
      painter: _RailPainter(nodeY: 16, nodeColor: dim ? accent.withValues(alpha: 0.5) : accent, nodeRadius: 3.5),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => DetailScreen.open(context, item, heroTag),
        child: Opacity(
          opacity: dim ? 0.62 : 1,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 60,
                  child: AspectRatio(
                    aspectRatio: 2 / 3,
                    child: Hero(
                      tag: heroTag,
                      child: MediaPlaceholderArt(
                        baseType: item.baseType,
                        imagePath: item.posterImagePath ?? item.coverImagePath,
                        title: item.title,
                        borderRadius: BorderRadius.circular(10),
                        iconSize: 22,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 2),
                      Text(item.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: KType.title),
                      const SizedBox(height: 3),
                      Text(metaLine(item), style: KType.meta.copyWith(color: accent.withValues(alpha: 0.9))),
                      if (d != null) ...[const SizedBox(height: 2), Text(whenLabel(d), style: KType.small)],
                      if (progress != null) ...[
                        const SizedBox(height: 10),
                        EpisodeBar(watched: progress.$1, total: progress.$2, accent: accent, height: 4),
                      ],
                    ],
                  ),
                ),
                if (d != null) ...[
                  const SizedBox(width: 12),
                  Ticker(
                    builder: (context, now) =>
                        Text(shortUntil(d, now), style: KType.numerals(26, color: dim ? KColors.muted : KColors.text)),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RailEnd extends StatelessWidget {
  const _RailEnd();

  @override
  Widget build(BuildContext context) {
    return _RailRow(painter: _RailPainter(fadeOut: true), child: const SizedBox(height: 120));
  }
}

// ---------------------------------------------------------------------------
// Empty states

class _EmptyLibrary extends StatelessWidget {
  const _EmptyLibrary();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 24, 28, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Keep Up', style: KType.headline(40).copyWith(fontWeight: FontWeight.w800)),
          const Spacer(),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text('00:00:00', style: KType.numerals(110, color: KColors.line)),
          ),
          const SizedBox(height: 24),
          Text('Nothing on the clock yet.', style: KType.headline(34)),
          const SizedBox(height: 10),
          const Text(
            'Add a show, film, anime, or album and Keep Up counts down to its next release.',
            style: KType.bodyText,
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => _openAdd(context),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add your first title'),
            ),
          ),
        ],
      ),
    );
  }
}

class _NoMatches extends ConsumerWidget {
  const _NoMatches();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final query = ref.watch(searchQueryProvider).trim();
    final category = ref.watch(categoryFilterProvider);

    final message = query.isNotEmpty
        ? 'No titles match “$query”.'
        : 'No ${category == null ? '' : '${labelForBaseType(category).toLowerCase()} '}titles tracked.';

    return Padding(
      padding: const EdgeInsets.fromLTRB(_gutter, 40, _gutter, 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(message, style: KType.headline(28)),
          const SizedBox(height: 16),
          if (category != null)
            TextButton.icon(
              onPressed: () => ref.read(categoryFilterProvider.notifier).state = null,
              icon: const Icon(Icons.filter_alt_off_rounded, size: 18),
              label: const Text('Show all categories'),
            ),
        ],
      ),
    );
  }
}
