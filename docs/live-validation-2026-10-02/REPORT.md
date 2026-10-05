# Live original-app validation — October 2, 2026

Raw captures and analysis receipts for this report are local and Git-ignored under `evidence/docs/live-validation-2026-10-02/`.


This pass corrected observed Home/navigation differences and defects in the newly added backup workflow. Full visual and behavioral parity is **not established**.

## Reference and collection

- Visible `ditto2_play_x86_64`, emulator-5556, Android 14, 1080×2400 at 420 dpi.
- Original package `com.baby.sleep.tracker.feeding.diaper.free`, 2.9.0 / 20209000, x86_64. All three installed APK hashes match the archived complete Play delivery (see installed-delivery.json).
- Thirteen supplementary screenshots are retained under original/ with source paths and SHA-256 in capture-source.json. These came from manual navigation using the mobile-control preview and adb screenshots. They are **not** eligible recorded graph checkpoints and do not add fabricated graph transitions.
- Package-bound recorder setup could not handle the base-only Play split input; an attempted base install failed with missing splits. The installed package was retained, byte-verified, and inspected using preview mode.
- No original tracking entries were saved/deleted, no app storage reset, and no purchase/account operation performed. The custom-nap toggle briefly enabled during picker inspection; after Cancel left it enabled, it was explicitly restored off and verified. Original returned to Today in Day mode.

## Findings and implemented corrections

| Live observation or defect | Correction |
| --- | --- |
| Today without a wake-up shows the sun, explanation, and Start day; tapping opens a wake-up editor rather than starting a nap | Added that flow, original sun asset, and dark open arc |
| The retained previous-day unfinished nap does not become today's displayed timer | Today's dial only displays a timer started on that date |
| Yesterday shows completed Day sleep and Naps logged (original fixture: 6 h 20 min, five completed naps) | Past-day dial summary excludes running naps; no running nap icons/segments on past-day dial |
| Tapping the 13:03–14:19 nap shows a 1 h 16 min summary with Edit | Added a summary before the editable form; closing the editor returns to the summary |
| Original has Day/Night modes and an empty Night sleep / Night wakings summary | Added switch, dark night background, empty night summary, bedtime preview and log form |
| Original night bedtime preview showed 10:00 PM, then Log bedtime opened the editor prefilled with that date/time | Added the observed default preview journey; this default does not establish a prediction algorithm |
| Backup accepted duplicate IDs / multiple simultaneous sleep timers that later failed loading | Reject before writing; validate profile/entries and normalize descending order |
| Valid restore was blocked when saved data was corrupt | Allow a validated restore, clear the error only after successful persistence, and expose restore from the error screen |
| Failed Reset could still display a success message | Show success only after a successful write |
| Awake-for display froze after stopping a nap because refresh depended on active timers | Home now refreshes even while awake |
| Past-day unlogged schedule anchors opened today in the editor | Preserve selected day and displayed bedtime when opening the form |
| Seventh and later logged naps lost their dial target | Keep a summary/edit target for every logged nap |
| Future suggested timestamps were silently changed to now by editor initialization | Keep the suggested value visible and disable Save through existing future-time validation |

The existing user edits were retained. The changed overnight widget-test fixture now uses a same-day running nap to check past-date navigation; the newly observed previous-day case has its own regression test.

## Verification

- Full Dart analysis: no issues.
- Full Flutter test suite: **48 tests passed**, including 14 live-parity/recovery regressions. Targeted regressions were run failing before their fixes; complete results are in tests.txt.
- Release Flutter Web bundle rebuilt and served by the existing loopback preview service on port 8765; HTTP 200 checked.
- Interactive Flutter Web hot reload succeeded repeatedly (observed 193–696 ms); an open wake-up editor and an open bedtime preview remained intact. Browser checked Start day → wake-up form, Day → Night → bedtime preview, and logged nap → summary → Edit. No writes were made to the real browser profile during these checks. Fixture at port 8771 uses memory storage.
- All 276 copied assets match their original source hashes (asset-check.json).
- No Android clone APK build or Android clone hot reload was performed; only the original APK ran on Android. The installed SDK still lacks Android platform packages.

## Remaining evidence and parity gaps

- The added age-based nap targets, fixed 70-minute sleep target, wake windows and 14 h 58 min bedtime offset are approximations, not recovered original algorithms. The fixture still shows 1 h 4 min oversleep versus the earlier original's 1 h 5 min. Personalized/entitled predictions need additional controlled evidence.
- Night view currently uses calendar-day night totals from the existing controller; original bedtime-to-next-wake grouping, midnight transitions, active night controls and rendered waking segments are not validated.
- Exact arc/anchor positions, typography, gradients, spacing, summary delete-button placement and missing-data overview presentation remain visually different. No pixel-perfect score is claimed.
- Original premium feeding/diaper journeys remain gated. The clone's versions are intentionally free; their original detailed forms still need entitled evidence.
- Original activity-menu rows were disabled in the retained session, including Night waking. Taps did not open that editor; this was captured as activity-menu-disabled.png, not mislabeled as a successful editor capture. Existing earlier targeted Night waking evidence remains separate.
- Full onboarding, cloud sync, native widgets, notification delivery, native export/share and system-back semantics remain outside this verified pass.
- A matching ARM64 release is still unavailable; no new AOT algorithm recovery is claimed.

## Independent review

The reviewer found two Important defects (frozen awake clock and past-day anchors saving today) and one Minor defect (six-nap marker cap). All three were reproduced by failing tests and fixed; read-only recheck found no new Critical or Important issue in the reviewed changes. Prediction/night/native evidence limitations remain.
