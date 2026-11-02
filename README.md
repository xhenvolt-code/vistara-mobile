# Vistara Mobile

Vistara Mobile is the Flutter client for the Vistara film-discovery and
account platform. It connects to the Vistara Next.js service for the
rights-approved catalogue, managed subscription plans, Neon-backed identity,
verified viewing entitlements, and purchase history.

The client follows the device appearance setting and provides branded light
and dark themes. Catalogue and account data are served by the configured
Vistara deployment; credentials and session cookies are handled through the
platform's secure storage.

## Production capabilities

- Browse and search films published by Vistara with approved distribution
  rights and ready video assets.
- View film artwork and metadata supplied by the Vistara service.
- Play available films through Vistara's protected MP4 stream after signing in
  with an active subscription. Access is checked by the server, and playback
  supports range-based streaming.
- Create an account, sign in, sign out, and request a password reset through
  the Vistara Neon Auth integration.
- Sign in or create an account with Google through Neon Auth, alongside the
  email-and-password options available on the Next.js application.
- View account status, verified active subscriptions, and recent purchase history.
- View subscription terms and pricing managed in the Vistara admin console.
- Start a subscription payment using Uganda mobile money through MarzPay.
  Viewing access is granted only after the Vistara server verifies payment.
- Follow system light/dark appearance with a Violet Vistara identity.

The client does not make up catalogue entries or subscription prices in
connected mode. When built without a service origin it clearly identifies the
sample catalogue as preview content and disables live account and subscription
operations.

## Service-dependent features

MarzPay currently collects a one-time payment for a selected subscription
term; automatic renewal is not supported. Daily, weekly, bi-weekly, monthly
(30-day), and custom day durations can be configured by administrators.
Sample/offline preview artwork is not a real listing and cannot be watched.
The app does not request camera, microphone, or location access because its
current features do not need them. User-approved screen sharing is not yet
available: it also requires an authenticated admin viewer and dedicated
signaling and media transport.

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

The app defaults to the deployed Vistara API at
`https://vistara-main.vercel.app`, so connected data and account features work
without an extra build define. Override that origin only for a separate
deployment:

```powershell
flutter run --dart-define=VISTARA_API_BASE_URL=https://your-vistara-domain.example
```

`VISTARA_API_BASE_URL` must be an HTTP(S) origin with no path, query, or
fragment. Use HTTPS in production; secure authentication cookies are not sent
over HTTP. To intentionally build an offline preview, use the APK script's
`-AllowOfflinePreview` option.
`APP_BASE_URL` in the Next.js `.env.local` is a separate server setting; it
does not automatically become a Flutter compile-time define.

Google sign-in also requires the deployed Neon Auth Google provider to be
configured. In Google Cloud, register an Android OAuth client for package
`com.vistara.mobile` and the SHA-1 fingerprints of every signing certificate
used (debug, sideload, and production/Play signing as applicable). The app
uses the configured web OAuth client as its server client ID; override it for
another deployment with
`--dart-define=VISTARA_GOOGLE_SERVER_CLIENT_ID=<web-client-id>`. This client ID
is public configuration, not a client secret.

The client uses these service endpoints:

| Endpoint | Purpose |
| --- | --- |
| `GET /api/mobile/catalogue` | Published rights-approved films with ready video assets |
| `GET /api/mobile/access-products` | Available admin-managed subscription plans |
| `POST /api/payments/marzpay/collections` | Start an authenticated MarzPay payment |
| `GET /api/mobile/session` | Authenticated profile, entitlement, and recent purchases |
| `GET /api/movies/{slug}/playback` | Entitlement-protected MP4 stream with byte-range support |
| `/api/auth/*` | Neon Auth email/Google sign-in, sign-up, sign-out, and password reset |

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

The APK script defaults to `https://vistara-main.vercel.app`. Use
`-ApiBaseUrl` or `VISTARA_API_BASE_URL` only to override it. To intentionally
package an offline preview without live data or account access, pass
`-AllowOfflinePreview`.

Every Android APK build automatically creates a Vistara-named APK in
`build/app/outputs/flutter-apk/`, following
`vistara-[version]-[channel]-[revision].apk`. For example, the current stable
release is `vistara-1.3.0-stable-6.apk`. The script removes Flutter's generic
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
deployment's public HTTPS origin. Debug/profile/release builds without an
override use `https://vistara-main.vercel.app`. Direct Flutter Gradle builds
also generate the Vistara-named APK, but the Flutter CLI's generic
compatibility output remains; use the script when you want only the
versioned installer left in the output folder.

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
