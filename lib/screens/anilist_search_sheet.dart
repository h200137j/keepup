import 'dart:async';

import 'package:flutter/material.dart';

import '../services/anilist_service.dart';
import '../theme/app_theme.dart';
import '../utils/time_format.dart';

/// Modal search sheet for picking a title from AniList. Pops with the
/// chosen [AniListResult], or null if dismissed.
class AniListSearchSheet extends StatefulWidget {
  const AniListSearchSheet({super.key});

  static Future<AniListResult?> show(BuildContext context) {
    return showModalBottomSheet<AniListResult>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const AniListSearchSheet(),
    );
  }

  @override
  State<AniListSearchSheet> createState() => _AniListSearchSheetState();
}

class _AniListSearchSheetState extends State<AniListSearchSheet> {
  final _controller = TextEditingController();
  Timer? _debounce;
  Future<List<AniListResult>>? _future;

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      if (!mounted) return;
      setState(() => _future = searchAniList(value));
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.75,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Find on AniList', style: KType.headline(30)),
                    const SizedBox(height: 14),
                    TextField(
                      controller: _controller,
                      autofocus: true,
                      onChanged: _onChanged,
                      textInputAction: TextInputAction.search,
                      style: KType.bodyText.copyWith(fontSize: 16),
                      decoration: const InputDecoration(
                        hintText: 'Anime title, in English or romaji',
                        prefixIcon: Icon(Icons.search_rounded, color: KColors.muted),
                        fillColor: KColors.raisedHi,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(child: _buildResults()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResults() {
    final future = _future;
    if (future == null) {
      return const _SheetMessage('Results appear as you type.');
    }

    return FutureBuilder<List<AniListResult>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return const _SheetMessage('AniList didn\'t respond. Check your connection and try the search again.');
        }
        final results = snapshot.data ?? [];
        if (results.isEmpty) {
          return const _SheetMessage('No anime found with that title. Try the romaji or a shorter name.');
        }
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
          itemCount: results.length,
          itemBuilder: (context, i) {
            final r = results[i];
            final next = r.nextAiringEpisodeTimestamp;
            return InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => Navigator.of(context).pop(r),
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: SizedBox(
                        width: 46,
                        height: 68,
                        child: r.coverImageUrl != null
                            ? Image.network(
                                r.coverImageUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, _) => const ColoredBox(color: KColors.raisedHi),
                              )
                            : const ColoredBox(color: KColors.raisedHi),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(r.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: KType.title),
                          const SizedBox(height: 3),
                          Text(
                            next == null ? r.format : 'Episode ${r.currentEpisode ?? '?'} airs ${whenLabel(next)}',
                            style: KType.small.copyWith(color: next == null ? KColors.muted : const Color(0xff5ce6c0)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _SheetMessage extends StatelessWidget {
  const _SheetMessage(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 24, 28, 0),
      child: Align(
        alignment: Alignment.topLeft,
        child: Text(text, style: KType.meta),
      ),
    );
  }
}
