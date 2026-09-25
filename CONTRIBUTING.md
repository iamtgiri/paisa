# Contributing to Paisa

Thank you for helping improve Paisa. Contributions should preserve the project's local-first privacy model and keep financial calculations reliable.

Paisa is distributed under the MIT License. By contributing, you agree that your contributions may be distributed under the same license.

## Before You Start

- Read the README and the release process in `docs/RELEASE_PROCESS.md`.
- Open an issue first for substantial behavior changes or new dependencies.
- Never include real financial records, exported backups, screenshots with personal data, API keys, or machine-specific paths.

## Development Setup

Use Flutter 3.41.4 and Java 17 for Android work. From the repository root:

```powershell
flutter pub get
dart format .
flutter analyze --no-fatal-infos --no-fatal-warnings
flutter test
```

For Android release validation, set `JAVA_HOME` to Java 17 and run:

```powershell
flutter build apk --release
```

## Change Standards

- Keep changes focused and consistent with existing Riverpod, Isar, and Flutter patterns.
- Add or update tests when changing calculations, persistence, filtering, import/export, or release behavior.
- Keep user-visible copy clear and professional.
- Do not add network services or telemetry without an explicit privacy review.
- Update `CHANGELOG.md` for user-visible changes.
- Update the version in `pubspec.yaml` when preparing a release, according to the documented change level.

## Pull Requests

A pull request should include:

- A concise problem statement and implementation summary.
- The user-visible impact and any migration or compatibility notes.
- Tests and validation commands that were run.
- Screenshots or recordings for meaningful UI changes, using demo data only.
- Updated documentation when behavior or setup changes.

Keep commits small enough to review. Do not commit generated build output, local configuration, or dependency cache directories.
