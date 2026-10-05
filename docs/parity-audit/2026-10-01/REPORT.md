# Evidence, asset and parity audit — 2026-10-01

Raw captures and analysis receipts for this report are local and Git-ignored under `evidence/docs/parity-audit/2026-10-01/`.


**Verdict: the current clone fails full feature and visual parity, and fails the newly requested all-features-free target.** This audit separates intended removal of payment flows from missing functionality and unrelated appearance differences.

## What was actually validated

Viewed the live localhost build at a temporary 412×864 browser viewport: Home, History, Stats, Settings, regional preferences, time-format choices, activity menu, Nap editor, time picker and share preview. Ten clone screenshots are retained here. Compared them qualitatively with the reviewed original Android captures; nine original/clone pairs are in `index.html`. No logs/preferences/purchases were saved, no clipboard/export operation was invoked, and the initial Stats view/date selection and browser viewport were restored. Browser error/warning retrieval returned no entries during this inspection.

Different app data, Android system bars, and browser device density mean these screenshots are not exact aligned fixtures. There is **no numerical pixel-parity score**. Empty clone Home/History cannot be compared pixel-for-pixel to the original's populated live timer/history. Obvious composition/control differences are still directly observable.

## Assets: authentic copies, incomplete/correctness-limited use

All **240 copied files** and their original source files match the recorded SHA256. Fixed asset references resolve; expanding the known dynamic icon/header/settings/navigation families plus declared fonts yields **43 potential base-resource paths**, all present. Resolution variants account for many copied files. These counts are not runtime usage or feature coverage. Four premium editor header paths are potentially resolvable but their routes are blocked.

The source inventory has 317 files, including manifests, fonts, artwork, animations and resolution variants. Copying every file or using every illustration is not an acceptance requirement; using the right resource in the right observed place is. RobotoFlex and SourceSerif4 are actually selected by the theme; SFPro is declared but not selected by any current TextStyle. That alone does not prove wrong typography; exact original family selection per component has not been established.

Concrete misuse/omissions:

- `lib/ui/history.dart:27` invokes `PremiumBanner`; `lib/ui/premium.dart` chooses `tracking/headers/nap.webp` for its History promotion. The original History promotion shows a different baby/cradle composition. The Nap editor's teddy illustration is authentic but reused in the wrong slot.
- `lib/ui/theme.dart:70` applies `background_night.webp` across screens. The copied `tabs/home/app_bar_background.webp` and other top/header composition assets are unused. The current Settings/Home headers are visibly darker and flatter than the original.
- `lib/ui/settings.dart:127` renders settings images without a tint/contrast adjustment. Several icons are almost black on the dark browser background. Original captured icons are light. Density/resolution selection needs investigation before choosing the exact correction.
- `lib/ui/editor.dart` uses the literal `▶` in button text, which the browser renders as a colored emoji in the captured Nap button; the original uses a white play affordance.
- `lib/ui/dial.dart` uses a generic 24-hour arc with numeric ticks. Original wake/bedtime anchors, activity icons, segment treatment, prediction windows and learning progress composition are not faithfully rebuilt.
- The share card lacks original age display, legend, QR/branding composition and image Save/Share behavior despite relevant captured evidence/assets.

## Evidence consumption: partial, now traceable

The first implementation used the collected report, core screenshots, fields and selected original assets. It did **not** translate all collected evidence into a complete app. No comprehensive per-feature acceptance trace existed in the initial build. `evidence-coverage.json` now maps every one of the main review's 18 raw screenshots (including the external Android launcher) to an implementation/status and preserves the original screenshot hash/path. Additional targeted-run, semantic-key, native path, component and asset inventories are listed as sources.

Original IDs are scoped to their raw run: Nap/Night-waking and date/time wheel collisions remain known. Screenshot paths/context are used instead of treating a state ID as a unique semantic screen. Historical curated graphs are not asserted as verified raw journeys. Existing raw evidence and its review index remain unchanged. In particular, the old collection's “no rebuilt source project” gap is historical; the clone now exists, but full parity remains unverified.

Runtime evidence establishes core forms and gates. The 850 Dart package paths, semantic keys and native component inventory help identify missing features; they do not recover algorithms, field layouts, backend contracts or implementations. Nursing, bottle, solids, diaper and full Stats editor/chart behavior are still not observed in an entitled original session. Their type/editor names and artwork provide partial clues only.

## Feature findings and free-access requirement

| Area | Current status | Acceptance under the updated target |
|---|---|---|
| Wake-up, Nap, Bedtime, Night waking | Basic local editors implemented | Retain all four, calibrate observed layout; verify original edge rules and Android behavior |
| Nursing, Bottle, Solids, Diaper | Menu rows open paywall; controller explicitly rejects these kinds | All four must have functioning free editors, storage, history, edit/delete and appropriate units/types |
| Stats | Promotional image; no real statistics | Replace promo with statistics computed from actual logs; no locked charts or copied promotional sample averages |
| Predictions/wake windows | Collecting-data message; no algorithm | Implement an explicit evidence-informed algorithm and test it; exact-original equivalence remains unknown until more evidence |
| Sleep preferences | Toggles/count/time saved only | Preferences must influence the implemented schedule, not merely persist |
| Home/History | Working local navigation/records; major visual simplifications | Match unchanged layout/components with controlled fixtures; remove upsell-only composition intentionally |
| Regional settings | Time format works; units stored | Amount conversion must work in the free feeding editors |
| Notifications/widgets | Preference only; widgets absent | Actual Android scheduling/widgets required if claiming these original features are delivered free |
| Sharing | Local preview and copy summary | Add real image Save/Share; match observed card fields/composition except any intentional branding change |
| Account/cloud/backup/onboarding | Not implemented | Free access does not justify omitting unrelated features; retain as open feature work |
| Paywalls/prices/trials/locks | Still present as placeholders | Intentionally remove from the target; purchase parity is not required |

Removing only a lock or setting `premium=false` would not deliver the premium features: `ActivityEntry` has no specialized feeding/breast/amount/diaper fields, and Stats has no calculation/chart model. These require real implementations and tests. Do not label them complete after merely removing a gate.

## Important defects vs intentional differences

Intentional: no subscription, payment, trial, entitlement checks, upgrade pressure or locked capabilities in our own app. All formerly paid features should be reachable and functional for free.

Not intentional: wrong illustration placement, poor icon contrast, generic dial, inaccurate spacing/button composition, missing predictions/statistics/feeding models, fake notifications, missing export/cloud/native flows. The free-access decision does not excuse these gaps. Match common screens and journeys; compare formerly gated functionality against available feature evidence, recording unresolved areas honestly.

The main add button is also unnamed in the live browser accessibility tree. It needs a useful accessibility label; broad picker/keyboard/large-text and platform checks remain open beyond the current tests.

## Checks and next implementation order

Existing controller/widget/render tests establish local CRUD, save-failure protection, pause edits, overlapping sleep accounting and one narrow/large-text journey. They do not establish original-app equivalence, real OS storage durability, full accessibility or whole-app functionality. Current analyzer status remains partial JADX and missing matching ARM64 analysis.

1. Implement the four formerly gated tracking models/forms and real free statistics; remove all payment/lock/upsell routes after functionality exists.
2. Correct common-screen visual composition using the right assets and explicit same-data/same-size fixtures; add meaningful screenshots/checkpoints for unchanged surfaces.
3. Implement/test schedule predictions and preferences, image export, onboarding/data-management, then Android notifications/widgets and relevant platform behavior. Keep uncertain algorithms/backend contracts explicit.

Current product code was not changed by this audit. The free-feature requirement is recorded in `docs/free-feature-policy.md`; present paywalls are known failures against it. Screenshots, asset hashes and the coverage matrix are retained for review.

Fresh recheck after the audit: `flutter test` passed all 19 tests; `dart analyze` reported no issues. Those tests still include the old premium rejection/gate behavior, so passing them is explicitly **not** acceptance of the new free-feature policy.
