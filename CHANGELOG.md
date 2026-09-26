# Changelog

All notable changes to Paisa are documented here.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and versions follow [Semantic Versioning](https://semver.org/).

## [1.2.2+14] - Unreleased

### Fixed

- Stabilized Android validation and release automation.
- Removed redundant workflow branches after integrating their changes into `main`.
- Added explicit CMake 3.22.1 provisioning with retries for Android CI builds.

### Changed

- Reworked light-theme surfaces, text, dividers, inputs, cards, navigation, dialogs, and shared widgets to use a coordinated light palette.
- Kept the existing dark theme palette unchanged.
- Added independent daily, weekly, and monthly local spending report notifications with previous-period comparisons.
- Weekly reports now run only on Sunday night or Monday catch-up; monthly reports run only on the final night of the month or first-day catch-up.
- Added stable Android release signing support for local builds and GitHub Actions releases.
- Corrected the keystore path resolution for Android release builds.

### Added

- MIT License for the public repository.

## [1.2.1+6] - 2026-09-25

### Fixed

- Updated the Android SDK setup action used by validation and release workflows.

## [1.2.1+5] - 2026-09-25

### Added

- Complete GitHub issue, pull request, dependency update, validation, and tagged Android release automation.
- Android API 36 provisioning in CI to match the release build configuration.

### Changed

- GitHub issue templates now require clearer titles, labels, and ownership fields.

## [1.2.1+4] - 2026-09-25

### Added

- Public project documentation for local development, privacy, contribution, security, and releases.
- GitHub Actions validation for formatting, analysis, tests, and Android debug builds.

### Fixed

- Account filter chips now reflect selection immediately while the filter sheet remains open.
- Android release resource linking for the legacy Isar library under modern Android Gradle Plugin versions.

### Notes

- Android is the primary validated release target for this version.
- No financial data or cloud service was added.

## Previous baseline: 1.2.0+3

- Baseline feature release before the public repository preparation work.
