# Keep Up

Offline-first Flutter app for tracking TV, movies, anime, and music, with live
countdowns to next release.

## Stack

- **Flutter** + **Riverpod** (state) + **Material 3** (dark theme, `#0f0f13`)
- **Isar** — local database, polymorphic `MediaItem` schema (embedded
  `TvData` / `AnimeData` / `MovieData` / `MusicData` per `baseType`)
- **AniList GraphQL API** — search + autofill for anime entries
- `image_picker`, `slide_countdown`, `intl`, `path_provider`

## Features

- Dashboard: horizontally scrolling "Dropping Soon" carousel (live countdown
  ticker for anything releasing within 24h) + a "Tracking" grid with
  days-remaining pills for everything further out
- Add/edit any of the 4 media types, with local poster/cover image picking
- Anime entries can be populated straight from an AniList search
- Search + category filter chips on the dashboard
- Delete with confirmation
- Hero transitions from grid/carousel into the detail view

## Project layout

```
lib/
  models/       Isar schema (media_item.dart)
  providers/    Riverpod providers — Isar instance, CRUD, countdown logic
  services/     Isar bootstrap, AniList client, image persistence
  screens/      Dashboard, detail, add/edit, AniList search sheet
  widgets/      Reusable UI pieces (cards, grid tiles, pills, placeholder art)
  data/         Mock seed data (3 items per category, first-launch only)
```

## Running

```
flutter pub get
flutter run              # picks a connected device
flutter run -d linux      # desktop
flutter run -d chrome     # web
```

## Codegen

The Isar schema is generated code. After editing `lib/models/media_item.dart`:

```
dart run build_runner build --delete-conflicting-outputs
```

## Tests

```
flutter test
```

Covers the countdown logic (`nextWeekdayOccurrence`, per-type
`nextReleaseDateProvider` dispatch) and an app-boot smoke test.

## Notes

- `flutter_riverpod` is pinned to the 3.x line; `StateProvider` comes from
  `package:flutter_riverpod/legacy.dart`.
- `isar`/`isar_generator` are pinned to 3.1.x (last version before the
  package went unmaintained) — kept deliberately over the `isar_community`
  fork for stability; see `lib/providers/isar_provider.dart`.
- App icon is generated via `flutter_launcher_icons` (Android/iOS/macOS/
  Windows/Web) from `assets/icon/`; Linux desktop icon isn't covered by that
  tool and still uses the Flutter default.
