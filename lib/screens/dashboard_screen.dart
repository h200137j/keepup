import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/media_item.dart';
import '../providers/media_provider.dart';
import '../widgets/dropping_soon_card.dart';
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const AddEditScreen()),
        ),
        icon: const Icon(Icons.add),
        label: const Text('Add title'),
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
              padding: EdgeInsets.fromLTRB(20, 12, 20, 0),
              sliver: SliverToBoxAdapter(child: _CategoryChips()),
            ),
            if (!hasAnyMedia)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: _EmptyState(),
              )
            else ...[
              if (droppingSoon.isNotEmpty) ...[
                const SliverPadding(
                  padding: EdgeInsets.fromLTRB(20, 24, 20, 12),
                  sliver: SliverToBoxAdapter(child: _SectionHeader('Dropping Soon')),
                ),
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 320,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.only(left: 20, right: 4),
                      itemCount: droppingSoon.length,
                      itemBuilder: (context, i) => DroppingSoonCard(entry: droppingSoon[i]),
                    ),
                  ),
                ),
              ],
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
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
                      (context, i) => TrackingGridTile(entry: grid[i]),
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

class _SearchField extends ConsumerWidget {
  const _SearchField();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return TextField(
      onChanged: (v) => ref.read(searchQueryProvider.notifier).state = v,
      decoration: InputDecoration(
        hintText: 'Search your titles…',
        prefixIcon: const Icon(Icons.search, size: 20),
        isDense: true,
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.06),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
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
      height: 36,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _chip(ref, label: 'All', value: null, selected: selected == null),
          for (final type in MediaBaseType.values)
            _chip(ref, label: _categoryLabels[type]!, value: type, selected: selected == type),
        ],
      ),
    );
  }

  Widget _chip(WidgetRef ref, {required String label, required MediaBaseType? value, required bool selected}) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => ref.read(categoryFilterProvider.notifier).state = value,
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(iconForBaseType(MediaBaseType.tv), size: 56, color: Colors.white24),
            const SizedBox(height: 16),
            const Text(
              'Nothing tracked yet',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
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
    );
  }
}
