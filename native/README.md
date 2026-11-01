# EST native app (Android / iOS) — Capacitor shell

One code base: the website at the repository root **is** the app. This folder
wraps it in a native shell so it can be published on Google Play and the App
Store, with native permissions, file saving/sharing and a proper app icon.

```
native/
├─ capacitor.config.ts   app id, name, splash/status-bar settings
├─ package.json          Capacitor + plugins, build scripts
├─ scripts/build-www.mjs copies app.html → www/index.html (+ signin, dashboard, assets)
├─ bridge/native-bridge.js  runs only inside the shell: permissions, blob → share sheet,
│                           external links → system browser, back button, splash/status bar
├─ assets/               icon-only.png, icon-foreground.png, icon-background.png, splash*.png
├─ android/              generated Android Studio project (committed; builds are not)
└─ ios/                  generated on a Mac with `npx cap add ios` (not committed here)
```

**App id: `in.est.surveillance`** — permanent once uploaded to a store. Change it
in `capacitor.config.ts` *before* the first upload if you prefer another.

## Build on your own machine

Requirements: Node 20+, Java 21, Android Studio (SDK 35). For iOS: a Mac with Xcode 16 + CocoaPods.

```bash
cd native
npm ci                     # first time: npm install
npm run sync:android       # build www/ from the root pages, copy into android/
npm run assets             # icons + splash from assets/ (once, or when the icon changes)
npm run open:android       # opens Android Studio → Run on a device / emulator
```

Signed Play bundle (`.aab`), locally:

```bash
# once: create the upload keystore and KEEP IT SAFE (a lost keystore = new app listing)
keytool -genkeypair -v -keystore est-upload.jks -alias est -keyalg RSA -keysize 2048 -validity 10000
export EST_KEYSTORE_FILE=$PWD/est-upload.jks EST_KEYSTORE_PASSWORD=… EST_KEY_ALIAS=est EST_KEY_PASSWORD=…
npm run android:bundle     # → android/app/build/outputs/bundle/release/app-release.aab
```

## Build in GitHub Actions (no Android Studio needed)

`.github/workflows/android-build.yml`:
- every push to `main` that changes the web app or `native/` → **debug APK** artifact
  (install on test phones; the Actions page → run → Artifacts → `EST-debug-apk`)
- push a tag `v2.10.0` (or run the workflow manually with `release`) → **signed .aab**
  artifact ready to upload to Play Console.

Add these repository secrets once: `ANDROID_KEYSTORE_BASE64`
(`base64 -w0 est-upload.jks`), `ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_ALIAS`,
`ANDROID_KEY_PASSWORD`.

## iOS

Needs macOS. On the Mac:

```bash
cd native && npm ci && npm run build:www
npx cap add ios && npx cap sync ios && npm run assets
npx cap open ios          # Xcode: set Team (Apple Developer account), then Product → Archive
```

Then App Store Connect → TestFlight → submit. Apple asks for the privacy policy
URL (`PRIVACY.md` published on the website), the account-deletion path (in the
app: Home → *Delete my account*) and location-usage text (already in Info.plist
after `cap add ios`: edit `NSLocationWhenInUseUsageDescription` to
"EST records the GPS position of each survey point").

## What differs inside the shell (handled by the bridge)

| On the website | In the app |
|---|---|
| Browser download of XLSX/PDF/PNG | Saved to the app cache and offered via the **share sheet** (Files, Drive, WhatsApp, Gmail…) |
| `window.open(https://…)` | Opens in the system browser |
| Service worker caching | Not registered — the store update replaces the files |
| Location permission on first GPS use | Requested once at start |
| Android back button closes the app | Steps back inside the app; closes modals first |

Supabase works unchanged (origin `https://localhost`). Password-recovery uses
one-time codes, so no deep-link/redirect URL is needed in the app.

## Store checklist (Phase 2b)

Privacy policy URL · Data-safety form (location, health-surveillance data,
account info; data encrypted in transit; deletion available in-app) · 512 px icon,
feature graphic 1024×500, 4–8 phone screenshots · content rating · internal
testing track with ≥12 testers for 14 days (personal developer accounts) ·
in-app purchases through Play Billing / Apple IAP only (Phase 3) — Razorpay
stays web-only.
