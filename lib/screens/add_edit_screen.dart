import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../models/media_item.dart';
import '../providers/media_provider.dart';
import '../services/image_storage_service.dart';
import '../widgets/fade_slide_in.dart';
import '../widgets/media_placeholder_art.dart';
import 'anilist_search_sheet.dart';

const _weekdayNames = [
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
  'Sunday',
];

/// Create/edit form for a [MediaItem]. Pass an existing [item] to edit it
/// in place; omit it to create a new one.
class AddEditScreen extends ConsumerStatefulWidget {
  const AddEditScreen({super.key, this.item});

  final MediaItem? item;

  @override
  ConsumerState<AddEditScreen> createState() => _AddEditScreenState();
}

class _AddEditScreenState extends ConsumerState<AddEditScreen> {
  late final _titleController = TextEditingController(text: widget.item?.title ?? '');
  final _formKey = GlobalKey<FormState>();

  late MediaBaseType _baseType = widget.item?.baseType ?? MediaBaseType.tv;
  late final TvData _tvData = _cloneTv(widget.item?.tvData);
  late final AnimeData _animeData = _cloneAnime(widget.item?.animeData);
  late final MovieData _movieData = _cloneMovie(widget.item?.movieData);
  late final MusicData _musicData = _cloneMusic(widget.item?.musicData);

  String? _posterImagePath;
  String? _coverImagePath;
  bool _saving = false;

  static TvData _cloneTv(TvData? d) => TvData()
    ..currentSeason = d?.currentSeason
    ..status = d?.status ?? TvStatus.airing
    ..releaseDayOfWeek = d?.releaseDayOfWeek ?? DateTime.now().weekday
    ..nextEpisodeNumber = d?.nextEpisodeNumber
    ..totalEpisodes = d?.totalEpisodes
    ..nextEpisodeDate = d?.nextEpisodeDate;

  static AnimeData _cloneAnime(AnimeData? d) => AnimeData()
    ..format = d?.format ?? AnimeFormat.tv
    ..cour = d?.cour
    ..nextAiringEpisodeTimestamp = d?.nextAiringEpisodeTimestamp
    ..aniListId = d?.aniListId;

  static MovieData _cloneMovie(MovieData? d) => MovieData()
    ..releaseDate = d?.releaseDate
    ..runtimeMinutes = d?.runtimeMinutes;

  static MusicData _cloneMusic(MusicData? d) => MusicData()
    ..releaseDate = d?.releaseDate
    ..trackCount = d?.trackCount;

  @override
  void initState() {
    super.initState();
    _posterImagePath = widget.item?.posterImagePath;
    _coverImagePath = widget.item?.coverImagePath;
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  bool get _isNew => widget.item == null;

  Future<void> _pickImage({required bool isPoster}) async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked == null) return;
    final savedPath = await persistPickedImage(picked);
    setState(() {
      if (isPoster) {
        _posterImagePath = savedPath;
      } else {
        _coverImagePath = savedPath;
      }
    });
  }

  Future<void> _searchAniList() async {
    final result = await AniListSearchSheet.show(context);
    if (result == null) return;
    setState(() {
      _titleController.text = result.title;
      _coverImagePath = result.coverImageUrl;
      _animeData.format = _animeFormatFrom(result.format);
      _animeData.aniListId = result.id.toString();
      if (result.nextAiringEpisodeTimestamp != null) {
        _animeData.nextAiringEpisodeTimestamp = result.nextAiringEpisodeTimestamp;
      }
    });
  }

  AnimeFormat _animeFormatFrom(String raw) {
    switch (raw) {
      case 'MOVIE':
        return AnimeFormat.movie;
      case 'OVA':
      case 'ONA':
      case 'SPECIAL':
        return AnimeFormat.ova;
      default:
        return AnimeFormat.tv;
    }
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _saving = true);

    final item = widget.item ?? MediaItem();
    item.title = _titleController.text.trim();
    item.baseType = _baseType;
    item.posterImagePath = _posterImagePath;
    item.coverImagePath = _coverImagePath;
    item.tvData = _baseType == MediaBaseType.tv ? _tvData : null;
    item.animeData = _baseType == MediaBaseType.anime ? _animeData : null;
    item.movieData = _baseType == MediaBaseType.movie ? _movieData : null;
    item.musicData = _baseType == MediaBaseType.music ? _musicData : null;

    await saveMediaItem(ref, item);

    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isNew ? 'Add title' : 'Edit title')),
      body: Form(
        key: _formKey,
        child: FadeSlideIn(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _CategorySelector(
                selected: _baseType,
                onChanged: (v) => setState(() => _baseType = v),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Title', border: OutlineInputBorder()),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Title is required' : null,
              ),
              const SizedBox(height: 20),
              if (_baseType == MediaBaseType.anime) ...[
                OutlinedButton.icon(
                  onPressed: _searchAniList,
                  icon: const Icon(Icons.search),
                  label: const Text('Search AniList'),
                ),
                if (_animeData.aniListId != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      'Linked to AniList #${_animeData.aniListId}',
                      style: const TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                  ),
                const SizedBox(height: 20),
              ],
              const _FieldSectionLabel('Artwork'),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 110,
                    child: _ImagePickerTile(
                      label: 'Poster',
                      hint: '2:3 · 500×750px+',
                      aspectRatio: 2 / 3,
                      path: _posterImagePath,
                      baseType: _baseType,
                      onPick: () => _pickImage(isPoster: true),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _ImagePickerTile(
                      label: 'Cover',
                      hint: '16:9 · 1280×720px+',
                      aspectRatio: 16 / 9,
                      path: _coverImagePath,
                      baseType: _baseType,
                      onPick: () => _pickImage(isPoster: false),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              _FieldSectionLabel(_detailsLabel(_baseType)),
              const SizedBox(height: 12),
              _buildTypeFields(),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox(
                          width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Save'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeFields() {
    switch (_baseType) {
      case MediaBaseType.tv:
        return _TvFields(data: _tvData, onChanged: () => setState(() {}));
      case MediaBaseType.movie:
        return _MovieFields(data: _movieData, onChanged: () => setState(() {}));
      case MediaBaseType.anime:
        return _AnimeFields(data: _animeData, onChanged: () => setState(() {}));
      case MediaBaseType.music:
        return _MusicFields(data: _musicData, onChanged: () => setState(() {}));
    }
  }

  String _detailsLabel(MediaBaseType type) {
    switch (type) {
      case MediaBaseType.tv:
        return 'TV details';
      case MediaBaseType.movie:
        return 'Movie details';
      case MediaBaseType.anime:
        return 'Anime details';
      case MediaBaseType.music:
        return 'Music details';
    }
  }
}

class _FieldSectionLabel extends StatelessWidget {
  const _FieldSectionLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: const TextStyle(
        color: Colors.white38,
        fontSize: 12,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.8,
      ),
    );
  }
}

class _CategorySelector extends StatelessWidget {
  const _CategorySelector({required this.selected, required this.onChanged});

  final MediaBaseType selected;
  final ValueChanged<MediaBaseType> onChanged;

  static const _labels = {
    MediaBaseType.tv: 'TV',
    MediaBaseType.movie: 'Movie',
    MediaBaseType.anime: 'Anime',
    MediaBaseType.music: 'Music',
  };

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final type in MediaBaseType.values)
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: type == MediaBaseType.values.last ? 0 : 8),
              child: _CategoryOption(
                label: _labels[type]!,
                icon: iconForBaseType(type),
                accent: accentColorForBaseType(type),
                selected: selected == type,
                onTap: () => onChanged(type),
              ),
            ),
          ),
      ],
    );
  }
}

class _CategoryOption extends StatelessWidget {
  const _CategoryOption({
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
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? accent.withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: selected ? accent.withValues(alpha: 0.65) : Colors.white.withValues(alpha: 0.08)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: selected ? accent : Colors.white54),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected ? Colors.white : Colors.white54,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ImagePickerTile extends StatelessWidget {
  const _ImagePickerTile({
    required this.label,
    required this.path,
    required this.baseType,
    required this.onPick,
    required this.aspectRatio,
    required this.hint,
  });

  final String label;
  final String? path;
  final MediaBaseType baseType;
  final VoidCallback onPick;
  final double aspectRatio;
  final String hint;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPick,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: aspectRatio,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  MediaPlaceholderArt(baseType: baseType, imagePath: path, borderRadius: BorderRadius.circular(14)),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  Positioned(
                    right: 6,
                    bottom: 6,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.55),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.edit_rounded, size: 14, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600)),
          Text(
            hint,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white38, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _TvFields extends StatelessWidget {
  const _TvFields({required this.data, required this.onChanged});

  final TvData data;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          initialValue: data.currentSeason?.toString() ?? '',
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Current season', border: OutlineInputBorder()),
          onChanged: (v) => data.currentSeason = int.tryParse(v),
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<TvStatus>(
          initialValue: data.status,
          decoration: const InputDecoration(labelText: 'Status', border: OutlineInputBorder()),
          items: TvStatus.values
              .map((s) => DropdownMenuItem(value: s, child: Text(s.name)))
              .toList(),
          onChanged: (v) {
            if (v != null) data.status = v;
            onChanged();
          },
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<int>(
          initialValue: data.releaseDayOfWeek,
          decoration: const InputDecoration(labelText: 'Release day', border: OutlineInputBorder()),
          items: List.generate(
            7,
            (i) => DropdownMenuItem(value: i + 1, child: Text(_weekdayNames[i])),
          ),
          onChanged: (v) {
            if (v != null) data.releaseDayOfWeek = v;
            onChanged();
          },
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xff8c6bff).withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(16),
            border: Border(left: BorderSide(color: const Color(0xff8c6bff).withValues(alpha: 0.6), width: 3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.visibility_rounded, size: 16, color: Color(0xffb9a6ff)),
                  const SizedBox(width: 6),
                  Text('Already watching?', style: Theme.of(context).textTheme.labelLarge),
                ],
              ),
              const SizedBox(height: 4),
              const Text(
                'Set where you are if this show is already in progress.',
                style: TextStyle(color: Colors.white54, fontSize: 12),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      initialValue: data.nextEpisodeNumber?.toString() ?? '',
                      keyboardType: TextInputType.number,
                      decoration:
                          const InputDecoration(labelText: 'Next episode #', border: OutlineInputBorder()),
                      onChanged: (v) => data.nextEpisodeNumber = int.tryParse(v),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      initialValue: data.totalEpisodes?.toString() ?? '',
                      keyboardType: TextInputType.number,
                      decoration:
                          const InputDecoration(labelText: 'Total episodes', border: OutlineInputBorder()),
                      onChanged: (v) => data.totalEpisodes = int.tryParse(v),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _DateTimePickerField(
                label: 'Next episode date (override)',
                value: data.nextEpisodeDate,
                includeTime: true,
                onChanged: (dt) {
                  data.nextEpisodeDate = dt;
                  onChanged();
                },
                onClear: data.nextEpisodeDate == null
                    ? null
                    : () {
                        data.nextEpisodeDate = null;
                        onChanged();
                      },
              ),
              const SizedBox(height: 4),
              const Text(
                'Overrides the release-day countdown for a one-off delay. Clear '
                'it to go back to the weekly schedule above.',
                style: TextStyle(color: Colors.white54, fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MovieFields extends StatelessWidget {
  const _MovieFields({required this.data, required this.onChanged});

  final MovieData data;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _DateTimePickerField(
          label: 'Release date',
          value: data.releaseDate,
          includeTime: false,
          onChanged: (dt) {
            data.releaseDate = dt;
            onChanged();
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          initialValue: data.runtimeMinutes?.toString() ?? '',
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Runtime (minutes)', border: OutlineInputBorder()),
          onChanged: (v) => data.runtimeMinutes = int.tryParse(v),
        ),
      ],
    );
  }
}

class _AnimeFields extends StatelessWidget {
  const _AnimeFields({required this.data, required this.onChanged});

  final AnimeData data;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<AnimeFormat>(
          initialValue: data.format,
          decoration: const InputDecoration(labelText: 'Format', border: OutlineInputBorder()),
          items: AnimeFormat.values
              .map((f) => DropdownMenuItem(value: f, child: Text(f.name.toUpperCase())))
              .toList(),
          onChanged: (v) {
            if (v != null) data.format = v;
            onChanged();
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          initialValue: data.cour?.toString() ?? '',
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Cour', border: OutlineInputBorder()),
          onChanged: (v) => data.cour = int.tryParse(v),
        ),
        const SizedBox(height: 16),
        _DateTimePickerField(
          label: 'Next episode airs',
          value: data.nextAiringEpisodeTimestamp,
          includeTime: true,
          onChanged: (dt) {
            data.nextAiringEpisodeTimestamp = dt;
            onChanged();
          },
        ),
      ],
    );
  }
}

class _MusicFields extends StatelessWidget {
  const _MusicFields({required this.data, required this.onChanged});

  final MusicData data;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _DateTimePickerField(
          label: 'Release date',
          value: data.releaseDate,
          includeTime: false,
          onChanged: (dt) {
            data.releaseDate = dt;
            onChanged();
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          initialValue: data.trackCount?.toString() ?? '',
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Track count', border: OutlineInputBorder()),
          onChanged: (v) => data.trackCount = int.tryParse(v),
        ),
      ],
    );
  }
}

class _DateTimePickerField extends StatelessWidget {
  const _DateTimePickerField({
    required this.label,
    required this.value,
    required this.onChanged,
    required this.includeTime,
    this.onClear,
  });

  final String label;
  final DateTime? value;
  final bool includeTime;
  final ValueChanged<DateTime?> onChanged;
  final VoidCallback? onClear;

  Future<void> _pick(BuildContext context) async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: value ?? now,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 10),
    );
    if (date == null) return;

    if (!includeTime) {
      onChanged(date);
      return;
    }
    if (!context.mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: value != null ? TimeOfDay.fromDateTime(value!) : TimeOfDay.now(),
    );
    onChanged(DateTime(date.year, date.month, date.day, time?.hour ?? 0, time?.minute ?? 0));
  }

  @override
  Widget build(BuildContext context) {
    final display = value == null
        ? 'Not set'
        : includeTime
            ? DateFormat.yMMMd().add_jm().format(value!)
            : DateFormat.yMMMd().format(value!);

    return InkWell(
      onTap: () => _pick(context),
      child: InputDecorator(
        decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
        child: Row(
          children: [
            Expanded(child: Text(display)),
            if (onClear != null)
              IconButton(
                icon: const Icon(Icons.close, size: 18),
                onPressed: onClear,
                tooltip: 'Clear',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            const SizedBox(width: 8),
            const Icon(Icons.calendar_today, size: 18),
          ],
        ),
      ),
    );
  }
}
