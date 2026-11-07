# GSV Poems — Privacy Policy

*Last updated: 7 November 2026*

GSV Poems is a personal Android app for writing, reading and keeping the poems of ગીગાભાઈ સનાભાઈ વાળા "ગૌરવ". It is made for one family. It has no accounts, no advertising and no analytics.

## What the app stores
- **Poems and edit history, collections, and app settings** (theme, language, Panchang place): stored only on the phone or tablet, in the app's private storage.
- **4-digit PIN:** stored only as a salted hash, in Android's secure storage. The PIN itself is never saved.
- **Recovery key and Gmail app password** (if email backup is turned on): stored only in Android's secure storage on the device.
- **Location:** read once, coarse, only if you choose "Use my location". It is used only to work out sunrise and Panchang times on the phone, and it is never sent anywhere.

## What leaves the device, and only when you set it up
- **Google Drive** (only if you tap "Connect Google Drive"):
  - The app uses Google's `drive.file` permission. It can see and change **only the files it creates itself**: a folder named "GSV Poems Backups" with encrypted backup files. It cannot see any other file in your Drive.
  - The backups are encrypted (AES-256) with your recovery key before they leave the device. Nobody, including Google, can read the poems without that key.
- **Email backup** (only if you enter a Gmail address and app password): the app sends the encrypted backup from your own Gmail account to the address you choose.
- **WhatsApp or other apps:** only when you tap Share, using Android's normal share screen.
- **App updates:** the app asks GitHub (github.com) whether a newer version exists. No personal data is sent.

## What the app never does
- **No selling or sharing:** it does not sell, share or send your data to the developer or to any third party.
- **No tracking or ads:** it contains no advertising, tracking or analytics.

## Removing your data
- **On the device:** uninstalling the app removes everything it stored there.
- **On Google Drive:** delete the "GSV Poems Backups" folder.
- **Drive access:** remove it at https://myaccount.google.com/permissions.

## Contact
Questions: open an issue at https://github.com/solerunner26/GSV-Poems/issues.

---

**ગુજરાતીમાં ટૂંકમાં:** કવિતા અને સેટિંગ ફક્ત ફોનમાં રહે છે.
- **Google Drive:** જોડશો તો એપ ફક્ત પોતે બનાવેલું "GSV Poems Backups" ફોલ્ડર જ જોઈ શકે છે.
- **તાળાબંધ બેકઅપ:** બેકઅપ Recovery key વગર કોઈ ખોલી શકતું નથી.
- **કોઈ જાહેરાત કે ટ્રેકિંગ નથી.** કોઈ માહિતી બીજા કોઈને મોકલાતી નથી.
