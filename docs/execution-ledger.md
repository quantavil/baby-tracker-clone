# Execution ledger

Ruling: User's explicit “yes build now” supplies implementation authorization and supersedes repeated skill approval handoffs. Proceed inline from the agreed evidence-backed core scope. Cost if wrong: scope changes may need revision.
Preflight: No existing clone or Flutter SDK found; system Dart exists. Install official prebuilt Flutter SDK under ~/.local/share, without system package/source builds. SDK manifest and checksum retained.
Task 1: complete — missing implementation tests observed RED; `flutter test test/controller_test.dart` GREEN 9/9. Immutable models, shared_preferences adapter, transactional publication and corruption gate implemented. SDK installed from verified prebuilt archive; generated scaffold only.
Ruling: New standalone directory is the isolation boundary; branch rebuild/core created instead of duplicating the empty project into a worktree. Cost if wrong: workspace layout may need relocation.
Task 2: complete — initial widget suite RED for missing app; first implemented run exposed Material/ink layering, large-text dial overflow and two test finder issues. Backdrop now paints through Ink; large text moves supporting copy outside the dial. Full suite `flutter test` GREEN 13/13; `flutter analyze` no issues.
Ruling: Compile a web bundle as an additional build check without launching the clone. This is not browser or Android parity acceptance. Cost if wrong: packaging may require later platform-specific changes.
Final review: fresh read-only reviewer inspected 438c530..30d0109 and spec; four findings, no Critical.
Final: regraded dropdown failure and paused dial from Minor to Important: both contradict the displayed persisted/elapsed state contract.
Final: fixed overlapping totals — overlapping completed naps count sleep once across midnight RED (45 vs30 minutes) → GREEN; total uses union of unpaused segments.
Final: fixed paused editor completion/date correction — paused nap can be completed from history editor RED (timer remains active) → GREEN; revised entries translate and clip pauses, close open pause at end.
Final: fixed unsaved nap-count display — failed nap-count save shows persisted value RED (3 visible despite stored2) → GREEN; controlled dropdown disables during save.
Final: fixed paused dial — real canvas-pixel test RED (paused segment lavender) → GREEN; renderer uses unpaused segments.
Final: full suite GREEN 19/19 after fix pass.
Ruling: Overlapping records remain editable; daily sleep counts their union instead of rejecting existing history. Cost if wrong: a later original-app merge rule could require different record handling.
Ruling: Changing an activity start translates pause timestamps by that difference and clips at the new end. Cost if wrong: users expecting original absolute pause timestamps may need a different editor policy.
Final: Ruling: Pixel parity, Android/back gestures, clipboard and real persistence durability deferred to runtime milestone — source/tests cannot establish these. Cost if wrong: device/browser defects remain possible.
Final: Ruling: Layout coverage is a narrow/large-text wake-up journey plus standard screen navigation, not every picker/keyboard/timer combination — keep runtime accessibility review open. Cost if wrong: an untested layout may overflow.
Final: Ruling: Predictions/nighttime derived totals/cloud/auth/premium/notifications/widgets/onboarding/image export are explicitly unavailable — do not invent their behavior. Cost if wrong: additional scope remains before full parity.
Final: Ruling: Timezone/clock rollback, cross-tab writes and crash/power-loss are not runtime-verified — local timestamps and single-controller persistence are provisional. Cost if wrong: later tests may require migrations/locking/recovery.
Final: Ruling: Release signing/store identity deferred — independent dev package, no distribution release. Cost if wrong: packaging/signing work remains.
Final: minor (deferred): Optional demo insertion may partly succeed on a storage failure and its final snackbar can still point to yesterday; real tracking save failures remain protected.
Final: Ruling: History shows the full activity duration on each intersected date while day summaries clip to the day — records describe whole intervals. Cost if wrong: display labels may need clarification.
Task 3: complete — reviewer findings addressed with RED→GREEN coverage; final full suite 19/19, analysis clean, web compilation successful and all 240 asset hashes verified. Source/tests and build artifacts ready; runtime/parity gates remain in docs/verification.md.
Ruling: Keep the new repository on rebuild/core with local commits; no remote exists and no new GitHub repository was requested. Cost if wrong: remote creation/push remains outstanding.

## 2026-10-02 — free trackers and comparison fixes

User authorized fixing differences and making every delivered feature free. Removed gates/premium route; added persisted nursing/bottle/solids/diaper details, independent nursing timer, unit conversion, night sleep derivation and computed seven-day statistics. Used authentic backgrounds/buttons/icons; corrected editor/settings/navigation/dial layout and web share export. No original algorithm was invented or claimed recovered.

Final fresh reviewer: no Critical finding; Share legend and Stats chart had Important overflow issues at 320 × 900/text scale 2. Reproduced both, replaced legend Row with Wrap and sized/fitted chart labels; retained regression tests. Final analysis clean, 29 tests pass, real/fixture web builds succeed. Asset check: 276 copies, zero hash mismatches. Updated audit retains 22 clone views, reference provenance and downloaded PNG.

Perfect parity remains open: predictions/progress, exact geometry, absent unlocked editor references, onboarding/cloud and native integrations. Original x86 delivery and session remain untouched; matching ARM64 remains unavailable. Browser fixture uses isolated memory. No Android build, public deployment or remote push was possible; repository has no remote. Temporary loopback servers restarted as detached Python processes (8765 real/fixture, 8766 historical audit with `/updated/` link).
