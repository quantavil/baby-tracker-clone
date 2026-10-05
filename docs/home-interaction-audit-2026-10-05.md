# Home interaction and visual audit — October 5

This is a scoped audit of Home, anchors, summaries, Overview, and wake windows, not a complete-app parity certificate.

Original Baby Tracker 2.9.0 retained emulator `ditto2_play_x86_64`, 1080×2400, density 420. Read-only navigation: dismiss rating prompt, scroll Today, select retained Thursday, inspect wake-up summary, close without editing, scroll Thursday. No tracking records saved or deleted. Supplementary captures under ignored `evidence/research/2026-10-05/`: `original-overview.png`, `original-wake-summary.png`, `original-historical-overview-wake-windows.png`.

| Issue | Evidence / cause | Current status |
|---|---|---|
| Large rectangular wake/bedtime press highlight | Half-width Expanded InkWells; only hover was suppressed | Fixed: compact hit areas and transparent press/focus/hover feedback |
| Anchors detached from track endpoints | Icons placed by Row/bottom offset, painter used circle geometry; widget regression measured 37px error | Fixed against current track geometry at 320 and 412 widths; exact original dial geometry still needs matched screenshot measurement |
| Wake-up opens editor immediately | Original capture shows saved clock and Edit summary; clone callback called showEditor | Fixed: summary first, then Edit |
| Single-time events displayed as elapsed durations | Generic entry summary used c.elapsed and start–now text | Fixed for wake/bedtime: saved clock, no interval text |
| Overview has only two stacked cards | Original has two-column, four-card grid | Fixed structure and icons: Day/Night/Total sleep/Daytime awake |
| Empty Overview shows zero | Original Today shows dash plus Log today’s data | Fixed empty-state display |
| Overview heading includes date | Original uses Today / Thursday | Today corrected; historical weekday-only heading still open |
| Overview comparison captions missing | Original Thursday says Log previous day’s data under every card; training/comparison states exist in native code | Open: current recorded-data captions are provisional |
| Historical awake totals and night attribution differ | Original Thursday shows 8h19 awake, 12h48 night, 19h08 total; clone calendar-based mapping does not recover those logical intervals | Open. New awake card uses only bounded recorded wake→bed/current clock minus day sleep; historical missing end remains unknown |
| Entire Wake windows section absent | Original Thursday shows premium section; metadata includes _buildWakeWindows 0x8afb7c and WakeWindowTile 0x9cfc70 | Open. User requests free access, so implementing content is required; copying lock screen would not satisfy it |
| Wake-window status/range logic absent | _buildWakeWindows compares durations against two range fields; builds items plus current interval; _loadWakeWindowRange 0x8b02f8 | Open. Fields and unlocked layout need interpretation/runtime confirmation; raw native outputs retained |
| Date/day header scrolls away | Original retains pinned header during Overview scroll | Open: clone uses a single ListView |
| Night uses a different predicted bedtime | _NightSchedule defaults to 22:00 instead of DialScale prediction | Open: must unify day/night schedule state |
| Summary transition/background mismatch | Clone uses generic Material bottom-sheet transition and flat background; original wake summary has gradient and custom layout | Open beyond removing press highlight. No animation timing claim from still screenshots |
| Layered summary→editor sheets | Recorded summary opens editor on its own context, unlike predicted flow which closes summary first | Open: close/back behavior requires original journey comparison |
| Learning qualification, short/skipped/late nap correction | Existing evidence map documents approximation / missing prediction branches | Open; affects both numbers and rendered forecast |
| System bars, sizing, typography and spacing | Android original differs from browser; current dial placements only guarantee internal alignment | Open for matched Android clone comparison |

## Tests

Anchor regression failed with 37px offset before correction. Wake-summary regression failed due missing Edit summary. Four-card regression initially failed due missing Daytime awake. Existing conflict test expectation updated to reflect intentional dash-for-missing Overview semantics; its dial/history assertions remain.

Original screenshots demonstrate empty and historical Overview layouts and the wake-summary transition destination. They do not verify the original's unlocked premium layout or all animation frames. No claim of every app bug having been discovered.
