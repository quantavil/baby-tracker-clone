# Why the reconstruction still differs

Investigation: October 2, 2026. This is a code and archived APK investigation, not a claim of full runtime parity.

## Thursday is computed from a fixed fixture

`tool/parity_preview.dart` seeds October 1 with a wake-up, five completed naps of 80, 78, 76, 74 and 72 minutes. The optional `WITH_ACTIVE_NAP` define adds an unfinished nap; the default fixture contains completed naps only. The completed durations sum to 380 minutes, so the renderer displays 6 h 20 min and 5 times. The `/faithful/` route starts this isolated in-memory dataset on every reload. Other dates were not seeded with those completed records. The real app route `/` uses local persisted records instead.

The ring, labels and totals are calculated by `ScheduleDial`, `DialPainter`, `DialScale` and `TrackerController.totalForDay`. They are not a Thursday screenshot or date-specific layout. New tests reproduce the same completed total on October 1 and October 4; shortening a record by 20 minutes changes the displayed total to 6 h 0 min on both dates. This proves the rendering generalizes, not that the prediction engine matches the original.

## The central behavioral cause

The clone's `DialScale` receives only selected-day entries. It chooses an initial nap count from age/custom settings, distributes age-standard awake and sleep totals, and places subsequent predictions after the preceding entry. It has no prior-day history input. Therefore it cannot reproduce an original prediction that depends on previous tracked days, even when every icon and font is correct.

The original machine code contains a broader pipeline:

| Original evidence | Clone gap and consequence |
| --- | --- |
| `InitialScheduleBuilder.build` at 0x7fd8b4 calls data preparation, `NapCountPredictor.predict`, prior-day selection, `AwakeTimePrediction.getAwakeTime/getWakeWindows`, and `NapsTimePredictor.predict` | The clone implements the initial age baseline, not this complete historical schedule builder. |
| `NapCountPredictor.predict` at 0x801844 has a three-day branch and calls `SleepDataValidator.isUnrealisticNapData`, average nap count and extreme-count calculations | The clone always uses the initial count unless custom count is enabled. Learning from accumulated data is absent. Exact filtering predicates still need recovery. |
| `WindowsPredictor.getPredictedWindowsDependingOnAlgorithmType` at 0x7fe040 calls standard and previous-data branches; spline functions are present in the snapshot | The clone uses initial normalized weights. Presence of these functions alone does not establish every runtime algorithm selection rule. |
| `ScheduleBuilder.build` at 0x8030c4 invokes `PredictCorrection.trackNap`, `trackWakeWindow` and `trackLastWakeWindow`; `_correctPredict` invokes strategy selection and nap-count changes | The clone moves remaining slots after recorded entries without implementing this correction system. Short or late naps can produce different next-nap and bedtime predictions. |
| Micro-nap add/remove/last-window adjustment methods and skip-nap tracking logic are present | These journeys and their effects are missing. |
| `LogicalDayResolver.resolveLogicalDays` at 0x7cb0c4 and synthetic-anchor/night-reset methods are present | Clone day selection uses midnight-to-midnight intersections. Overnight records and missing anchors need matched-state validation. |

Raw disassembly is in local `evidence/docs/faithful-reconstruction/` and supplementary `evidence/research/`. Named calls and branches support the pipeline above; generic snapshot field decodes are not complete Dart source.

Other provisional behavior is explicit in current code: historical predicted bedtime defaults to 22:00; the learning banner counts calendar dates containing any nap, including ongoing naps. The banner is not driven by the original data-validity pipeline. The former missing-birthday age-nine fallback was corrected to the recovered age-zero rule on October 5; see `prediction-fix-2026-10-05.md`. The new hidden-session recovery card also changes layout and has not been recovered as an original screen element.

## Evidence and tooling limits

The original analyzer collection is partial: Apktool succeeded, JADX exited 3 with retained fallback output, and the MCP r2Flutter stage rejected the missing ARM64 library. Supplementary direct x86 extraction subsequently recovered metadata and selected machine code. This bypasses a tooling limitation for research; it does not produce the original Dart project or establish ABI equivalence.

Runtime collection retained 18 reviewed main-run screens and six targeted-run screens. Some Flutter state IDs collide across distinct screens, so screenshots and run context must be reviewed together. This is coverage evidence, not complete app exploration. Some original editors are premium-gated and their full layouts/behavior remain unobserved. The original account is cloud-synced; emulator snapshot rollback did not undo cloud writes, so future mutation experiments require disposable isolated/offline data.

The Ditto2 skill provides collection and review steps, not automatic implementation or parity certification. The process mistake was accepting a narrow matched fixture and passing clone-only tests as too much reassurance. Tests validate implemented behavior; they cannot validate omitted original behavior.

All 276 entries in the copied-asset inventory match both their recorded hashes and the relocated original files. Assets are being reused correctly for that inventory. Correct assets do not compensate for missing state transitions, prediction rules, onboarding, account/family sync, Android notifications/widgets or native sharing.

## What must happen to establish parity

Recover and validate the history/validity/logical-day inputs first, then historical nap counts and windows, then correction/micro-nap/skip transitions. Compare original and clone with identical profiles and records across empty, first-day, trained, short-nap, late-nap, skipped-nap and overnight states. Each comparison must include numerical predictions and transitions as well as screenshots. Complete the remaining tab/editor/onboarding journeys and native Android checks separately. Free access is the intended product difference; it does not excuse the other gaps.

## This pass verified

33,205 files were relocated with matching SHA-256 hashes; the two sibling Baby Tracker evidence directories are gone. Raw evidence is ignored and absent from the current Git index. Recovery helpers work from the consolidated paths and write new output separately from archived receipts. All 63 Flutter tests passed, including the two new cross-date/edit tests. Existing commits still contain previously tracked raw evidence; no history was rewritten or pushed.
