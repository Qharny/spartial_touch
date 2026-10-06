# Releasing SpatialTouch

Package ID: `kabuteyy.spartial_touch`. Version comes from `version:` in `pubspec.yaml`
(`1.0.0+1` → versionName `1.0.0`, versionCode `1`). Keep `kAppVersion` in
`lib/core/app_info.dart` in step with it.

## 1. Create the upload keystore (once)

```bash
keytool -genkey -v -keystore ~/spatialtouch-upload.jks \
  -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

Back the keystore and its passwords up somewhere safe. If you lose them you can't
publish updates (unless you use Play App Signing, which is recommended).

## 2. Point the build at it

Create `android/key.properties`. It's git-ignored, so never commit it:

```properties
storePassword=<store password>
keyPassword=<key password>
keyAlias=upload
storeFile=/home/<you>/spatialtouch-upload.jks
```

`android/app/build.gradle.kts` signs release builds with this file when it exists
and falls back to the debug key when it doesn't. A debug-signed build is fine for
local testing, but the Play Console rejects it.

## 3. Build

```bash
flutter test
(cd android && ./gradlew :app:testDebugUnitTest)
flutter build appbundle --release   # upload build/app/outputs/bundle/release/app-release.aab
```

## 4. Play Console declarations

SpatialTouch uses several permissions that Google reviews by hand. Prepare these
before submitting:

| Item | What to provide |
|---|---|
| **Accessibility API** | Accessibility declaration form. Core purpose: performing taps, swipes, scrolls and Back/Home on the user's behalf when they make a hand gesture, for touch-free control. The app is not an accessibility tool for disabilities, so declare it as such and don't claim otherwise. A short video of a gesture driving an app helps. |
| **Prominent disclosure** | Onboarding's Accessibility step explains what the service does *before* sending the user to system settings. Keep that copy accurate. |
| **Usage access (`PACKAGE_USAGE_STATS`)** | Permissions declaration: used only to know which app is in the foreground so per-app gesture profiles apply. |
| **Foreground service: camera** | Foreground service declaration for type `camera`: continuous hand-gesture detection the user starts from the app, with a visible notification while running. Include a demo video. |
| **Camera / data safety** | Data safety form: no data collected or shared. Camera frames are processed on-device in memory and never stored or transmitted. |
| **Display over other apps** | Optional status overlay. No declaration needed, but mention it in the listing. |
| **Privacy policy URL** | Host `docs/PRIVACY_POLICY.md` (e.g. GitHub Pages) and paste the URL in the Console and the README. |

## 5. Before each release

- Test on a real device: gestures at 30–80 cm in good and poor light, each
  performance preset, active hours across the window edges, reboot → resume
  notification, and recording plus using a custom gesture.
- Update the store screenshots if the UI changed.
