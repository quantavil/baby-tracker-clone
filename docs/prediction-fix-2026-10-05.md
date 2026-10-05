# October 5 forecast correction

The clone's missing-birthday fallback selected age nine months, producing two naps and a long first wake window. This was an unsupported compatibility decision.

## Recovered age rule

Supplementary original x86_64 Baby Tracker 2.9.0 binary, SHA-256 `b059afe4660a2d72ab70ec6745d2d830a3b0473f1631a21d869ec2579dac81be`:

- `AgeRepositoryImpl.loadAgeInMonths`, 0xafa1f4, loads birthday and calls `AgeCalculator.ageInMonthsFromBirthday`.
- `AgeCalculator.uncappedAgeInMonthsFromBirthday`, 0x65c230: 0x65c252 compares birthday to null; null selects AppClock.now as the date to subtract. The elapsed whole days are divided by 30.0 and negative age clamps to zero.
- `AgeCalculator.ageInMonthsFromBirthday`, 0x65c1ec, caps at 24.0.
- Pool operands r15+0x5d07 and r15+0x5cff decode as immediate IEEE754 doubles 30.0 and 24.0, corroborated by divsd/movsd consumers. Generic Smi labels for these slots are misleading.

Raw annotated bodies and pool receipts remain ignored under `evidence/research/`.

`DialScale` now uses zero rather than nine for null birthday. Existing explicitly supplied birthdays remain unchanged. No persisted profile or records are migrated or erased.

## Screenshot regression

User screenshot: wake 11:23; six predicted nap starts 12:23, 14:45, 17:06, 19:26, 21:46, 00:05; final nap ends 01:14; bedtime 02:23. A frozen 11:51:30 case yields 31 minutes until first nap and 28 minutes awake. Exact original screenshot seconds and birthday were not supplied; these are a discriminating initial zero-age case, not proof of matching every profile/history.

The test failed before the fix (two slots rather than six) and passes after it. Predicted slots now render as dark capsules with closed gradient outlines and tangent captions, based on the supplied screenshot. These use computed intervals; no screenshot time array is used by production code.

The disposable `PREDICTION_CASE` preview uses memory storage and a frozen clock. The normal app continues using the real clock and persisted records. Historical learning, corrections after short/skipped naps, and all adaptive prediction branches remain incompletely reconstructed; this fix does not establish full prediction parity.
