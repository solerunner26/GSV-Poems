# GSV Poems — Product Brief (v1)

Status: **draft v2, waiting for approval** · Last updated 2026-11-07

## 1. Problem and user

Shri GSV writes poems in **Gujarati and Hindi**. About 900 poems currently sit in Google Keep. He needs one simple, private, beautiful Android app to **write, find, read, share and safely keep** all of them, on two devices:

| Device | Type | Screen |
| --- | --- | --- |
| Nothing Phone (3a) Pro | Phone | ~6.8", portrait |
| Samsung Galaxy Tab S7 | Tablet | 11", portrait and landscape |

He is not tech-savvy, so every screen must be obvious, use large text, and never lose his work.

## 2. Guiding principles

1. **Offline first.** Writing, search, reading, calendar and local backup all work with no internet. Internet is used only when needed (Drive upload, email, sync, updates) and those jobs wait quietly until a connection exists.
2. **Nothing is ever lost.** Auto-save while typing, edit history, a recycle bin, daily encrypted backups, and sync that never deletes or duplicates.
3. **Simple over clever.** One clear action per screen, labels next to icons, large touch targets (≥ 48 dp), the help topic for each screen one tap away.
4. **Private.** PIN lock, encrypted backups, no analytics, no ads, no third-party servers.

## 3. MVP scope (user stories + acceptance criteria)

### A. Start-up and security
- **A1 Splash.** Shows the logo, the poet's photo (changeable in Settings) and the name, with an "Enter / પ્રવેશ" button.
  - AC: the photo can be replaced from Settings; a default photo is bundled.
- **A2 PIN lock.** A 4-digit PIN is required every time the app opens or returns after 2 minutes in the background. Fingerprint unlock is optional.
  - AC: PIN is never stored in plain text (salted hash in Android Keystore-backed secure storage). After 5 wrong tries there is a 30-second wait.
  - AC: "Forgot PIN" works with the recovery key.
- **A3 Recovery key.** Created at first setup and shown as 24 easy words plus a QR code to print.
  - Second way to get it back: a one-time email of the recovery key to the configured address, sent separately from backups. It can be re-sent from Settings, but only after the PIN is entered.

### B. Writing
- **B1 Editor.** Large Gujarati/Hindi text area. Works with Gujarati Gboard, Hindi Gboard and Alaya keyboards. A mic button dictates straight into the poem using Android speech recognition (gu-IN / hi-IN / en-IN).
  - AC: auto-save every few seconds and on leaving the screen. Live word count. Undo.
- **B2 Save.** Title (optional; the first line is used by default), language (auto-detected: Gujarati / Hindi / English), category (with icon), favourite toggle, date.
- **B3 Categories.** Default set with icons, for example ભક્તિ (devotion), પ્રેમ (love), પ્રકૃતિ (nature), દેશ (nation), જીવન (life), પરિવાર (family), હાસ્ય (humour), ગઝલ (ghazal), ભજન (bhajan), and others. He can add, rename or re-icon categories.
- **B4 Edit history.** Each save keeps the earlier version, and any version can be restored.

### C. Collection, recycle bin
- **C1 Collection.** Every poem, grouped or filtered by category and language (Gujarati / Hindi), sortable by date, title or number.
- **C2 Edit / update / delete.** A deleted poem goes to the **Recycle bin**. The **Restore** button brings it back. "Delete forever" asks twice. Items are purged after 90 days only if he enables that (off by default).

### D. Search
- **D1** Typing **any 3 characters** lists every poem containing them, in Gujarati, Hindi or English. Results update as he types, with the match highlighted.
- **D2 Cross-script search.** Typing "prem" in English letters also finds પ્રેમ and प्रेम (through transliteration).
- **D3** Tapping a result opens the poem in reading mode.

### E. Reading experience
- Large adjustable font size (pinch or A−/A+), choice of beautiful Gujarati/Devanagari fonts, line spacing.
- Paper / night look matching the theme, and an optional decorative border.
- Swipe left or right to move to the next or previous poem.
- **Read aloud** (Android text-to-speech, Gujarati/Hindi where the device supports it).
- Keep the screen awake while reading.

### F. Home screen (top to bottom)
1. **Today:** Gujarati date (Vikram Samvat, month, paksha, tithi), Hindu weekday, English date, and the **current Choghadiya** (name, good/bad, ends at …).
2. **Alert strip:** "Tomorrow is Diwali", "Tomorrow is Ekadashi", "Today is Purnima", etc.
3. **Upcoming festivals and vrat days:** next festivals plus **Purnima, Ekadashi, and Sankashti/Ganesh Chaturthi** dates.
4. **Recent entries (last 7 days):** poems written or edited in the past 7 days, with a "Clear list" action that only hides them here and never deletes poems. *(Confirmed.)*
5. **Favourite poems:** a single horizontal row.
6. **Stats and language filter:** total poems, total words, and a Gujarati / Hindi toggle that shows each language's poems in its own section.
7. **On this day:** poems written on this date in earlier years. **Poem of the day.**

### G. Panchang calendar (full)
- Month view for the **whole year** (not only Jan–Mar): each day shows the English date, tithi and festival markers.
- Day detail: tithi, nakshatra, yoga, karana, vaar, paksha, Gujarati month (amanta, Vikram Samvat), sunrise and sunset, and the full **Choghadiya** table for day and night.
- Computed **on the device** with astronomical formulas (Lahiri ayanamsa), so it is offline and works for any year.
- **Location:** the phone's GPS is read once at setup and saved, so it works offline afterwards. It can be refreshed or set to a city by hand in Settings. If location is denied, Ahmedabad is used.
- Notifications the evening before important days (Ekadashi, Purnima, Sankashti, major festivals), each type switchable on or off.

### H. Backup, restore, sync
- **H1 Backup file:** one compact `.gsvbak` file holding JSON of all poems, categories, history, recycle bin and settings, compressed and then **encrypted with AES-256-GCM** using a key derived from the recovery key. It cannot be read without the key.
- **H2 When:** automatically every night at **11:59 PM** (exact alarm), plus a **"Backup now"** button. If the phone was off at 11:59, the backup runs the next time the app opens.
- **H3 Where:**
  - On the phone: the last 7 backups.
  - **Google Drive:** automatic upload when online.
  - **Email:** automatic, sent with a Gmail app password set once in Settings after each new install.
  - **WhatsApp:** one tap on "Send backup to WhatsApp" opens WhatsApp with the file attached.
- **H4 Restore:** "Restore from file" accepts a backup picked from WhatsApp downloads, email, Drive or any folder, then asks for the recovery key. A fresh install offers "Restore from backup" during first setup.
- **H5 Multi-device sync (Drive):** each device uploads its backup to the same Drive folder. On open and before each backup, the app downloads the other device's latest file and **merges poem by poem**:
  - Every poem has a permanent unique ID, so the same poem on two devices is never duplicated.
  - Same poem edited on both devices: the newer edit wins, and the older text is kept in edit history, never dropped.
  - A poem deleted on one device goes to the other device's recycle bin. Sync never permanently deletes.
  - Restore also merges instead of overwriting, unless he explicitly chooses "Replace everything".

### I. Sharing
- Share a poem to WhatsApp or any app as **plain text** (with the poet's name), or as a **designed image card** (themed background, logo, name).

### J. Import of the existing 900 poems
- Import the **Google Takeout Keep JSON** files.
- Parsing rule: a poem **starts with a number** and **ends with `****`**. One note may hold several poems.
- Keep the poem number, original date, labels (mapped to categories), and detect the language.
- A preview screen lists "found N poems, M problems" before anything is saved, so you check the count before it goes into the app. Duplicate-safe if imported twice.
- DOCX import as a fallback, using the same rule.

### K. Languages, themes, help
- **UI languages:** Gujarati, Hindi, English, all fully translated. While a poem is being viewed or edited, the UI switches to that poem's language automatically, and switches back afterwards.
- **Themes:**
  - Light and Night.
  - **Kesar** (saffron paper, maroon ink, from the logo).
  - **Kamal** (lotus pink and gold).
  - **Neel** (deep indigo night sky with gold).
  - **Van** (soft green leaf and parchment).

  Each theme has its own subtle ornament (border, motif, texture) and a matching poem-card style.
- **Help:** a "?" on every screen opens the help for that screen, with pictures and short steps in his language. A full in-app user guide, plus an optional first-run tour.

### L. App updates
- When online, the app checks the public `GSV-Poems-Releases` repo on start. If a newer version exists, it shows **"Update Now"**, which downloads the signed APK and opens Android's installer. All data stays.
- I build every update; nothing is released until you approve the push.

### M. Layout
- **Bottom bar**, left to right on screen: **Settings · Search · [HOME, raised centre] · Write · Collection**, so read right to left it is Collection, Write, Home, Search, Settings. Home is truly centred and writing a new poem is one tap away. *(Decided 2026-11-07.)*
- **Adaptive:** phone gets a single column. Tablet gets two panes (list + poem side by side) and a wider calendar, and works in landscape.

## 4. Out of scope for v1
- Publishing to the kavigsv.com website.
- iPhone / iOS.
- Google Play Store listing (the app is installed directly from GitHub Releases).
- Any cloud server or paid storage.

## 5. Data the app holds
| Data | Where | Why |
| --- | --- | --- |
| Poems, categories, history | On device (SQLite) | Core purpose |
| PIN hash, recovery-key wrap, Gmail app password, Drive token | Android Keystore-backed secure storage | Security and backup |
| Encrypted backups | Device, his Google Drive, his email, WhatsApp (when he sends) | Safety |
| Poet photo | On device | Splash screen |

No analytics, no tracking, no data sent anywhere except his own Drive and email.

## 6. Non-functional needs
- Opens to the PIN screen in under 2 s. Search results in under 150 ms for 5,000 poems.
- Accessibility: large text by default, contrast ≥ 4.5:1 in every theme, TalkBack labels on every control, no text overlap at 200% font scale.
- Works on Android 10+ (both devices run Android 13–15).

## 7. Risks and open questions
| Risk | Plan |
| --- | --- |
| Panchang accuracy (tithi times must match printed Gujarati panchang) | Implement standard astronomical algorithms and check 30+ dates against a published panchang before release |
| Offline Gujarati voice typing depends on Google's speech pack | Online works everywhere. For offline, we show how to download the Gujarati speech pack once |
| Exact 11:59 PM alarm can be delayed by battery saver (Samsung) | Ask once to exclude the app from battery optimisation. Run any missed backup on next open |
| Drive access needs a free Google Cloud OAuth client (no card) | I'll guide you step by step; you create it |
| Losing the recovery key and access to email = backups unreadable | Printed key + emailed key; warn clearly at setup |
| Auto-update needs the APK downloadable without a password | Source stays in private `GSV-Poems`. Signed APKs only are published to a separate **public** repo `GSV-Poems-Releases` (no poems or secrets in either). |

## 8. Proposed stack (Phase 2)

| Need | Choice | Cost / catch |
| --- | --- | --- |
| App framework | **Flutter 3.47 / Dart 3.13** (already installed), Android only | Free, open source |
| Local database + search | **Drift (SQLite)** with an FTS5 *trigram* index, which gives the "any 3 letters" search across all scripts, plus a transliterated shadow column for cross-script search | Free |
| State and navigation | Riverpod · go_router | Free |
| Translations | Flutter `gen-l10n` (gu / hi / en ARB files) | Free |
| Fonts (bundled, offline) | Noto Serif/Sans Gujarati, Noto Serif Devanagari, Hind Vadodara, Mukta Vaani, Tiro Devanagari Hindi (all SIL OFL) | Free |
| Encryption | `cryptography` (AES-256-GCM, Argon2id key derivation) · `flutter_secure_storage` (Keystore) · `local_auth` (fingerprint) | Free |
| Voice typing | `speech_to_text` (Android SpeechRecognizer) + the Gboard mic | Free. Offline needs the Gujarati speech pack |
| Read aloud | `flutter_tts` | Free |
| Nightly backup | `android_alarm_manager_plus` (exact 11:59 PM) + `workmanager` (retry uploads when online) | Free |
| Google Drive | `google_sign_in` + `googleapis` (Drive v3, app folder) | Free. Needs a free Google Cloud OAuth client: you create it, I guide you, no card needed |
| Email backup | `mailer` (Gmail SMTP + app password) | Free (Gmail limit of about 500 emails a day) |
| Share / WhatsApp | `share_plus` · image cards rendered in-app | Free |
| Panchang | Own Dart module (sun/moon positions after Meeus, Lahiri ayanamsa, sunrise, choghadiya) · `geolocator` for one-time location | Free |
| Notifications | `flutter_local_notifications` | Free |
| Updates | GitHub Releases API on public `GSV-Poems-Releases` · `open_filex` / install intent | Free |
| CI | GitHub Actions builds the signed APK on a version tag. The keystore is stored as a GitHub secret, never in the repo | Free |

Alternative considered: native Kotlin + Compose. It is equally good on Android but slower to build all of this, so Flutter is recommended.
