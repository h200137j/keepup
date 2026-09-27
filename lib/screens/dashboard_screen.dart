import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/media_item.dart';
import '../providers/media_provider.dart';
import '../widgets/dropping_soon_card.dart';
import '../widgets/fade_slide_in.dart';
import '../widgets/media_placeholder_art.dart';
import '../widgets/tracking_grid_tile.dart';
import 'add_edit_screen.dart';

const _categoryLabels = {
  MediaBaseType.tv: 'TV',
  MediaBaseType.movie: 'Movie',
  MediaBaseType.anime: 'Anime',
  MediaBaseType.music: 'Music',
};

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mediaState = ref.watch(mediaListProvider);
    final droppingSoon = ref.watch(droppingSoonProvider);
    final grid = ref.watch(trackingGridProvider);
    final hasAnyMedia = ref.watch(hasAnyMediaProvider);

    return Scaffold(
      floatingActionButton: _GradientFab(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const AddEditScreen()),
        ),
      ),
      body: mediaState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Failed to load: $err')),
        data: (_) => CustomScrollView(
          slivers: [
            const SliverAppBar(
              pinned: true,
              backgroundColor: Color(0xff0f0f13),
              title: Text('Keep Up'),
            ),
            const SliverPadding(
              padding: EdgeInsets.fromLTRB(20, 12, 20, 0),
              sliver: SliverToBoxAdapter(child: _SearchField()),
            ),
            const SliverPadding(
              padding: EdgeInsets.fromLTRB(20, 14, 20, 0),
              sliver: SliverToBoxAdapter(child: _CategoryChips()),
            ),
            if (!hasAnyMedia)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: _EmptyState(),
              )
            else ...[
              if (droppingSoon.isNotEmpty) ...[
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 26, 20, 12),
                  sliver: SliverToBoxAdapter(
                    child: _SectionHeader('Dropping Soon', subtitle: '${droppingSoon.length} in the next 24h'),
                  ),
                ),
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 320,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.only(left: 20, right: 4),
                      itemCount: droppingSoon.length,
                      itemBuilder: (context, i) => FadeSlideIn(
                        delay: Duration(milliseconds: 60 * i),
                        child: DroppingSoonCard(entry: droppingSoon[i]),
                      ),
                    ),
                  ),
                ),
              ],
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 26, 20, 12),
                sliver: SliverToBoxAdapter(child: const _SectionHeader('Tracking')),
              ),
              if (grid.isEmpty)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Text('No matches.', style: TextStyle(color: Colors.white54)),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 160,
                      mainAxisSpacing: 14,
                      crossAxisSpacing: 14,
                      childAspectRatio: 0.68,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, i) => FadeSlideIn(
                        delay: Duration(milliseconds: 30 * (i % 12)),
                        child: TrackingGridTile(entry: grid[i]),
                      ),
                      childCount: grid.length,
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _GradientFab extends StatelessWidget {
  const _GradientFab({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          colors: [Color(0xff9b7fff), Color(0xff6a4fe0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xff7c5cff).withValues(alpha: 0.45),
            blurRadius: 22,
            spreadRadius: -2,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onPressed,
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.add_rounded, color: Colors.white),
                SizedBox(width: 8),
                Text(
                  'Add title',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, letterSpacing: 0.2),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SearchField extends ConsumerStatefulWidget {
  const _SearchField();

  @override
  ConsumerState<_SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends ConsumerState<_SearchField> {
  final _focusNode = FocusNode();
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() => setState(() => _focused = _focusNode.hasFocus));
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        boxShadow: _focused
            ? [
                BoxShadow(
                  color: const Color(0xff7c5cff).withValues(alpha: 0.3),
                  blurRadius: 18,
                  spreadRadius: -4,
                ),
              ]
            : const [],
      ),
      child: TextField(
        focusNode: _focusNode,
        onChanged: (v) => ref.read(searchQueryProvider.notifier).state = v,
        decoration: const InputDecoration(
          hintText: 'Search your titles…',
          prefixIcon: Icon(Icons.search, size: 20),
          isDense: true,
        ),
      ),
    );
  }
}

class _CategoryChips extends ConsumerWidget {
  const _CategoryChips();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(categoryFilterProvider);

    return SizedBox(
      height: 38,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _CategoryChip(
            label: 'All',
            icon: Icons.apps_rounded,
            accent: Colors.white,
            selected: selected == null,
            onTap: () => ref.read(categoryFilterProvider.notifier).state = null,
          ),
          for (final type in MediaBaseType.values)
            _CategoryChip(
              label: _categoryLabels[type]!,
              icon: iconForBaseType(type),
              accent: accentColorForBaseType(type),
              selected: selected == type,
              onTap: () => ref.read(categoryFilterProvider.notifier).state = type,
            ),
        ],
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.icon,
    required this.accent,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color accent;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? accent.withValues(alpha: 0.22) : Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: selected ? accent.withValues(alpha: 0.7) : Colors.white.withValues(alpha: 0.1)),
            boxShadow: selected
                ? [BoxShadow(color: accent.withValues(alpha: 0.25), blurRadius: 14, spreadRadius: -4)]
                : const [],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 15, color: selected ? accent : Colors.white60),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: selected ? Colors.white : Colors.white60,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.label, {this.subtitle});

  final String label;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -0.2),
        ),
        if (subtitle != null) ...[
          const SizedBox(width: 8),
          Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: Text(subtitle!, style: const TextStyle(color: Colors.white38, fontSize: 13)),
          ),
        ],
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: FadeSlideIn(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [const Color(0xff7c5cff).withValues(alpha: 0.28), Colors.transparent],
                  ),
                ),
                child: Icon(iconForBaseType(MediaBaseType.tv), size: 44, color: Colors.white38),
              ),
              const SizedBox(height: 20),
              const Text(
                'Nothing tracked yet',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              const Text(
                'Tap "Add title" to track a show, movie, anime, or album.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white54),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
