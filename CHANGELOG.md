# Changelog

All notable changes to Paisa are documented here.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and versions follow [Semantic Versioning](https://semver.org/).

## [2.0.0+15] - 2026-10-01

### Notes

- Tagged as a major version because of the size of the feature and redesign work in this release (automatic transaction capture, a full analytics/insights suite, a corrected light theme, and a large accuracy pass on financial calculations), even though existing data and backups remain compatible.

### Added

- Optional, off-by-default automatic transaction capture from Android bank notifications, with fully local parsing and a mandatory Pending Transactions review step before anything is posted.
- Financial Health score info popup explaining score bands and the Needs/Wants/Savings category classification.
- Detailed Insights: average transaction size, highest spending day/category, budget utilization, upcoming recurring obligations, estimated subscription cost, spending consistency, and emergency-fund coverage.
- Local net-worth trend chart built from daily account-balance snapshots.
- Daily spending heatmap, budget progress list, and savings-goal progress list in Analytics.
- Explicit next-due-date picker for recurring transactions.
- 8 new default categories to fill Needs/Savings gaps (society/maintenance, home repairs, vehicle maintenance, domestic help, gold, PF/NPS/pension, fixed/recurring deposit, emergency fund). New defaults are now reseeded automatically on app start, replacing the old manual "Add Missing Categories" action.
- Automatic local safety backup created before every restore.
- Backup validation (version, structure, and enum checks) before any existing data is cleared during import.

### Changed

- Reworked light-theme surfaces, text, dividers, inputs, cards, navigation, dialogs, and shared widgets to use a coordinated light palette with real tonal depth and corrected text/background contrast (including several colors that were tuned only for the dark theme).
- Centralized all transaction create/edit/delete/undo/duplicate flows through one balance-safe path, with automatic rollback if an account-balance update fails partway through.
- Cash accounts now participate in balance updates like any other account (previously excluded).
- Recurring transaction due-date math no longer drifts forward when the due day (29th/30th/31st) doesn't exist in the target month — it now clamps to month-end instead.
- Rewrote the month-end spending projection and Financial Health score to use an outlier-resistant, recency-weighted historical baseline instead of a naive linear projection.
- Restructured the Monthly Report (on-screen and shared/copied text) with clearer sections, per-category percentages, an income breakdown, and a month-over-month comparison.
- Daily/weekly/monthly spending report notifications now include net cash flow and the top spending category, and are no longer truncated on Android.
- Added independent daily, weekly, and monthly local spending report notifications with previous-period comparisons.
- Weekly reports now run only on Sunday night or Monday catch-up; monthly reports run only on the final night of the month or first-day catch-up.
- Added stable Android release signing support for local builds and GitHub Actions releases.
- Corrected the keystore path resolution for Android release builds.

### Fixed

- Stabilized Android validation and release automation.
- Removed redundant workflow branches after integrating their changes into `main`.
- Added explicit CMake 3.22.1 provisioning with retries for Android CI builds.
- Fixed a hardcoded dark-theme background color on the Spending Reports settings sheet that made its text unreadable in light mode.

### Removed

- Manual "Add Missing Categories" action from the More tab (superseded by automatic reseeding on app start).

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
