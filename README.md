# GSV Poems · કાવ્ય સંગ્રહ

An Android app (phone and tablet) for writing, finding, reading and safely keeping the Gujarati and Hindi poems of ગીગાભાઈ સનાભાઈ વાળા "ગૌરવ". It works fully offline and keeps everything on the device.

- **Spec:** [BRIEF.md](BRIEF.md)
- **Design:** [DESIGN.md](DESIGN.md)
- **Code layout:** [ARCHITECTURE.md](ARCHITECTURE.md)
- **Icon render prompts:** [ICON_PROMPTS.md](ICON_PROMPTS.md)

## Status — v1.3.0-beta.1 (build 5)
- **Foundation:**
  - Splash, 4-digit PIN (plus optional fingerprint), and the 5-button bottom bar with a raised Home
  - Write with auto-save, voice typing and edit history
  - Reading mode with text size, read-aloud, favourite and share
  - Search for any 3 letters across Gujarati, Hindi and English letters
  - Recycle bin with restore
  - Six themes, a gu/hi/en interface and help
- **All 890 poems come with the app** (`assets/poems/seed.json`): 801 Gujarati and 89 Hindi, in 20 collections. They fill the collections on first launch. A later version can add new poems the same way without touching existing ones.
- **Clean poems:** each poem keeps only its title and stanzas. Contents lists, numbers, separator lines (`****`, `++++`, `####`, `:::`), "સમાપ્ત" and date/place lines are removed. The written date becomes the poem's date, and the app keeps each poem's number.
- **Collections:**
  - named after each note's title; notes with number ranges ("૧ થી ૧૮", "૧૯ થી ૩૬") join one collection
  - the Collection tab has **ગુજરાતી / हिन्दी** sections, so each shows only its own poems, with names in that script
  - uncategorised poems go to **અન્ય / अन्य / Others**
- **Duplicates:**
  - found by text, ignoring spacing, commas and line breaks
  - shown on Home and in Settings → "એકસરખી કવિતા" (duplicate poems)
  - removed only when asked, and the extras go to the recycle bin
  - the editor warns when typed or pasted text is already in the collection
- **Panchang and Choghadiya**, worked out on the phone with no internet:
  - Sun and Moon positions from Meeus' *Astronomical Algorithms*, with Lahiri ayanamsa.
  - **Today card on Home:**
    - Gujarati date (month, paksha, tithi), Vikram Samvat and nakshatra
    - the Choghadiya running now, whether it is good, and when it ends
  - **Festival strip:** a "Tomorrow is …" / "Today is …" notice on Home.
  - **Upcoming list:** festivals and vrat days, including Ekadashi, Purnima, Amavasya and Sankashti Chaturthi.
  - **Panchang screen:**
    - month calendar with tithi and festival dots
    - day details: tithi and nakshatra with end times, yoga, karana, sunrise and sunset
    - day and night Choghadiya
  - **Calendar rules:**
    - Gujarati amanta months, with Adhik month detection
    - Vikram Samvat changes at Kartik sud 1
    - festivals use the right moment of the day: sunrise, Diwali/Holi at sunset, Ganesh Chaturthi at madhyahna, Dussehra in the afternoon, Shivratri/Janmashtami at midnight
    - a skipped tithi is kept on the day it begins
  - **Place:** phone GPS once, or a city list (Gujarat cities, Mumbai, Delhi, Auckland). The default is Ahmedabad.
  - **Checked against published sources:**
    - 5 eclipse times, to within 12 minutes
    - Ahmedabad sunrise and sunset
    - 11 festival dates in 2026–27, all matching Drik Panchang and others
- **Backup and restore:**
  - **Encrypted file:** an encrypted `.gsvbak` file (gzip + AES-256-GCM) with a key made from a 25-character **recovery key** (PBKDF2-SHA256, 120,000 rounds). The recovery key is shown once at first launch, to write down, print or email.
  - **When:** automatically **every night at 11:59 PM**, even with the app closed (exact alarm when Android allows it, otherwise within a few minutes). A missed night is backed up the next time the app opens. **Back up now** works any time.
  - **Where:**
    - the last 7 backups stay on the phone
    - **Send to WhatsApp** takes one tap
    - **Gmail** emails the backup automatically every night (app password, set once in Settings)
  - **Restore:** from any `.gsvbak` file (WhatsApp, email, phone). It merges poem by poem: matched by id, bundled-poem key or text, the newer edit wins, the older text goes to history, and nothing is duplicated or erased. A safety backup is taken first. "Replace everything" asks twice.
  - **Forgot PIN:** resets with the recovery key.
- **Festival reminders:** a notification at 7 PM the evening before festivals and vrat days.
- **Updates:** on every open, the app checks this repo's GitHub Releases and offers **Update Now**: download, then Android's installer, with all poems kept.

**Coming next:**
- Google Drive backup and two-device sync (needs a Google Cloud sign-in setup, done together)

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

## Rebuilding the bundled poems from a Keep export
```bash
dart run tool/build_seed.dart "path/to/folder/with/json"
```

To check an export without changing anything:

```bash
dart run tool/keep_dry_run.dart "path/to/folder/with/json"
```

## Releasing an update
1. Raise `version:` in `pubspec.yaml`. The number after `+` must go up, for example `1.1.0-beta.2+3`.
2. Build the APK:
   ```bash
   flutter build apk --release
   ```
3. Create a GitHub release with the APK named `gsv-poems-v<version>-build<N>.apk`. Phones see it the next time the app opens.

The release signing key is `%USERPROFILE%\.gsvpoems\gsv-poems-release.jks`, and its passwords are in `android/key.properties`. Neither is in git. **Back up both files.** Without them, future updates cannot install over the app.

## Privacy rules for this repo
- **Never commit:** backups (`*.gsvbak`), keystores or passwords. `.gitignore` blocks them.
- **Public by the owner's choice:** the poems in `assets/poems/seed.json`.
- **On the phone:** the PIN is stored only as a salted PBKDF2 hash in Android's Keystore-backed storage.

## Fonts
Noto Serif Gujarati, Hind Vadodara, Hind and Tiro Devanagari Hindi are bundled under the SIL Open Font License (`assets/fonts/OFL.txt`).
