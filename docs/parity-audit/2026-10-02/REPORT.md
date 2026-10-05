# Free reconstruction validation — 2026-10-02

Raw captures and analysis receipts for this report are local and Git-ignored under `evidence/docs/parity-audit/2026-10-02/`.


**Full visual and feature parity has not passed.** This update fixes the initial payment gates, promotional Stats and several large visual differences. Removing payment is an intentional product change. It does not exempt predictions, cloud/native features or unrelated appearance differences from acceptance.

## Verified implementation

- All eight trackers open and save without entitlement checks: wake-up, nap, bedtime, night waking, nursing, bottle, solids and diaper. Nursing side/duration, bottle type/amount, food/amount and diaper type survive reload. Existing records remain readable.
- Nursing and sleep can run together; stopping nursing preserves active sleep. Sleep pause intervals, overlapping intervals and midnight boundaries are covered by tests. Night sleep is independently derived from bedtime until the next wake-up, subtracting night wakings.
- Bottle/solids units convert to stored ml/g; editing a note preserves the stored amount. Positive finite amount validation rejects invalid input.
- Stats computes seven-day recorded totals/averages. Missing days count as zero. This replaces the original promotional screen; original analytics semantics remain unverified.
- Original backgrounds, stars, tracking illustrations, button artwork and dial outline icons are used. Rounded editor controls, row spacing, navigation and desktop phone-width layout were corrected. There are still visual differences.
- Share saves an actual web PNG; downloaded file `exported-share.png` is 1116 × 2043 RGBA. Copy summary is implemented. Original store QR and native sharing are not reproduced.

## Evidence and checks

Original: Baby Tracker 2.9.0 / 20209000, complete Play x86_64 split delivery. Main runtime review contains 18 screens/37 reviewed actions; targeted run contains 6 screens/9 actions. Raw graph state IDs collide on some Flutter routes; screenshot paths and run context are authoritative. Source report: `/home/quantavil/Documents/baby-tracker-clone/evidence/original-analysis/REPORT.md`.

JADX output is partial (9,326 errors plus fallback); Apktool extraction succeeded. Matching ARM64 delivery is unavailable, so the original prediction implementation has not been recovered. Native strings and semantic keys are clues, not reconstructed code.

`asset-verification.json` verifies all 276 copied assets against their source with zero mismatches. `capture-source.json` identifies the 17 paired reference captures. This does not mean every extracted asset or source clue is implemented. The gallery contains 22 updated clone views. Four unlocked feeding/diaper editor references are absent; their forms are independent implementations. The time picker has runtime evidence but no paired reference in this gallery.

Comparison fixture: `tool/parity_preview.dart`, in-memory storage, fixed October 1 22:08:15, Leo/October 1 birth date, 7:20 wake-up, five closed naps and an ongoing nap. Visible nap minutes are transcribed from captures; seconds are reconstructed. The fixture does not alter the user's real local profile. Original prediction state is deliberately not fabricated.

Fresh final verification: Flutter analysis reports no issues; all **29 tests pass**; real and fixture web builds succeed. Tests cover persistence/failure handling, all free editors, amounts, simultaneous timers, real aggregates, past-day active state and 320 px/large-text layouts. Final reviewer found no Critical issue; two Important responsive overflows in Share/Stats were reproduced, fixed and regression-tested. Browser captures verify navigation and the downloaded PNG. Passing these checks is not full parity acceptance.

## Remaining defects and acceptance work

| Area | Status |
|---|---|
| Predicted bedtime/nap windows, oversleep logic, learning progress ring | Missing; original algorithm unavailable |
| Exact dial geometry, screen spacing/typography and animations | Improved; exact visual parity remains open |
| Original unlocked nursing/bottle/solids/diaper layouts | No authoritative capture; implemented independently |
| Onboarding, account/cloud sync, backup/conflict handling | Incomplete |
| Android notification delivery, widgets, native share/feedback | Incomplete; local preferences/help do not deliver these integrations |
| Android APK, OS back navigation, keyboard layouts and device persistence | Not verified; Android platform SDK not installed |
| Parallel tabs, clock/timezone changes, crash recovery | Not verified |

No numerical parity score is claimed. The original session/data, APKs and evidence were preserved. Local preview is `http://127.0.0.1:8765/`; comparison is `http://127.0.0.1:8766/updated/`. Repository has no remote, so this source can only be committed locally until a destination exists.
