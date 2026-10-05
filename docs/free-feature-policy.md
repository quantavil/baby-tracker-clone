# Updated product requirement — every feature is free

User instruction on 2026-10-01: provide all features for free and validate evidence/asset use and parity.

This supersedes the initial milestone's decision to reproduce premium gates. Our own implementation must not require purchases, trials or entitlement checks. Nursing, bottle feeding, solids, diaper tracking, real statistics, prediction/schedule tools and every other delivered feature must be functional without payment. Removing gates alone does not deliver missing functionality.

Parity acceptance has two parts:
- Match original appearance and behavior on unchanged, evidenced screens and journeys.
- Intentionally replace payment/locks/upsells with direct feature access. Judge the features themselves for completeness, correct data and observed behavior; do not count payment removal as a defect.

All other missing functions and unrelated visual mismatches remain open defects. Exact original predictions, entitled editor layouts, cloud contracts and native behavior remain unresolved evidence gaps. They must be independently implemented with documented assumptions or validated using stronger evidence; no claim of full parity follows from clues alone.

The 2026-10-02 build removes gates and promotional statistics. All eight local trackers, computed statistics, unit conversion and web PNG export work without payment. Prediction/schedule algorithms, initial account onboarding, cloud sync, Android notification delivery and widgets remain incomplete. This is not full feature or pixel parity. Current follow-up: `docs/parity-audit/2026-10-02/REPORT.md`; the original audit is retained unchanged.
