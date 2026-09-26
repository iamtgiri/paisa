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

## Android Signing

Every published APK must use the same private release keystore. Do not use the Android debug keystore for public releases: GitHub-hosted runners create a different debug certificate on different runs, which prevents users from installing updates.

Create the release keystore once and store it outside the repository:

```powershell
keytool -genkeypair -v `
   -keystore paisa-upload.jks `
   -alias paisa `
   -keyalg RSA `
   -keysize 2048 `
   -validity 10000
```

Add these repository Actions secrets under **Settings -> Secrets and variables -> Actions**:

| Secret | Value |
| --- | --- |
| `PAISA_KEYSTORE_BASE64` | Base64 contents of `paisa-upload.jks` |
| `PAISA_KEYSTORE_PASSWORD` | Keystore password |
| `PAISA_KEY_ALIAS` | `paisa` |
| `PAISA_KEY_PASSWORD` | Key password |

On PowerShell, copy the keystore as one-line Base64 for the first secret:

```powershell
[Convert]::ToBase64String([IO.File]::ReadAllBytes('.\paisa-upload.jks')) | Set-Clipboard
```

The tagged release workflow refuses to build when these secrets are missing. It writes temporary signing material only inside the runner and removes it after the build.

The first stable-key release cannot update an app installed from a differently signed debug APK. Export the user's Paisa backup, uninstall the old debug-signed app once, and install the first stable release. Every later release will update normally.

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
8. Push the tag. GitHub Actions will validate the tag, build the release APK, and create the GitHub release automatically.

## GitHub Release Notes

Release notes should summarize user-visible changes, compatibility requirements, data migration concerns, and known limitations. The tagged release workflow generates the initial notes and attaches the APK; review them before publishing the release publicly. Link to the matching changelog entry rather than duplicating every implementation detail.

## Data and Migration Discipline

Changes to Isar schemas, exported JSON, or preference keys require an explicit migration assessment. If existing user data could be affected, document the migration and test it with a copy of a representative demo dataset before publishing.
