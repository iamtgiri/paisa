# Security Policy

## Scope

Paisa is an offline-first personal finance application. Financial records are intended to remain on the device unless the user explicitly exports them.

Paisa includes an optional, off-by-default Android feature that reads notifications (with the user's explicit OS-level permission grant) to locally detect bank transaction messages. All parsing happens on-device using pattern matching; nothing is transmitted anywhere, and the app never posts a transaction automatically — every match must be manually reviewed and confirmed by the user. This feature can be disabled at any time, which also clears any locally queued, unreviewed captures.

The optional PIN protects access inside the application, but it is not a substitute for Android device security, encrypted storage, or a professionally audited security boundary. The PIN is currently stored unhashed in local app preferences.

## Reporting a Vulnerability

Please do not report security issues in a public GitHub issue. Use GitHub's private vulnerability reporting feature when it is enabled for this repository. If it is not enabled, contact the repository maintainer privately through the verified contact method listed on the maintainer's GitHub profile.

Include:

- A clear description of the issue and its impact.
- Reproduction steps or a minimal proof of concept.
- The affected version, platform, and device where relevant.
- Any suggested mitigation, if known.

Do not attach real financial data. Redact logs and exported files before sharing.

## Supported Versions

Only the latest published release is expected to receive security fixes. Users should keep the app and their device operating system up to date.
