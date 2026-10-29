# Vistara Mobile

Vistara Mobile is the Flutter client for the Vistara film-discovery and
account platform. It connects to the Vistara Next.js service for the
rights-approved catalogue, managed access products, Neon-backed identity,
verified viewing entitlements, and purchase history.

The client follows the device appearance setting and provides branded light
and dark themes. Catalogue and account data are served by the configured
Vistara deployment; credentials and session cookies are handled through the
platform's secure storage.

## Production capabilities

- Browse and search films published by Vistara with approved distribution
  rights and ready video assets.
- View film artwork and metadata supplied by the Vistara service.
- Create an account, sign in, sign out, and request a password reset through
  the Vistara Neon Auth integration.
- View account status, verified active access, and recent purchase history.
- View access products and pricing managed in the Vistara admin console.
- Follow system light/dark appearance with a Violet Vistara identity.

The client does not make up catalogue entries or pass prices in connected
mode. When built without a service origin it clearly identifies the sample
catalogue as preview content and disables live account and pass operations.

## Service-dependent features

Playback and payment checkout are intentionally unavailable until the Vistara
service has production-ready playback delivery and verified MarzPay checkout.
The app must not be represented as streaming films or accepting payments until
those service capabilities are released. The admin console remains the source
of truth for film rights, publishing, product management, payments, and
account administration.

## Requirements

- Flutter SDK and Dart SDK versions matching `pubspec.yaml`.
- Android Studio / Android SDK for Android builds, or Xcode on macOS for iOS.
- A deployed Vistara Next.js service with the mobile routes, Neon Auth, and
  database configuration enabled for connected operation.
- A publicly reachable HTTPS service origin for devices. Do not use
  `localhost` as the API origin on a physical phone.

## Configure and run

Install dependencies and run the checks:

```powershell
flutter pub get
flutter analyze
flutter test
```

Run against the deployed Vistara service:

```powershell
flutter run --dart-define=VISTARA_API_BASE_URL=https://your-vistara-domain.example
```

`VISTARA_API_BASE_URL` must be an HTTP(S) origin with no path, query, or
fragment. Use HTTPS in production; secure authentication cookies are not sent
over HTTP. If the define is omitted, the app opens in a clearly labelled
offline preview and does not claim that authentication or live data works.

The client uses these service endpoints:

| Endpoint | Purpose |
| --- | --- |
| `GET /api/mobile/catalogue` | Published rights-approved films with ready video assets |
| `GET /api/mobile/access-products` | Available admin-managed passes |
| `GET /api/mobile/session` | Authenticated profile, entitlement, and recent purchases |
| `/api/auth/*` | Neon Auth email sign-in, sign-up, sign-out, and password reset |

The Next.js deployment must have its existing database, Neon Auth, and public
`APP_BASE_URL` settings configured. Mobile session responses are private and
not cached; public catalogue and products use the server's short cache policy.

## Build and release

Build a 64-bit Android APK connected to the production service:

```powershell
.\scripts\build_apk.cmd `
  -Mode release `
  -TargetPlatform android-arm64 `
  -ApiBaseUrl https://your-vistara-domain.example
```

Every Android APK build automatically creates a Vistara-named APK in
`build/app/outputs/flutter-apk/`, following
`vistara-[version]-[channel]-[revision].apk`. For example, the current stable
release is `vistara-1.1.0-stable-3.apk`. The script removes Flutter's generic
`app-release.apk` compatibility output after verifying the named APK, leaving
the Vistara filename as the installer artifact. ABI-split or flavored builds
add their variant identifier before `.apk`.

The channel defaults to `stable` for release builds, `beta` for profile builds,
and `development` for debug builds. Pass `-Channel` to override it, for
example:

```powershell
.\scripts\build_apk.cmd -Mode release -Channel beta
```

The optional revision is the build number after `+` in `pubspec.yaml`. Use the
deployment's public HTTPS origin; a build without `-ApiBaseUrl` is an offline
preview build. Direct Flutter Gradle builds also generate the Vistara-named
APK, but the Flutter CLI's generic compatibility output remains; use the
script when you want only the versioned installer left in the output folder.

The Android release build currently uses the local debug signing key for
sideload testing. Before production distribution, configure a private Android
release key and protected CI signing secrets. Never commit signing keys,
passwords, deployment credentials, or local environment files. A debug-signed
APK is not suitable for Play Store release.

Set the Android/iOS version in `pubspec.yaml` using
`MAJOR.MINOR.PATCH+BUILD`. Release semantics, changelog, and the requirement
to tie every release version to a matching commit and annotated tag are
documented in [VERSIONING.md](VERSIONING.md). Record user-visible changes in
[CHANGELOG.md](CHANGELOG.md).

## Branding

The launcher icon and in-app violet palette use the Vistara mark in
`assets/images/vistara_app_icon.png`. Regenerate Android and iOS launcher
assets after changing the source icon:

```powershell
dart run flutter_launcher_icons
```

## Repository

Issues and release history are tracked in the
[vistara-mobile GitHub repository](https://github.com/xhenvolt-code/vistara-mobile).
