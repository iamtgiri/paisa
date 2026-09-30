# Paisa

Paisa is a private, offline-first personal finance tracker for Android — track income, expenses, accounts, budgets, savings goals, and recurring bills entirely on your own device.

Project website: <https://iamtgiri.github.io/paisa>

> **Built with "vibe coding".** This app is being developed with heavy assistance from AI coding tools rather than by a professional engineering team from scratch. Features, code, and these docs are written, reviewed, and iterated on with an AI pair-programmer. It works and is actively improved, but treat it as an independent personal project rather than a polished commercial product.

## Features

### Transactions & accounts

- Add, edit, delete, duplicate, and favorite transactions, with undo on delete.
- Search transactions by description, category, tag, or amount; filter by category, payment method, account, or type; sort by date or amount.
- Multiple accounts (cash, bank, wallet, credit card) with balances that stay in sync with every transaction, transfer, and edit — including rollback if a balance update fails partway through.
- Transfers between accounts with history.
- Quick-add favorites for repeat transactions (e.g. daily coffee, monthly rent).

### Categories, budgets & goals

- A large default category set covering everyday spending, EMIs/loans, insurance, investments (SIP, stocks, gold, PF/NPS, fixed deposits, emergency fund), family & health, and more — organized so the Financial Health score can classify spending into **Needs / Wants / Savings**.
- Enable/disable any category to fit your own habits; new default categories are added automatically on update (nothing is ever silently deleted).
- Per-category monthly budgets with progress bars and 80%/100% local alert notifications.
- Savings goals with target amount, optional deadline, and progress tracking.
- Recurring transactions (daily/weekly/monthly/yearly) with an explicit due-date picker — e.g. SIP on the 3rd, rent on the 5th — and month-end-safe date handling (a bill due on the 31st correctly lands on Feb 28, it doesn't drift into March). Due/overdue reminders are local notifications; posting a recurring item is a manual, reviewable action.

### Optional automatic transaction capture

- An **opt-in, off-by-default** Android feature that reads notifications from apps you choose (e.g. your bank's SMS/notification) and locally parses amount, date, merchant, and reference number using on-device pattern matching — no internet connection, no server, no third-party parsing service.
- Only messages that look like an actual bank transaction are captured; OTPs, marketing, and unrelated notifications are ignored.
- Nothing is posted automatically. Every captured message becomes a **Pending Transaction** that you review, assign to an account/category, and confirm (or ignore) before it ever touches a balance.
- Can be turned off at any time, which also clears any locally queued (not-yet-reviewed) captures.

### Analytics & insights

- **Breakdown**: category pie chart, payment-method/account split.
- **Trends**: 6-month income vs. expense chart, daily bar chart, and a daily spending heatmap.
- **Category Insights**: month-over-month comparison per category with 6-month history.
- **Calculator**: pick any set of categories and see their combined total.
- **Insights**: at-a-glance metrics (net cash flow, savings rate, daily spend pace, month-over-month change), a **Financial Health score** (0–100, with an info popup explaining the score bands and the Needs/Wants/Savings classification), an outlier-resistant month-end spending projection, budget and savings-goal progress, a local net-worth trend (built from daily balance snapshots), weekday spending patterns, upcoming recurring obligations, an estimated monthly/yearly subscription cost, and more.
- **Top Spends**: your largest expenses for the month, ranked.

### Reports & export

- A structured Monthly Report (summary, income & expense breakdown by category, largest expenses, budget status) that you can copy or share as plain text — nothing leaves your device unless you choose to share it.
- CSV export of transactions and full JSON backup export for your own records.

### Backup & data safety

- Full JSON export/import of every transaction, account, category, budget, goal, and recurring item.
- Imports are validated (version, structure, and field checks) **before** any existing data is touched, so a corrupted or incompatible file can't wipe your data.
- A local safety backup is created automatically right before every restore, so a bad import can be undone.

### Notifications (all local, no server involved)

- Budget threshold alerts (nearing/exceeding a category limit).
- Recurring transaction due/overdue reminders.
- Daily, weekly, and monthly spending report notifications with a previous-period comparison, net cash flow, and top spending category.

### Security & personalization

- Optional 4-digit PIN lock on app launch (a convenience lock for casual privacy — see [Privacy Model](#privacy-model) below).
- Dark and light themes, both checked for text/background contrast.
- Configurable currency symbol, prefix/suffix placement, and decimal precision.
- Month navigation available throughout the app.

## Privacy Model

Paisa is local-first. Financial records are stored on the device using Isar and local JSON preferences. The application does not require a backend, account, or cloud sync service, and no data is sent anywhere by default.

The optional notification-capture feature is **off by default** and requires you to explicitly grant Android notification access — it only reads notifications on your own device and never transmits them anywhere; parsing happens entirely with local pattern matching.

The optional PIN is stored unhashed and is an app-access convenience feature for casual privacy (e.g. someone picking up your phone), not encryption, and not a replacement for Android device security or a professionally audited security boundary.

Exported backups can contain sensitive financial information. Store them securely and do not commit them to Git.

## Current Release

The current release is **2.0.0** with Android build number **15**. See [CHANGELOG.md](CHANGELOG.md) for release notes and [docs/RELEASE_PROCESS.md](docs/RELEASE_PROCESS.md) for versioning rules.

## Requirements

- Flutter 3.41.4
- Dart 3.11.1 (included with Flutter)
- Android SDK with API 36 for the validated Android release build
- Java 17 for Android builds

Android is the primary supported and tested platform. This project has no other backend dependency — no paid API keys, no cloud database, and no third-party analytics are used anywhere in the app.

## Local Development

```powershell
git clone https://github.com/iamtgiri/paisa.git
cd paisa

flutter pub get
flutter run
```

If you change any Isar model (files under `lib/models/`), regenerate the generated code:

```powershell
dart run build_runner build --delete-conflicting-outputs
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

Please read [CONTRIBUTING.md](CONTRIBUTING.md) before submitting changes. Keep pull requests focused, test behavior that affects financial calculations or persistence, and never include real financial data in issues, screenshots, fixtures, or commits.

## Security

For security concerns, follow the private reporting guidance in [SECURITY.md](SECURITY.md). Please do not disclose sensitive details in a public issue.

## License

Paisa is available under the [MIT License](LICENSE).


