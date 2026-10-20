# Baby Tracker clone

Flutter rebuild of Baby Tracker / Luli 2.9.0 with **every feature free** (no purchases, trials or entitlement checks). Independent app: local storage, application ID `dev.quantavil.babytracker`, no connection to the original Firebase account or subscriptions.

## Approach

Functional reverse engineering with the `ditto` skill: the original app is a black-box test oracle. Catalog its features, recover its data model from captured app data, record golden traces of its behaviour, and build the clone until the same experiments produce the same notes. Results are tracked in `parity.md`.

```
apk/          original base.apk + splits (gitignored)
research/     catalog, data captures (state/ gitignored), data-model.md
experiments/  behaviour experiments (run(lab))
traces/       original vs clone golden traces (raw/ gitignored)
parity.md     scorecard
lib/ test/    the app
```

## Development

Flutter SDK: `/home/quantavil/.local/share/baby-tracker-sdk/flutter/bin/flutter`.

```sh
flutter pub get
flutter analyze
flutter test
```

`tool/parity_preview.dart` is a test-only entrypoint with in-memory fixtures; it never reads user preferences.

## ARM64 APK releases

[Download the installable APK](https://github.com/quantavil/baby-tracker-clone/releases/latest/download/baby-tracker-arm64.apk). Requires ARM64 and Android 7.0 or newer; GitHub's source archives cannot be installed.

Each push to `main` builds one signed `arm64-v8a` release APK and publishes it on [GitHub Releases](https://github.com/quantavil/baby-tracker-clone/releases). CI signing uses the `ANDROID_KEYSTORE_BASE64` and `ANDROID_KEYSTORE_PASSWORD` secrets with alias `baby-tracker`. Local builds without signing variables use the debug key.
