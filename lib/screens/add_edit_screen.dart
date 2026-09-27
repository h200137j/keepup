import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../models/media_item.dart';
import '../providers/media_provider.dart';
import '../services/image_storage_service.dart';
import '../theme/app_theme.dart';
import '../utils/media_text.dart';
import '../utils/time_format.dart';
import '../widgets/media_placeholder_art.dart';
import 'anilist_search_sheet.dart';

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
    final accent = accentColorForBaseType(_baseType);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Discard',
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(_isNew ? 'New title' : 'Edit title'),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
          child: FilledButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: KColors.inkDeep),
                  )
                : Text(_isNew ? 'Start counting down' : 'Save changes'),
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
          children: [
            _CategorySelector(selected: _baseType, onChanged: (v) => setState(() => _baseType = v)),
            const SizedBox(height: 18),
            TextFormField(
              controller: _titleController,
              textCapitalization: TextCapitalization.words,
              style: KType.headline(40).copyWith(fontWeight: FontWeight.w800),
              cursorColor: accent,
              decoration: InputDecoration(
                hintText: 'Title',
                hintStyle: KType.headline(40).copyWith(fontWeight: FontWeight.w800, color: KColors.faint),
                filled: false,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                border: const UnderlineInputBorder(borderSide: BorderSide(color: KColors.line, width: 2)),
                enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: KColors.line, width: 2)),
                focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: accent, width: 2)),
                errorBorder: const UnderlineInputBorder(borderSide: BorderSide(color: KColors.danger, width: 2)),
                focusedErrorBorder: const UnderlineInputBorder(borderSide: BorderSide(color: KColors.danger, width: 2)),
              ),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Give it a title so you can find it later' : null,
            ),
            if (_baseType == MediaBaseType.anime) ...[
              const SizedBox(height: 14),
              _AniListButton(linkedId: _animeData.aniListId, accent: accent, onPressed: _searchAniList),
            ],
            const SizedBox(height: 32),
            const _SectionLabel(
              'Artwork',
              hint: 'Tap to pick from your photos. Without art, the title is set as a poster.',
            ),
            const SizedBox(height: 14),
            ValueListenableBuilder(
              valueListenable: _titleController,
              builder: (context, value, _) => Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 104,
                    child: _ImagePickerTile(
                      label: 'Poster',
                      aspectRatio: 2 / 3,
                      path: _posterImagePath,
                      title: value.text,
                      baseType: _baseType,
                      onPick: () => _pickImage(isPoster: true),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _ImagePickerTile(
                      label: 'Backdrop',
                      aspectRatio: 16 / 9,
                      path: _coverImagePath,
                      title: null,
                      baseType: _baseType,
                      onPick: () => _pickImage(isPoster: false),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            _SectionLabel(_detailsLabel(_baseType)),
            const SizedBox(height: 14),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              child: KeyedSubtree(key: ValueKey(_baseType), child: _buildTypeFields()),
            ),
          ],
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
        return 'Schedule';
      case MediaBaseType.movie:
        return 'Release';
      case MediaBaseType.anime:
        return 'Schedule';
      case MediaBaseType.music:
        return 'Release';
    }
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label, {this.hint});

  final String label;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: KType.headline(26)),
        if (hint != null) ...[const SizedBox(height: 4), Text(hint!, style: KType.small)],
      ],
    );
  }
}

/// Four large type-set words; the selected one lights up in its category
/// colour. The choice sets the tone for the rest of the form.
class _CategorySelector extends StatelessWidget {
  const _CategorySelector({required this.selected, required this.onChanged});

  final MediaBaseType selected;
  final ValueChanged<MediaBaseType> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: [
        for (final type in MediaBaseType.values)
          Semantics(
            selected: selected == type,
            button: true,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => onChanged(type),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedOpacity(
                      duration: const Duration(milliseconds: 200),
                      opacity: selected == type ? 1 : 0.0,
                      child: Icon(iconForBaseType(type), size: 18, color: accentColorForBaseType(type)),
                    ),
                    const SizedBox(width: 4),
                    AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 200),
                      style: KType.headline(26).copyWith(
                        fontWeight: FontWeight.w800,
                        color: selected == type ? accentColorForBaseType(type) : KColors.faint,
                      ),
                      child: Text(labelForBaseType(type)),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _AniListButton extends StatelessWidget {
  const _AniListButton({required this.linkedId, required this.accent, required this.onPressed});

  final String? linkedId;
  final Color accent;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: accent.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(Icons.travel_explore_rounded, color: accent),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      linkedId == null ? 'Find it on AniList' : 'Linked to AniList #$linkedId',
                      style: KType.title.copyWith(fontSize: 15),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      linkedId == null ? 'Fills in the title, art, and next airing time' : 'Search again to replace',
                      style: KType.small,
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: KColors.muted),
            ],
          ),
        ),
      ),
    );
  }
}

class _ImagePickerTile extends StatelessWidget {
  const _ImagePickerTile({
    required this.label,
    required this.path,
    required this.title,
    required this.baseType,
    required this.onPick,
    required this.aspectRatio,
  });

  final String label;
  final String? path;
  final String? title;
  final MediaBaseType baseType;
  final VoidCallback onPick;
  final double aspectRatio;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Choose $label image',
      child: GestureDetector(
        onTap: onPick,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: aspectRatio,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  MediaPlaceholderArt(
                    baseType: baseType,
                    imagePath: path,
                    title: (title?.trim().isEmpty ?? true) ? null : title,
                    borderRadius: BorderRadius.circular(14),
                    iconSize: 28,
                  ),
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.all(7),
                      decoration: const BoxDecoration(color: KColors.sodium, shape: BoxShape.circle),
                      child: const Icon(Icons.add_photo_alternate_rounded, size: 15, color: KColors.inkDeep),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(label, style: KType.meta.copyWith(color: KColors.text)),
          ],
        ),
      ),
    );
  }
}

/// Segmented single choice rendered as pills.
class _Choice<T> extends StatelessWidget {
  const _Choice({
    required this.values,
    required this.selected,
    required this.label,
    required this.onChanged,
    required this.accent,
  });

  final List<T> values;
  final T? selected;
  final String Function(T) label;
  final ValueChanged<T> onChanged;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final v in values)
          Semantics(
            selected: v == selected,
            button: true,
            child: GestureDetector(
              onTap: () => onChanged(v),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                decoration: BoxDecoration(
                  color: v == selected ? accent : KColors.raised,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  label(v),
                  style: KType.title.copyWith(fontSize: 14, color: v == selected ? KColors.inkDeep : KColors.text),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(text, style: KType.meta),
  );
}

/// Seven day dots, Monday first, for a weekly release slot.
class _WeekdayPicker extends StatelessWidget {
  const _WeekdayPicker({required this.selected, required this.onChanged, required this.accent});

  final int? selected;
  final ValueChanged<int> onChanged;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        for (var d = 1; d <= 7; d++)
          Semantics(
            selected: selected == d,
            button: true,
            label: weekdayNames[d - 1],
            excludeSemantics: true,
            child: GestureDetector(
              onTap: () => onChanged(d),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 42,
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(shape: BoxShape.circle, color: selected == d ? accent : KColors.raised),
                child: Text(
                  weekdayNames[d - 1].substring(0, 2),
                  style: KType.title.copyWith(fontSize: 14, color: selected == d ? KColors.inkDeep : KColors.muted),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

InputDecoration _num(String label) => InputDecoration(labelText: label);

class _TvFields extends StatelessWidget {
  const _TvFields({required this.data, required this.onChanged});

  final TvData data;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final accent = accentColorForBaseType(MediaBaseType.tv);
    final ended = data.status == TvStatus.ended;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _FieldLabel('Status'),
        _Choice<TvStatus>(
          values: TvStatus.values,
          selected: data.status,
          label: tvStatusLabel,
          accent: accent,
          onChanged: (v) {
            data.status = v;
            onChanged();
          },
        ),
        if (!ended) ...[
          const SizedBox(height: 22),
          const _FieldLabel('New episodes every'),
          _WeekdayPicker(
            selected: data.releaseDayOfWeek,
            accent: accent,
            onChanged: (v) {
              data.releaseDayOfWeek = v;
              onChanged();
            },
          ),
        ],
        const SizedBox(height: 22),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                initialValue: data.currentSeason?.toString() ?? '',
                keyboardType: TextInputType.number,
                decoration: _num('Season'),
                onChanged: (v) => data.currentSeason = int.tryParse(v),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextFormField(
                initialValue: data.nextEpisodeNumber?.toString() ?? '',
                keyboardType: TextInputType.number,
                decoration: _num('Next episode'),
                onChanged: (v) {
                  data.nextEpisodeNumber = int.tryParse(v);
                  onChanged();
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextFormField(
                initialValue: data.totalEpisodes?.toString() ?? '',
                keyboardType: TextInputType.number,
                decoration: _num('Episodes'),
                onChanged: (v) {
                  data.totalEpisodes = int.tryParse(v);
                  onChanged();
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        const Text('Already partway through? Set the episode you\'re waiting on.', style: KType.small),
        if (!ended) ...[
          const SizedBox(height: 22),
          _DateTimePickerField(
            label: 'One-off date for the next episode',
            placeholder: 'Follows the weekly slot',
            value: data.nextEpisodeDate,
            includeTime: true,
            accent: accent,
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
          const SizedBox(height: 6),
          const Text('For a delayed or moved episode. Clear it to go back to the weekly slot.', style: KType.small),
        ],
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
          accent: accentColorForBaseType(MediaBaseType.movie),
          onChanged: (dt) {
            data.releaseDate = dt;
            onChanged();
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          initialValue: data.runtimeMinutes?.toString() ?? '',
          keyboardType: TextInputType.number,
          decoration: _num('Runtime in minutes'),
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
    final accent = accentColorForBaseType(MediaBaseType.anime);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _FieldLabel('Format'),
        _Choice<AnimeFormat>(
          values: AnimeFormat.values,
          selected: data.format,
          label: animeFormatLabel,
          accent: accent,
          onChanged: (v) {
            data.format = v;
            onChanged();
          },
        ),
        const SizedBox(height: 22),
        _DateTimePickerField(
          label: 'Next episode airs',
          value: data.nextAiringEpisodeTimestamp,
          includeTime: true,
          accent: accent,
          onChanged: (dt) {
            data.nextAiringEpisodeTimestamp = dt;
            onChanged();
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          initialValue: data.cour?.toString() ?? '',
          keyboardType: TextInputType.number,
          decoration: _num('Cour'),
          onChanged: (v) => data.cour = int.tryParse(v),
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
          accent: accentColorForBaseType(MediaBaseType.music),
          onChanged: (dt) {
            data.releaseDate = dt;
            onChanged();
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          initialValue: data.trackCount?.toString() ?? '',
          keyboardType: TextInputType.number,
          decoration: _num('Number of tracks'),
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
    required this.accent,
    this.placeholder = 'Choose a date',
    this.onClear,
  });

  final String label;
  final String placeholder;
  final DateTime? value;
  final bool includeTime;
  final Color accent;
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
    final v = value;
    return Material(
      color: KColors.raised,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _pick(context),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
          child: Row(
            children: [
              Icon(Icons.event_rounded, color: v == null ? KColors.muted : accent),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: KType.small),
                    const SizedBox(height: 2),
                    Text(
                      v == null ? placeholder : (includeTime ? whenLabel(v) : DateFormat('EEEE d MMMM y').format(v)),
                      style: KType.title.copyWith(fontSize: 15, color: v == null ? KColors.faint : KColors.text),
                    ),
                  ],
                ),
              ),
              if (onClear != null)
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 20),
                  color: KColors.muted,
                  onPressed: onClear,
                  tooltip: 'Clear date',
                ),
            ],
          ),
        ),
      ),
    );
  }
}
