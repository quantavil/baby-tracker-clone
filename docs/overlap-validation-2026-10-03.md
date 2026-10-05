# Overnight conflict repair — October 3, 2026

## Reproduced cause

The browser's Friday screenshot was caused by a completed nap from Thursday 19:53 to Friday 19:49, spanning the Friday wake-up at 08:49. The clone accepted the contradiction and used the nap as a Friday schedule input. The large solid arc and zero awake time followed from those records. This is distinct from the unresolved original logical-day resolver.

## Original evidence and implementation

The retained `wake-overlap.png` shows the original **Overlapping Activity** dialog and its **Discard activity** / **Edit time** actions. The original `SingleEditorCubit.validateSavingData` calls `TrackingMergeValidator.validateSingle`, which reaches `BackupMergeHelper.validateWakeUpCloudData` (0x91e1cc). It invokes `_hasDateTimeOverlapIntervalData` (0x91ded4) twice against typed collections. The supplementary x86 object-pool decoder leaves those type arguments opaque. This supports the runtime-observed conflict; it does not establish all tracking types or endpoint semantics.

The clone now rejects saving a wake-up strictly inside a nap and rejects the reciprocal nap edit before writing storage. Edit time retains the draft; Discard activity closes the draft without changing existing records. New overlap validation is not claimed as the complete original validator. The helper compares its point against both interval endpoints, but the indirect dispatch and exact input collection types still need corroboration before changing endpoint rules.

Existing contradictory records remain in History and exported data. The day schedule excludes those naps from arcs, counts, totals and the awake origin. Home offers a direct edit link. This legacy recovery link is an intentional repair affordance, not a recovered original screen element. Raw History/Stats totals retain their records until repaired.

The original nap editor screenshot has a trash control beside End. The clone now uses that control and a Delete end time confirmation instead of immediately clearing the end. Clearing is a draft change until Save; failed saves preserve stored records. The original cleanup narrative also records its Not finished/Delete end time flow; exact confirmation appearance remains unverified.

The default comparison fixture no longer includes an invisible ongoing nap. `WITH_ACTIVE_NAP=true` enables the timer fixture explicitly; `OVERLAP_CASE=true` imports the old contradictory state for regression checks. This does not delete persisted user data.

## Validation

- All 70 Flutter tests passed, including the past-day total consistency assertion; Flutter analysis reported no issues.
- Regression coverage: wake/nap reciprocal saves, failed storage changes, original dialog edit/discard transitions, legacy dial filtering, confirmed draft end removal and persisted unfinished timer.
- Browser regression on port 8771: giant solid arc absent; repair link opens retained Thursday 19:53–Friday 19:49 record; end-time cancellation retains 19:49; editor survives hot reload.
- Browser receipts are ignored under `evidence/research/2026-10-03/`: `friday-overlap-repaired.png` and `end-time-control.png`.
- Updated release and faithful-fixture bundles are served by the existing loopback preview service on port 8765. No public deployment or original account mutation.

## Remaining replica gaps

Historical adaptive predictions, validity filtering, logical-day resolution, short/late/skip/micro-nap correction, onboarding, complete matched-state editor/tab checks, account/family sync and Android notifications/widgets/share remain incomplete. Existing x86 recovery is supplementary; matching ARM64 input is still unavailable. All local trackers are free, as requested. These fixes do not establish full-app parity.
