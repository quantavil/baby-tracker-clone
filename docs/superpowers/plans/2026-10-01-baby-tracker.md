# Baby Tracker Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [x]`) syntax for tracking.

**Goal:** Build a locally persistent Flutter reconstruction of the observed core Baby Tracker flows.
**Architecture:** Immutable activity/profile models, JSON repository and ChangeNotifier controller; feature widgets consume controller state. Original extracted assets supply artwork/fonts.
**Tech Stack:** Flutter stable, Dart, shared_preferences, flutter_test.
**Spec:** `docs/superpowers/specs/2026-10-01-baby-tracker-design.md`

## Global Constraints
- Original evidence and installed app remain untouched; package `dev.quantavil.babytracker`.
- Empty default data; demo records require explicit action.
- No fabricated prediction, backend or subscription behavior.
- First milestone verifies source/tests without launching the clone.

## Review Focus
- Midnight intervals must count only the selected day's overlap.
- Failed persistence must not publish unsaved state.
- Paused timer must survive reload and exclude paused time.
- Large text/narrow screens must retain reachable controls.
- Corrupt storage must not be overwritten automatically.

### Task 1: Scaffold and persistent tracking model
Files: `pubspec.yaml`, `lib/model.dart`, `lib/storage.dart`, `lib/controller.dart`, `test/controller_test.dart`.
Interfaces: `TrackerController(TrackerStorage storage, {DateTime Function()? clock})`; `load()`, `saveEntry(ActivityEntry)`, `deleteEntry(String)`, `updateProfile(BabyProfile)`, `pause()`, `resume()`, `stop()`; immutable `entries`, `profile`, `active`, `error`; `totalForDay(DateTime)`.
- [x] Scaffold Android/Web app and asset declarations with official prebuilt Flutter SDK.
- [x] Write tests for CRUD/reload, rejected wake-ups/intervals, midnight totals, pause/reload/stop, settings reload, failed writes and corrupt state. Run tests and observe missing implementation failure.
- [x] Implement models/JSON storage/controller, rerun `flutter test test/controller_test.dart`; expected all pass.
- [x] Commit task and record verification.

### Task 2: Screens and local journeys
Files: `lib/main.dart`, `lib/app.dart`, `lib/ui/theme.dart`, `lib/ui/home.dart`, `lib/ui/dial.dart`, `lib/ui/history.dart`, `lib/ui/editor.dart`, `lib/ui/settings.dart`, `lib/ui/premium.dart`, `lib/ui/share.dart`, `test/app_test.dart`.
Interfaces: `BabyTrackerApp(controller: TrackerController)`; shared activity editor accepts optional existing entry, activity kind and controller; controller changes rebuild app views.
- [x] Write widget journeys for navigation, free log create/edit/delete, premium dismissal, settings change persistence and narrow/large-text layouts; run and observe missing implementation failure.
- [x] Implement observed screens/artwork, collecting-data state, schedule dial and forms; expected full tests pass.
- [x] Run `flutter analyze` and full `flutter test`; expected no issues and all tests pass. Commit task and record results.

### Task 3: Review and handoff
Files: `README.md`, `docs/verification.md`.
- [x] Fresh whole-project review of code/spec and five focus cases, fix material findings with reproducing tests.
- [x] Record actual commands/results and remaining parity gates; no claim of full-app parity or Android runtime verification.
- [x] Commit locally. Preserve source and evidence; no remote exists for this new project.
