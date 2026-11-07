# Google Drive setup (one time, about 10 minutes)

The app needs a free Google Cloud "OAuth client" so it may put its backup folder in your father's Google Drive. No card and no billing are needed. Do this on a computer, signed in to any Google account. Your own account is fine; your father's Google account is the one he will connect later in the app.

## 1. Create the project
1. Open https://console.cloud.google.com/ and accept the terms if asked.
2. Click the project picker at the top, then **New project**, name it `GSV Poems`, and click **Create**. Make sure the new project is selected.

## 2. Turn on the Drive API
3. Go to **APIs & Services → Library**, search for **Google Drive API**, and click **Enable**.

## 3. Consent screen (what you see when connecting)
4. Go to **APIs & Services → OAuth consent screen** (or **Google Auth Platform → Branding**).
5. Fill in the basics:
   - **User type:** External
   - **App name:** `GSV Poems`
   - **Support email:** yours
   - **Developer contact:** yours
6. Under **Data access / Scopes**, add `.../auth/drive.file` ("See, edit, create and delete only the specific Google Drive files you use with this app").
   - This is the narrowest Drive permission: the app only sees the files it creates, never the rest of the Drive.
7. Under **Audience**, click **Publish app → In production**.
   - Because `drive.file` is a non-sensitive scope, Google does not need to review it.
   - If you leave it in **Testing**, add your father's Gmail under **Test users**. In Testing, Google asks for permission again every 7 days, which is why production is better.

## 4. Two client IDs
8. Go to **APIs & Services → Credentials → Create credentials → OAuth client ID**.
9. **Android client.** Choose **Android** and enter:
   - **Package name:** `com.gsvpoems.gsv_poems`
   - **SHA-1 certificate fingerprint:** `74:9D:C7:12:D9:4D:55:DF:20:9B:3E:D8:67:42:3F:E5:DA:CD:CB:CD`

   Then click **Create**. You do not need to copy anything from it.
10. **Web client.** Create a second one, this time choosing **Web application**, name it `GSV Poems web`, and click **Create**.
11. **Copy the Web client's "Client ID".** It looks like `1234567890-abc…apps.googleusercontent.com`.
    - Do **not** copy the client secret; the app never needs it.
    - The client ID is not a secret.

## 5. Put the Web client ID in the app
12. **Paste it into the app:** on the phone, go to **Settings → Google Drive અને બે ઉપકરણ → Google Cloud સેટઅપ** (Google Cloud setup), paste the ID into **Web client ID**, and tap **Save**.
    - Or send it to me and I'll build it into the next update, so neither device needs it typed.

## 6. Connect both devices
13. **First device (the phone with the poems):** tap **Google Drive જોડો** (Connect Google Drive), pick your father's Google account, and allow access. The phone uploads its backup to the Drive folder **GSV Poems Backups**.
14. **Second device (the tablet):** do the same with the **same Google account**. The tablet asks once for the **recovery key of the first phone**. Type it in, and from then on both devices use that one key and stay in sync.

## How syncing behaves
- **When:** both devices sync when the app opens, about 20 seconds after a poem is saved, and at night.
- **Matching:** poems are matched one by one. The newer edit wins, and the older text stays in that poem's edit history.
- **Deletes:** a delete only moves the poem to the other device's recycle bin, so nothing is erased by syncing.
- **On Drive:** each device keeps its latest backup there, plus one copy per day for the last 14 days. All of them are encrypted, so they cannot be read without the recovery key.
