# Changelog

All notable changes to Paisa are documented here.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and versions follow [Semantic Versioning](https://semver.org/).

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
