# Baby Tracker reconstruction

Updated target: **every feature free**. All eight local trackers and computed statistics are now accessible without payment. See [free-feature policy](docs/free-feature-policy.md) and the [current validation](docs/parity-audit/2026-10-02/REPORT.md). Full-app parity remains incomplete.

Flutter reconstruction of the observed free Baby Tracker / Luli 2.9.0 flows. This is an independent app with local storage and application ID `dev.quantavil.babytracker`; it does not connect to the original Firebase account or subscriptions.

## Development

Flutter SDK: `/home/quantavil/.local/share/baby-tracker-sdk/flutter/bin/flutter` (official prebuilt stable SDK; pinned metadata in `evidence/docs/flutter-sdk.json`).

```sh
flutter pub get
flutter analyze
flutter test
```

Later visual comparison: `flutter run -d chrome`. Later Android verification: `flutter run -d emulator-5556`. These runtime milestones are separate from the initial source/test reconstruction. SDK path can be added temporarily to PATH; no shell profile was changed.

## Implemented scope

Home/day selector/schedule dial, local History create/edit/delete, all eight tracking editors, sleep timer pause/resume/stop, simultaneous nursing timer, feeding/food/diaper details, metric and imperial conversion, baby profile and preferences, seven-day recorded sleep/feed/diaper statistics, night-sleep calculation and share PNG download/copyable summary. Original artwork/fonts and light background are reused. The app starts empty; sample records require explicit action.

For repeatable comparisons, `tool/parity_preview.dart` uses only an in-memory fixture with captured dates and nap timings. It never reads user preferences. Its current compiled localhost comparison route is `/faithful/` (the older `/parity/` build is retained); it is separate from the real preview at `/`.

## Known limits

Exact predictions and entitled-editor layouts remain unverified. Initial onboarding, auth/cloud sync, actual notification delivery, Android widgets and native sharing/saving are incomplete. The web PNG download is verified. Original-store QR links and commerce offers are deliberately omitted. Browser and Android system bars differ; no perfect screenshot or Android runtime parity claim follows from passing tests.

Evidence: `/home/quantavil/Documents/baby-tracker-clone/evidence/original-analysis/REPORT.md`.
Asset copies and SHA256 references: `evidence/docs/asset-source.json`. Fonts and original artwork are reused for the requested reconstruction; original evidence files are preserved.


Latest original-app walkthrough and corrected-flow evidence: [October 2 live validation](docs/live-validation-2026-10-02/REPORT.md). Full visual/behavioral parity has not passed.

## Local evidence layout

All reconstruction work now lives in this project. `evidence/original-analysis/` holds the original analyzer exports and runtime graph runs; `evidence/live-runtime/` holds supplementary emulator checks; `evidence/docs/` holds raw report captures and reverse-engineering receipts; `evidence/research/` holds new supplementary analysis. The entire `evidence/` directory is ignored by Git. Source assets required to render the app remain tracked under `assets/`.

`evidence/relocation.json` records old/current paths and SHA-256 hashes for 33,205 moved files. Archived receipts retain historical paths; use this mapping to locate their current files. Recovery helpers resolve the relocated inputs relative to this repository and write new outputs to `evidence/research/`.

Public `main` starts from a clean source snapshot. Earlier reconstruction history and raw evidence remain local and are not published.

See [parity root-cause investigation](docs/parity-causes.md) for the fixture explanation and missing behavioral layers.

## ARM64 APK releases

[Download the installable APK](https://github.com/quantavil/baby-tracker-clone/releases/latest/download/baby-tracker-arm64.apk). Use this `.apk` file; GitHub’s Source code ZIP/TAR downloads are source archives and cannot be installed on Android. Requires ARM64 and Android 7.0 or newer.

Each push to `main` builds one signed release APK for `arm64-v8a` and publishes it on [GitHub Releases](https://github.com/quantavil/baby-tracker-clone/releases). Flutter 3.47.5, its package cache, and Gradle dependencies are cached; superseded builds are cancelled. No web, iOS, emulator, or other ABI jobs run. Manual builds are also available in Actions.

CI signing uses `ANDROID_KEYSTORE_BASE64` and `ANDROID_KEYSTORE_PASSWORD` repository secrets, with alias `baby-tracker`. Keep the private key backed up to preserve Android update compatibility. Build numbers increase with each workflow run. Local builds without signing environment variables use the development debug key.
