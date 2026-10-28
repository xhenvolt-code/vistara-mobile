# Vistara Mobile

The Android/iOS companion to the Vistara Next.js service. The mobile app uses
the same Neon-authenticated accounts, the same rights-approved film catalogue,
and the access products managed in the Vistara admin console.

## Versioning

The current app version is `1.0.0+2`. Follow the [versioning and release
policy](VERSIONING.md) for semantic version changes, build revisions, and
versioned Git commits and tags.

## Current mobile features

- Cinematic black-and-red discovery experience with featured films and
  searchable catalogue.
- Catalogue and artwork loaded from Vistara's published, rights-approved
  catalogue when the API is configured. The offline preview uses clearly
  identified sample artwork.
- Neon email sign-in, account creation, and password reset through the Next.js
  auth routes. Session cookies are stored with platform secure storage.
- Account profile, verified active viewing entitlement, and recent purchase
  history from the authenticated mobile-session endpoint.
- Available access passes and prices loaded from admin-managed products.
- Playback and MarzPay checkout remain unavailable, consistent with the
  current web service. Passes are not sold until checkout is enabled.

The Next.js admin console remains the source of truth for catalogue publishing,
rights approval, pass pricing/availability, payments, storage, and account
administration. Those administrative operations are intentionally not exposed
in the consumer app.

## Configure and run

The mobile app must use the publicly reachable HTTPS origin of the deployed
Vistara Next.js app. Do not use `localhost` for a physical phone: it points to
the phone itself.

```powershell
flutter pub get
flutter run --dart-define=VISTARA_API_BASE_URL=https://your-vistara-domain.example
```

In offline preview mode (without `VISTARA_API_BASE_URL`), catalogue sample
artwork is shown, but authentication and live pass data remain unavailable.

## Build an Android APK

Build a release APK for 64-bit Android phones:

```powershell
flutter build apk --release --target-platform android-arm64 `
  --dart-define=VISTARA_API_BASE_URL=https://your-vistara-domain.example
```

The installer is written to
`build/app/outputs/flutter-apk/app-release.apk`. This project currently signs
release builds with the local Android debug key for sideload testing. Set up a
private release signing key before distributing a production/store build; never
commit that key or its passwords.

Run the app checks with:

```powershell
flutter analyze
flutter test
```

## Next.js mobile API

The Next.js service exposes public read-only endpoints for the published
catalogue and available access products, plus an authenticated mobile-session
endpoint for the profile, active entitlement, and purchase history. The mobile
client continues to use the Next.js Neon Auth handler for email sign-in,
sign-up, sign-out, and reset requests. Configure the existing Neon, database,
and public `APP_BASE_URL` variables on the Next.js deployment.

## Service limitations

- The sample Fliqs artwork is not a real Vistara listing or evidence of
  streaming rights.
- The mobile player is a placeholder because playback delivery is not
  implemented in Vistara.
- No live MarzPay collection is initiated by the mobile app; checkout stays
  disabled until the provider setup and payment verification are enabled.
