# GSV Poems — Architecture

Android-only Flutter app. Everything lives on the device; network is used only for Drive/email/updates (later slices).

## Folders
```
lib/
  main.dart                 bootstrap (ProviderScope, DB, settings)
  app.dart                  MaterialApp, themes, start flow (splash → PIN → shell)
  core/
    theme/                  6 palettes (Mor default) → ThemeData + GsvColors extension
    l10n/                   gu / hi / en strings, per-screen language override
    widgets/icon3d.dart     3D clay icons (CustomPainter, same art as the design canvas)
    text/                   language detect, word count, transliteration for search
  data/
    db/                     Drift (SQLite): poems, categories, poem_versions, settings
    poem_repository.dart    all poem reads/writes (CRUD, recycle bin, search, stats)
    import/keep_parser.dart Google Takeout Keep JSON → poems ("<number> … ****" rule)
    security/pin_service    PBKDF2-SHA256 PIN hash in Keystore-backed secure storage
  features/
    splash/ pin/ shell/ home/ editor/ reader/ search/ collection/ settings/ help/
test/                       unit tests for parser, transliteration, search, repository
```

## Data model
- **poems:** `id` (UUID, permanent: this is the sync key), `number`, `title`, `body`, `lang` (gu/hi/en), `categoryId`, `isFavorite`, `wordCount`, `searchBlob`, `createdAt`, `updatedAt`, `deletedAt` (null = live; a value = in the recycle bin), `source` (app/keep/docx), `sourceKey` (for import de-duplication).
- **categories:** `id`, `nameGu`, `nameHi`, `nameEn`, `iconKey`, `sortOrder`.
- **poem_versions:** `id`, `poemId`, `title`, `body`, `savedAt`. Each save keeps the previous text.
- **settings:** key/value pairs (theme, language, font size, splash photo path, recent-list cleared-at).

## Rules
- **Delete:** sets `deletedAt` and nothing else. "Delete forever" is the only real delete, and it asks twice.
- **Search:** a query of ≥ 3 characters matches `searchBlob`, which holds the lower-cased title and body plus a Latin transliteration. That makes "prem" find પ્રેમ and प्रेम.
- **Import:** idempotent. `sourceKey` = hash(note id + poem number + first line), so importing the same file twice adds nothing.
- **Sync (later):** merge by `id` with the newer `updatedAt` winning. The losing text goes to `poem_versions`. A delete on another device only moves the poem to the recycle bin here.
- **Secrets:** the PIN hash, and later the recovery key and Gmail app password, are kept only in `flutter_secure_storage`, never in the DB or in backups in plain text.

## Slices
1. **Foundation (this slice):** themes, icons, translations, DB, splash, PIN, write, read, collection, recycle bin, search, settings basics.
2. Panchang and Choghadiya (offline astronomy) and festival notifications.
3. Encrypted backup (AES-256-GCM), restore, 11:59 PM schedule, WhatsApp/email/Drive, recovery key.
4. Google Keep Takeout import, then importing the 900 poems.
5. Two-device Drive sync, GitHub Releases "Update Now", help guide, polish, release.
