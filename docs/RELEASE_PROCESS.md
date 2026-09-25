# Release Process

This document defines how Paisa versions are changed and published. It is intentionally explicit so every release has a traceable, reviewable version change.

## Version Format

Flutter uses the version in `pubspec.yaml`:

```text
MAJOR.MINOR.PATCH+BUILD
```

The semantic version communicates compatibility. The build number identifies a distinct installable artifact and must always increase.

## Change-Level Rules

| Change | Version change | Examples |
| --- | --- | --- |
| Patch | `1.2.0` -> `1.2.1` | Bug fix, small UI correction, build fix, documentation-only release |
| Minor | `1.2.0` -> `1.3.0` | New backward-compatible feature, new report, new workflow |
| Major | `1.2.0` -> `2.0.0` | Breaking behavior, incompatible data migration, or major product contract change |

For every published build, increase the build number: `+3` -> `+4`. A build-number-only increment is appropriate for a rebuild with no semantic product change. Never reuse a published build number.

## Release Checklist

1. Review the changes since the previous tag and decide patch, minor, or major scope.
2. Update `version` in `pubspec.yaml`.
3. Add a dated entry to `CHANGELOG.md` with Added, Changed, Fixed, and Removed sections as applicable.
4. Run validation from the repository root:

   ```powershell
   dart format --output=none --set-exit-if-changed .
   flutter analyze --no-fatal-infos --no-fatal-warnings
   flutter test
   flutter build apk --release
   ```

5. Review the generated APK and verify the app launches on a supported test device.
6. Check that no personal data, local paths, secrets, or generated output is included in the commit.
7. Create an annotated Git tag matching the semantic version, for example `v1.2.1`.
8. Create a GitHub release from that tag and attach the release artifact when appropriate.

## GitHub Release Notes

Release notes should summarize user-visible changes, compatibility requirements, data migration concerns, and known limitations. Link to the matching changelog entry rather than duplicating every implementation detail.

## Data and Migration Discipline

Changes to Isar schemas, exported JSON, or preference keys require an explicit migration assessment. If existing user data could be affected, document the migration and test it with a copy of a representative demo dataset before publishing.
