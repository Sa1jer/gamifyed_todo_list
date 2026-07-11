# Android Release Checklist

Audit date: 2026-07-02

This document records the current Android release environment. It does not
publish the app, create signing credentials, or authorize changing the
application ID.

## Current Toolchain

| Component | Detected value | Status |
| --- | --- | --- |
| Flutter | `3.44.3` stable, revision `e1fd963c6f` | Ready |
| Dart / DevTools | `3.12.2` / `2.57.0` | Ready |
| Android SDK | `36.1`, platform/build-tools `36.1.0` | Ready; licenses accepted |
| Java | Android Studio JBR OpenJDK `21.0.10` | Ready |
| Gradle wrapper | `8.14` | Ready |
| Android Gradle Plugin | `8.11.1` | Ready |
| Kotlin Gradle Plugin | `2.2.20` | Works with deferred migration warning |
| Flutter Android defaults | compile/target `36`, min `24`, NDK `28.2.13676358` | Inherited from Flutter SDK |
| App version | `1.3.59+1` | Maps to versionName `1.3.59`, versionCode `1` |

Direct `./gradlew` requires `JAVA_HOME` in the current shell. Flutter already
uses the Android Studio JDK. A reproducible direct-wrapper command is:

```bash
JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home" \
  ./android/gradlew -p android -v
```

## Build Probe Results

| Command | Result |
| --- | --- |
| `flutter pub get` | Passed; no dependency upgrade requested |
| `dart format lib test` | Passed; no changes |
| `flutter analyze` | Passed; no findings |
| `flutter test -r expanded --timeout 30s` | Passed, `296/296` |
| `dart fix --dry-run` | Nothing to fix |
| `git diff --check` | Passed |
| `flutter build apk --debug` | Passed: `build/app/outputs/flutter-apk/app-debug.apk` |
| `flutter build apk --release` | Intentionally blocked because private signing is not configured |
| `flutter build appbundle --release` | Intentionally blocked by the same signing guard |

Release compilation and R8 output cannot be fully verified until a private
upload key is configured. Flutter enables R8 for release APK/AAB builds by
default. Do not weaken the signing guard merely to make a probe green.

## Identity and Branding

- Namespace: `com.example.todo_list_app`.
- Application ID: `com.example.todo_list_app`.
- Kotlin source package: `com.example.todo_list_app`.
- App label: `RPG To-Do List` and is not a placeholder.
- Launcher icon: the default Flutter icon and must be replaced before release.
- Launch background is still the basic Flutter template configuration.

The current `com.example...` ID is a release blocker. The app appears
unpublished, but that must be confirmed by the owner before changing it.
Candidate IDs for explicit confirmation:

- `com.albert.rpgtodo`
- `com.dodik.rpgtodo`
- `com.dodik.gamifiedtodo`

Keep `namespace`, `applicationId`, and the `MainActivity.kt` package consistent
unless there is a deliberate reason to separate them. Once published, changing
`applicationId` creates a different Play Store app and updates must retain the
same signing identity.

## Signing

The Kotlin DSL build script reads `android/key.properties`, creates a release
signing configuration, and refuses release/bundle/publish tasks when any field
is missing. It never falls back to debug signing.

Ignored private files include:

- `android/key.properties`
- `android/keystore.properties`
- every `*.jks`
- every `*.keystore`

Use `android/key.properties.example` only as a shape reference. To prepare a
real release manually:

1. Create or select a private upload key using Android Studio or `keytool`.
2. Store it outside the repository and back it up securely.
3. Copy `android/key.properties.example` to `android/key.properties`.
4. Replace placeholders locally; never send the file through chat or Git.
5. Re-run both release probes and verify their artifacts/signatures.
6. Prefer Play App Signing and preserve the upload key identity.

## Manifest and Platform Review

- `android:allowBackup="false"` and `android:fullBackupContent="false"` protect
  private productivity data from normal Android backup/export paths.
- No `dataExtractionRules` is defined. With backup disabled this is not an
  immediate blocker, but confirm behavior on target API devices before release.
- `MainActivity` is the only exported activity and has the launcher intent.
- Notification receivers are explicitly non-exported.
- Production has no `INTERNET` permission; debug/profile add it only for Flutter
  tooling.
- Permissions: notifications, exact alarms, boot completion, and vibration.
- Android 13+ notification permission timing still requires product-level QA.
- `SCHEDULE_EXACT_ALARM` is a policy and UX risk: Android 14+ denies it by
  default for most newly installed apps, so reminders must check permission and
  degrade safely. Confirm that exact precision is genuinely required before
  Play submission.
- Debug admin and `__debug__` storage remain runtime-gated and excluded from
  production persistence.

## Built-in Kotlin Clarification

The project already uses Kotlin DSL. This is not a Groovy-to-KTS migration and
does not require rewriting `MainActivity.kt`.

The warning concerns Flutter's move away from the legacy Kotlin Gradle Plugin:

- `android/app/build.gradle.kts` still applies `kotlin-android` and uses
  `kotlinOptions`.
- Flutter added `android.builtInKotlin=false` and `android.newDsl=false` as
  temporary compatibility flags.
- `audioplayers_android` and `flutter_timezone` also currently apply KGP.

Builds pass, so migration is deferred. Handle it as an isolated dependency and
Android-template batch: verify compatible plugin releases, remove legacy KGP,
move compiler options to the built-in Kotlin DSL, remove compatibility flags,
then rerun debug/release builds with a rollback to the current Gradle files and
lockfile.

## Release Blockers

1. Confirm whether the app has ever been published and choose the final
   application ID.
2. Replace the default Flutter launcher icon and review launch branding.
3. Create and privately configure an upload keystore.
4. Increase `versionCode` from `1` before any subsequent Play upload strategy.
5. Decide whether exact alarms are justified and document permission/fallback
   UX for Play policy.
6. Build signed APK and preferred AAB, then test the release artifact.
7. Complete store listing, privacy/data-safety, backup, and encryption-at-rest
   decisions outside this code-only audit.

## Commands After Private Signing Is Ready

```bash
flutter build apk --release
flutter build appbundle --release
```

Expected outputs:

- `build/app/outputs/flutter-apk/app-release.apk`
- `build/app/outputs/bundle/release/app-release.aab`

## Authoritative References

- [Flutter: Build and release an Android app](https://docs.flutter.dev/deployment/android)
- [Flutter: Built-in Kotlin migration](https://docs.flutter.dev/release/breaking-changes/migrate-to-built-in-kotlin/for-app-developers)
- [Android: Configure the app module](https://developer.android.com/build/configure-app-module)
- [Android: Sign your app](https://developer.android.com/studio/publish/app-signing.html)
- [Android: Exact alarm changes](https://developer.android.com/about/versions/14/changes/schedule-exact-alarms)
