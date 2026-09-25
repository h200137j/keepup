import 'dart:async';

import 'package:flutter/material.dart';

import '../services/anilist_service.dart';

/// Modal search sheet for picking a title from AniList. Pops with the
/// chosen [AniListResult], or null if dismissed.
class AniListSearchSheet extends StatefulWidget {
  const AniListSearchSheet({super.key});

  static Future<AniListResult?> show(BuildContext context) {
    return showModalBottomSheet<AniListResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xff17171d),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
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
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: TextField(
                  controller: _controller,
                  autofocus: true,
                  onChanged: _onChanged,
                  decoration: const InputDecoration(
                    hintText: 'Search AniList…',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
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
      return const Center(
        child: Text('Type a title to search', style: TextStyle(color: Colors.white54)),
      );
    }

    return FutureBuilder<List<AniListResult>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Search failed: ${snapshot.error}'));
        }
        final results = snapshot.data ?? [];
        if (results.isEmpty) {
          return const Center(child: Text('No results', style: TextStyle(color: Colors.white54)));
        }
        return ListView.builder(
          itemCount: results.length,
          itemBuilder: (context, i) {
            final r = results[i];
            return ListTile(
              leading: SizedBox(
                width: 44,
                height: 60,
                child: r.coverImageUrl != null
                    ? Image.network(r.coverImageUrl!, fit: BoxFit.cover)
                    : const ColoredBox(color: Colors.white12),
              ),
              title: Text(r.title),
              subtitle: Text(r.format),
              onTap: () => Navigator.of(context).pop(r),
            );
          },
        );
      },
    );
  }
}
