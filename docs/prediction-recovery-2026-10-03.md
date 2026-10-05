# Supplementary prediction recovery — October 3

Input: Baby Tracker 2.9.0 / 20209000, x86_64 `libapp.so`, SHA-256 `b059afe4660a2d72ab70ec6745d2d830a3b0473f1631a21d869ec2579dac81be`. Analysis: installed r2Flutter 0.3.6 metadata/object decoder and GNU objdump, using existing recovery helpers. This is supplementary analysis, not the missing primary ARM64 collection. New raw outputs are ignored under `evidence/research/`; prior raw exports remain retained.

## Object-pool addressing correction

Instruction `[r15+0xc8f7]` corresponds to decoder `pp+0xc8f8`, whose receipt reports `pool_offset=0xc8f7`. `pp+0xc8f0` selects the preceding slot. Passing the unaligned displacement directly is unresolved in the installed decoder. `tool/recovery/pool.py` now accepts the actual `r15+...` operand, applies the one-byte adjustment for this x86 snapshot, and requires a resolved receipt with exactly the requested instruction displacement. Existing raw receipts are reused rather than overwritten. This convention must not be generalized to a different architecture/profile without checking its decoder.

The ready-state return at 0x80cd02 consumes `[r15+0xc8f7]`: the correct decode is a `DataAccumulationBannerState` holding ready / 3. The collecting-stage assignment at 0x80cd2e consumes `[r15+0xc8ff]`: `pp+0xc900` decodes collecting. Generic field decodes alone are insufficient; the constructor stores and branch consumption corroborate these two meanings.

The previously used sleep-standards receipt `pp+0x8368` is correctly linked to the list operand `[r15+0x8367]` at 0x7cc4a5 and 0x7cc4ec, not the closure operand `[r15+0x836f]` at 0x7cc4d4. The standards were not replaced: the error was the documented instruction association. Similarly, night reset adds the duration at `[r15+0x899f]` (`pp+0x89a0`, 4 h) and caps against `[r15+0x89a7]` (`pp+0x89a8`, 17 h). The preceding slot contains a 22:00 TimeOfDay, demonstrating why neighboring-slot guesses are unsafe.

## Learning progress

Read caller 0x8af5a4 `HomeTabCubit._buildDataAccumulationBannerState`, resolver 0x8af6f0 `_resolveCloudMainForDaysBefore`, factory 0x80caf4 `DataAccumulationBannerState.fromTrackedDays`, and mapper 0x7ce338 `_buildFromBoundaries`.

- The caller loops integer offsets 0 through 29 (`cmp rcx,0x1e` at 0x8af5df), resolves each against AppClock.now, appends non-null logical days and evaluates the factory. It stops early when the stage is ready.
- The factory skips synthetic days' anchor, requires a non-null anchor field and a nonempty interval collection, then deduplicates by the day identity at +0x7. The mapper establishes those field stores; the complete interval-type dispatch and logical-day resolver remain unresolved.
- Three or more qualifying identities return ready / 3; fewer return collecting / max(1, count). A selected historical tab date is not the time source for this scan.

Implemented the bounded correction in `TrackerController.learningDays`: restrict the existing calendar-date nap grouping to today and the previous 29 dates; use one result for the banner text, fraction and progress arc. The former code counted all historical nap dates. A widget regression includes offsets 0, 29, 30, 31 and 60, selects a historical display date, and expects 2/3. It fails with the old counting behavior and passes after the fix.

This implementation deliberately retains a documented approximation: calendar nap grouping is not the original logical-day qualification. In particular, explicit/synthetic wake anchors, overlap attribution and DST-sensitive resolution still need implementation and matched original experiments. The ready-stage layout and exact localized copy also remain open. The test establishes the bounded static-derived correction, not full learning-progress parity.

## Adaptive nap count: traced, not implemented

Read `NapCountPredictor.predict` at 0x801844, `_filterTrackedData` at 0x801b94 and `_getAverageNapCount` at 0x801eec. Relevant branches now identified:

- Custom setting fields can return a supplied count, falling back to the age range maximum. Their field identities still need model corroboration.
- Fewer than three supplied history items return the range maximum. Otherwise a mapped history enters `SleepDataValidator.isUnrealisticNapData`; its boolean branch returns the maximum on one path. Do not infer that path solely from the validator's name.
- The next branch compares whole elapsed days since a history date to three and uses `min(history count, range maximum)` on the >=3 path. The indirect selector at dispatch offset 0x62da0 remains unresolved, so that date/count cannot yet be named first or latest.
- When a selected count is inside the age bounds, averaging takes three items, or five when history length exceeds four. Out-of-range counts enter an extremes helper; magnitude >=3 can produce maximum+1 or minimum-1. This confirms that a generic clamp to the age range would discard original behavior.
- The filter uses a captured closure at pool operand 0x8467; averaging uses a fold closure at 0x846f and a native floating-point call via thread offset 0x728. Closure predicates, fold semantics, ordering and rounding are not fully recovered. No adaptive-count code was added from these incomplete interpretations.

Next: resolve those closures/dispatch targets and the input model, trace validity and extremes helpers, then compare matched original histories. Also trace awake/nap duration predictors, spline and correction strategies before claiming next-nap or bedtime parity. Missing ARM64 remains a primary-analysis gap; repeated unsupported analysis runs would add no evidence.

## Validation

65 Flutter tests pass; analysis reports no issues. Both real and memory-fixture release web builds succeeded. The lookup helper accepted the correct operand, rejected an unaligned operand, and preserved the existing receipt hash. The binary hash matches the recorded input. The fixture route returned HTTP 200 and loaded in the browser; Thursday retained 6 h 20 min / 5 and the 1/3 banner. Capture: `evidence/research/2026-10-03/learning-window-preview.png`. This capture confirms the retained fixture only; the 30-day boundary is checked by the static-derived regression. No original account mutation, new Android verification or hot-reload verification occurred in this pass.
