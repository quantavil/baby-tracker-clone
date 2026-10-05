# Faithful reconstruction checkpoint

Raw captures and analysis receipts for this report are local and Git-ignored under `evidence/docs/faithful-reconstruction/`.


The full clone remains incomplete. Free access is the intended difference from the original; missing behavior or different screens are parity gaps.

## Static evidence

Direct r2Flutter 0.3.6 extraction works on the supplied x86_64 libapp.so for snapshot headers, 36,247 function records, classes and selected object-pool values. The Ditto2 MCP's ARM64 guard previously prevented this supplementary extraction. This does not establish ABI equivalence or recover complete Dart source. The original collection's unsupported ARM64 result has been preserved.

`provenance.json` identifies the binary and extraction. `tool/recovery/disassemble.py` maps direct x86 calls to extracted function names. `tool/recovery/pool.py` preserves raw decodes. Function/closure instance fields returned by the generic decoder must not be trusted as reconstructed source fields; decoded standard arrays were corroborated with their consuming machine code.

Implemented initial rules:

- Sleep standards: `pool-pp_0x8368.json`, consumed as the list at `[r15+0x8367]` (0x7cc4a5 / 0x7cc4ec); getSleepStandards at 0x7cc434 interpolates neighboring age rows, clamping beyond endpoints. SleepStandard.merge and DurationStandard.merge confirm linear interpolation. All three duration ranges are preserved in the raw receipt; baseline averages suffice for the initial schedule. The neighboring `[r15+0x836f]` is a closure operand, not this array.
- Initial nap counts: `pool-pp_0x8488.json`; findRangeForAge at 0x802210 selects the last age threshold <= age, otherwise first. NapCountPredictor.predict at 0x801844 uses the range maximum with fewer than three historical days, unless custom count is enabled.
- AgeCalculator at 0x65c230 uses whole days / 30, floored to zero; 0x65c1ec caps at 24 months. This replaced the provisional calendar-month bucket.
- WindowsPredictor at 0x7ffe58 generates weights `total * (1 + i / (max(count,3) * (max(count,3)-1)))`, normalizes to total at 0x7fecb0, and reverses nap durations. One window returns the total directly (0x7fe158). Its validator logs out-of-range windows; it does not clamp them.
- Duration conversion at 0x7cca6c truncates minutes * 60,000,000 to microseconds (`pool-pp_0x85d0.json`).

The previous hardcoded newborn `[60,62,63,65,66,68]` and nap `[80,78,76,73,71,68]` arrays were removed. `runtime-trace.json` explains why sequential saved-editor timings cannot be asserted as an initial untouched schedule. The recovered baseline matches the first prediction and its total; it does not yet reproduce every subsequent corrected prediction.

## Runtime/UI changes

The past-day Home now uses the weekday/date, completed totals, full-width dial, markers positioned on the dial, tangent captions, original share asset and learning mascot. It hides future slots on past days. Day/Night has separate rounded selection outlines. Today shows Nap starts in / Late for nap above the secondary awake duration. Active nap targets use their predicted duration instead of a fixed 70 minutes.

Predicted nap and bedtime taps open summaries before the prefilled log editor. Summary content scrolls on small screens. Future timestamps remain protected from being silently recorded as now. All eight local trackers remain free.

`clone-past-home.png` is a 412×842 browser capture with memory fixture data. The original runtime PNG includes Android status/navigation bars. No pixel-exact score is claimed. The pre-cleanup runtime screenshot has learning progress 2/3 because temporary October 2 logs were still synced; the final cloud-clean capture and memory fixture show the retained baseline.

## Remaining full-app work

| Area | Remaining evidence / implementation |
| --- | --- |
| Prediction | History validity filtering, averaging, wake-window spline, correction strategies, micro-naps, skipped naps, logical-day boundaries and training progress |
| Nap journeys | Missed-nap prompt, skip confirmation/persistence/rescheduling; summary deletion and end-time removal now implemented, with further original visual/transition comparison remaining |
| Onboarding | Welcome/name/birthday/reminder screens captured; clone onboarding absent. Original account screen did not expose footer actions during capture |
| Main tabs/editors | Further matched-state visual checks across History, Stats, Settings and all eight editor types; premium-gated original editors need entitled runtime evidence |
| Accounts/sharing | Original cloud account, family sync and invitation behavior unavailable; local backup is not cloud parity |
| Android | Clone APK build/device verification, notifications, widgets and native share unresolved |

## Original state restoration

`faithful-before-tests` restored temporary October 2 records but retained the test-completed October 1 sixth nap. Its summary confirmed 19:53–20:53. The observed Not finished action and Delete end time confirmation reverted that temporary end time. The original Home then showed 6 h 20 min / 5 times again. A new `faithful-original-restored` snapshot was saved. `original/restored-original.png` records this check. The emulator remains running; control ownership was released.

A follow-up Today check detected the six temporary October 2 records had returned through the original app's sync. Snapshot restoration alone was insufficient. Those exact test-created records (wake 08:00; five naps listed in `runtime-trace.json`) were removed through the app's summary Delete entry flow, verifying each start/end time first. Original October 1 records were preserved. Restart verification showed Today "Start day" and October 1 "6 h 20 min" / "5 times". `original/cleaned-today.png`, `original/cloud-clean-past-home.png` and the final `faithful-original-clean` snapshot document this cleanup. Earlier restored snapshots are not reliable cloud rollback points. Future experiments require a disposable isolated fixture or offline session.

## Checkpoint verification

- 59 tests passed; Flutter analysis has no issues.
- Release and comparison fixture web builds passed.
- Original-state cleanup was checked after restarting the original.
- Both debug previews hot-reloaded; browser confirmed prediction summary → Log bedtime → selected-date/time editor without saving fixture changes.
- Stable release: http://127.0.0.1:8765/ . Memory comparison fixture: http://127.0.0.1:8765/faithful/ (select Thursday).
- No Git remote is configured; pushing is unavailable. Full reconstruction remains open.

Existing clone profiles without a birthday retain a two-nap fallback (age 9), a compatibility decision rather than recovered original onboarding behavior. New-profile onboarding remains unfinished.


## Hidden timer and marker hover correction (2026-10-02)

An unfinished October 1 nap remained globally active while the selected-day dial hid it. Starting another unfinished sleep record therefore failed with "Stop the current timer before starting another". Home now exposes a compact live timer with Pause/Resume and Stop controls whenever the day dial cannot show that session, including previous-day sessions and the Night view. Historical completed summaries and Today Start day remain unchanged. This recovery card is a functional correction, not a claim that its layout was recovered from the original APK. No original or persisted user records were reset.

The memory comparison fixture uses a Stopwatch offset from its reference date so timers advance. Reloading this isolated fixture still recreates its reference data. Wake-up and predicted bedtime anchors retain their tap actions but have transparent pointer hover fills to eliminate the large rectangular desktop highlight.

Verification: 61 tests passed, clean Flutter analysis, release and faithful fixture web builds passed. Browser checks stopped the formerly hidden timer, started a new nap without the blocking message, and observed it advance from 00:00:00 to 00:01:16. Hovering Wake-up showed no rectangular fill. Evidence: `running-timer-fixed.png`, `new-timer-fixed.png`, `marker-hover-fixed.png`. Both stable localhost paths returned the updated bundles. Debug recompilation succeeded, but no client was connected for hot-reload verification in this pass. No Git remote is configured.
