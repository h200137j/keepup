import 'dart:convert';

import 'package:http/http.dart' as http;

class AniListResult {
  const AniListResult({
    required this.id,
    required this.title,
    required this.coverImageUrl,
    required this.format,
    this.nextAiringEpisodeTimestamp,
    this.currentEpisode,
  });

  final int id;
  final String title;
  final String? coverImageUrl;
  final String format;
  final DateTime? nextAiringEpisodeTimestamp;
  final int? currentEpisode;
}

const _searchQuery = r'''
query ($search: String) {
  Page(page: 1, perPage: 10) {
    media(search: $search, type: ANIME) {
      id
      format
      title { romaji english }
      coverImage { large }
      nextAiringEpisode { airingAt episode }
    }
  }
}
''';

Future<List<AniListResult>> searchAniList(String query) async {
  if (query.trim().isEmpty) return [];

  final response = await http
      .post(
        Uri.parse('https://graphql.anilist.co'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'query': _searchQuery,
          'variables': {'search': query},
        }),
      )
      .timeout(const Duration(seconds: 10));

  if (response.statusCode != 200) {
    throw Exception('AniList request failed (${response.statusCode})');
  }

  final body = jsonDecode(response.body) as Map<String, dynamic>;
  final media = (body['data']?['Page']?['media'] as List?) ?? [];

  return media.map((raw) {
    final m = raw as Map<String, dynamic>;
    final title = m['title'] as Map<String, dynamic>;
    final nextEp = m['nextAiringEpisode'] as Map<String, dynamic>?;

    return AniListResult(
      id: m['id'] as int,
      title: (title['english'] as String?) ?? (title['romaji'] as String? ?? 'Untitled'),
      coverImageUrl: (m['coverImage'] as Map<String, dynamic>?)?['large'] as String?,
      format: (m['format'] as String?) ?? 'TV',
      nextAiringEpisodeTimestamp: nextEp == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch((nextEp['airingAt'] as int) * 1000),
      currentEpisode: nextEp?['episode'] as int?,
    );
  }).toList();
}
