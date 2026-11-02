# Changelog

All notable releases of Vistara Mobile are recorded here. Versions follow the
policy in [VERSIONING.md](VERSIONING.md).

## [1.2.1] - 2026-11-02

- Configure `https://vistara-main.vercel.app` as the default API origin for
  app launches and APK builds.
- Keep offline preview builds available as an explicit opt-in.

## [1.2.0] - 2026-11-02

- Add authenticated MP4 playback through Vistara's entitlement-protected
  byte-range streaming endpoint.
- Require a signed-in account and active access pass before starting playback.
- Add in-player playback controls and access/sign-in recovery actions.
- Update mobile catalogue and release documentation to reflect the current
  Next.js service capabilities.

## [1.1.0] - 2026-10-28

- Add the Vistara violet V launcher icon and in-app brand mark.
- Add coordinated light and dark themes that follow the device appearance.
- Update Android launch surfaces to match the system light/dark setting.
- Expand production setup, service integration, and signing guidance.

## [1.0.0] - 2026-10-28

- Establish the initial versioned Vistara Mobile app.
- Add the cinematic mobile discovery experience and film details.
- Connect catalogue, access products, and account features to the Vistara
  Next.js service.
- Keep streaming playback and payment checkout disabled until the service
  supports them.
