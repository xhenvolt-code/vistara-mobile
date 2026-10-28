# Versioning and releases

Vistara Mobile follows Semantic Versioning. The canonical version is the
`version` value in `pubspec.yaml`, in Flutter's `MAJOR.MINOR.PATCH+BUILD`
format. The starting version is `1.0.0+2`.

## Choosing the version

- **Major** (`X.0.0`): incompatible behavior or significant product changes.
- **Minor** (`1.X.0`): backward-compatible features and substantial
  functionality additions.
- **Patch** (`1.0.X`): backward-compatible fixes and small improvements.
- **Build/revision** (`+N`): a monotonically increasing integer. Increment it
  for every release, including patch releases, and never reuse a build number.

For example, the next patch release after `1.0.0+2` is `1.0.1+3`. A minor
release would be `1.1.0+3`, and a major release would be `2.0.0+3`.

Use Conventional Commit prefixes to describe changes: `feat:` for features,
`fix:` for fixes, and `BREAKING CHANGE:` in the commit body for incompatible
changes. These describe the change; the version bump is recorded explicitly in
the release commit.

## Release commit and tag

Every release must have a dedicated commit that updates `pubspec.yaml` and
`CHANGELOG.md`. Use a commit subject such as `release: v1.1.0`, and create an
annotated Git tag `v1.1.0` on that exact commit. The tag omits the Flutter
build number; the tagged commit's `pubspec.yaml` records it.

Before tagging, run:

```powershell
flutter pub get
flutter analyze
flutter test
```

Then create and publish the versioned commit and tag:

```powershell
git add pubspec.yaml CHANGELOG.md
git commit -m "release: v1.1.0"
git tag -a v1.1.0 -m "Vistara Mobile v1.1.0"
git push origin main
git push origin v1.1.0
```

Replace the example version with the value chosen for the release. The current
release is `1.1.0+3`; this version and build number must be recorded in the
release commit and its matching tag. A release tag must never point to a
different commit than the version bump it names.
