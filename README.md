# Paisa
Paisa is a private, offline-first personal finance tracker for managing expenses, budgets, accounts, and savings on your device.

Project website: <https://iamtgiri.github.io/paisa>

## Product Focus

- Track income, expenses, transfers, accounts, budgets, savings goals, and recurring transactions.
- Organize transactions with searchable, enable/disable category management.
- Review spending by category, account, month, and custom date range.
- Use account-aware transaction filters and category trend analytics.
- Import and export local data for personal backup and migration.
- Protect the app with an optional PIN, theme settings, spending limits, and local notifications.

## Privacy Model

Paisa is local-first. Financial records are stored on the device using Isar and local JSON preferences. The application does not require a backend, account, or cloud sync service.

Exported backups can contain sensitive financial information. Store them securely and do not commit them to Git. The optional PIN is an app-access convenience feature, not a replacement for device encryption or a security audit.

## Current Release

The next release is **1.2.2** with Android build number **10**. See [CHANGELOG.md](CHANGELOG.md) for release notes and [docs/RELEASE_PROCESS.md](docs/RELEASE_PROCESS.md) for versioning rules.

## Requirements

- Flutter 3.41.4
- Dart 3.11.1 (included with Flutter)
- Android SDK with API 36 for the validated Android release build
- Java 17 for Android builds

Android is the primary tested release target. Other Flutter targets are retained in the project but should be validated independently before being described as production-supported.

## Local Development

```powershell
git clone https://github.com/<your-account>/paisa.git
cd paisa

flutter pub get
flutter run
```

For Android builds on Windows, make sure `JAVA_HOME` points to a Java 17 installation:

```powershell
$env:JAVA_HOME = 'C:\Android\Android Studio\jbr'
flutter build apk --release
```

The release APK is written to `build/app/outputs/flutter-apk/app-release.apk`.

## Quality Checks

Run these before opening a pull request or publishing a release:

```powershell
dart format --output=none --set-exit-if-changed .
flutter analyze --no-fatal-infos --no-fatal-warnings
flutter test
flutter build apk --release
```

## Versioning

Paisa follows Semantic Versioning for the public version and uses Flutter's Android build number for release ordering:

`MAJOR.MINOR.PATCH+BUILD`

- **PATCH**: bug fixes, documentation, build fixes, and small UI corrections.
- **MINOR**: backward-compatible user-facing features.
- **MAJOR**: breaking behavior, migrations, or incompatible public changes.
- **BUILD**: increment for every published build, regardless of semantic version level.

Every release must update `pubspec.yaml` and `CHANGELOG.md`. The complete release procedure is documented in [docs/RELEASE_PROCESS.md](docs/RELEASE_PROCESS.md).

## Contributing

Please read [CONTRIBUTING.md](CONTRIBUTING.md) before submitting changes. Keep pull requests focused, test behavior that affects financial calculations or persistence, and never include personal finance data in issues, screenshots, fixtures, or commits.

## Security

For security concerns, follow the private reporting guidance in [SECURITY.md](SECURITY.md). Please do not disclose sensitive details in a public issue.

## License

Paisa is available under the [MIT License](LICENSE).

