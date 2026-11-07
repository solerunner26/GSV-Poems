# GSV Poems · કાવ્ય સંગ્રહ

An Android app (phone and tablet) for writing, finding, reading and safely keeping Shri GSV's Gujarati and Hindi poems. It works fully offline and keeps everything on the device.

- **Spec:** [BRIEF.md](BRIEF.md)
- **Design:** [DESIGN.md](DESIGN.md)
- **Code layout:** [ARCHITECTURE.md](ARCHITECTURE.md)
- **Icon render prompts:** [ICON_PROMPTS.md](ICON_PROMPTS.md)

## Status
**Slice 1 (foundation) is done:**
- Splash, 4-digit PIN (plus optional fingerprint), and the 5-button bottom bar with a raised Home
- Write with auto-save, voice typing and edit history
- Reading mode with text size, read-aloud, favourite and share
- Search that finds any 3 letters across Gujarati, Hindi and English letters
- Collection by category, and a recycle bin with restore
- Six themes, a gu/hi/en interface and an in-app help guide
- **Google Keep import** (Settings → Import from Google Keep). Each note's title becomes a collection, and the same title in Gujarati and Hindi is one collection. The importer reads the contents list at the top of each note, splits poems at their numbered titles and at separator lines (`****`, `++++`, `####`, `:::`), and keeps the date written under a poem. Importing twice never duplicates. Tested on the full export: 888 entries, which are 887 unique poems (one appears twice) in 18 collections.

**Coming next:**
- Panchang and Choghadiya
- Encrypted backup (WhatsApp, email, Drive) and restore
- Two-device sync
- "Update Now"

## Develop
Requirements: Flutter 3.47+, Android SDK 36, and Android licences accepted (`flutter doctor --android-licenses`).

```bash
flutter pub get
```

```bash
dart run build_runner build --delete-conflicting-outputs
```

```bash
flutter test
```

```bash
flutter run
```

## Checking a Keep export without importing
```bash
dart run tool/keep_dry_run.dart "path/to/folder/with/json"
```

## Privacy rules for this repo
- **Never commit:** poems, backups (`*.gsvbak`), Google Takeout exports (`private/`, `takeout/`), keystores or passwords. `.gitignore` already blocks them.
- **On the phone:** the PIN is stored only as a salted PBKDF2 hash in Android's Keystore-backed storage.

## Fonts
Noto Serif Gujarati, Hind Vadodara, Hind and Tiro Devanagari Hindi are bundled under the SIL Open Font License (`assets/fonts/OFL.txt`).
