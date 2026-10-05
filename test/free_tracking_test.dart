import 'package:flutter_test/flutter_test.dart';
import 'package:baby_tracker/controller.dart';
import 'package:baby_tracker/model.dart';
import 'package:baby_tracker/ui/theme.dart';
import 'package:baby_tracker/ui/dial.dart';
import 'controller_test.dart' show MemoryStorage;

void main() {
  test('feeding and diaper details survive edits and reload', () async {
    final c = TrackerController(
      MemoryStorage(),
      clock: () => DateTime(2026, 10, 2, 12),
    );
    await c.load();
    for (final kind in [
      ActivityKind.bottleFeeding,
      ActivityKind.solids,
      ActivityKind.diaperChange,
      ActivityKind.nursing,
    ]) {
      final details = switch (kind) {
        ActivityKind.bottleFeeding => const TrackingDetails(
          amount: 120,
          choice: 'Formula',
        ),
        ActivityKind.solids => const TrackingDetails(
          amount: 25,
          food: 'Banana',
        ),
        ActivityKind.diaperChange => const TrackingDetails(choice: 'Mixed'),
        _ => const TrackingDetails(choice: 'Left'),
      };
      await c.saveEntry(
        ActivityEntry(
          id: kind.name,
          kind: kind,
          start: DateTime(2026, 10, 2, 9),
          end: kind.interval ? DateTime(2026, 10, 2, 9, 15) : null,
          details: details,
        ),
      );
      final e = c.entries.firstWhere((e) => e.id == kind.name);
      await c.saveEntry(e.revised(start: e.start, end: e.end, note: 'Edited'));
    }
    await c.load();
    expect(c.error, isNull);
    expect(
      c.entries
          .firstWhere((e) => e.kind == ActivityKind.bottleFeeding)
          .details
          .amount,
      120,
    );
    expect(
      c.entries.firstWhere((e) => e.kind == ActivityKind.solids).details.food,
      'Banana',
    );
    expect(
      c.entries
          .firstWhere((e) => e.kind == ActivityKind.diaperChange)
          .details
          .choice,
      'Mixed',
    );
    expect(
      c.entries
          .firstWhere((e) => e.kind == ActivityKind.nursing)
          .details
          .choice,
      'Left',
    );
  });
  test('nursing timer can run alongside sleep without replacing it', () async {
    final c = TrackerController(
      MemoryStorage(),
      clock: () => DateTime(2026, 10, 2, 12),
    );
    await c.load();
    await c.saveEntry(
      ActivityEntry(
        id: 'sleep',
        kind: ActivityKind.nap,
        start: DateTime(2026, 10, 2, 10),
      ),
    );
    await c.saveEntry(
      ActivityEntry(
        id: 'feed',
        kind: ActivityKind.nursing,
        start: DateTime(2026, 10, 2, 11),
      ),
    );
    await c.load();
    expect(c.error, isNull);
    expect(c.active?.id, 'sleep');
    expect(c.activeNursing?.id, 'feed');
  });
  test('night sleep spans midnight and excludes logged wakings', () async {
    final c = TrackerController(
      MemoryStorage(),
      clock: () => DateTime(2026, 10, 2, 12),
    );
    await c.load();
    await c.saveEntry(
      ActivityEntry(
        id: 'bed',
        kind: ActivityKind.bedtime,
        start: DateTime(2026, 10, 1, 22),
      ),
    );
    await c.saveEntry(
      ActivityEntry(
        id: 'wake',
        kind: ActivityKind.wakeUp,
        start: DateTime(2026, 10, 2, 7),
      ),
    );
    await c.saveEntry(
      ActivityEntry(
        id: 'night',
        kind: ActivityKind.nightWaking,
        start: DateTime(2026, 10, 2, 2),
        end: DateTime(2026, 10, 2, 2, 30),
      ),
    );
    expect(c.nightSleepForDay(DateTime(2026, 10, 1)), const Duration(hours: 2));
    expect(
      c.nightSleepForDay(DateTime(2026, 10, 2)),
      const Duration(hours: 6, minutes: 30),
    );
  });
  test('negative and non-finite amounts reject without saving', () async {
    final c = TrackerController(
      MemoryStorage(),
      clock: () => DateTime(2026, 10, 2, 12),
    );
    await c.load();
    for (final amount in [-1.0, double.nan, double.infinity]) {
      await expectLater(
        c.saveEntry(
          ActivityEntry(
            id: 'bad',
            kind: ActivityKind.bottleFeeding,
            start: DateTime(2026, 10, 2, 9),
            details: TrackingDetails(amount: amount),
          ),
        ),
        throwsArgumentError,
      );
    }
    expect(c.entries, isEmpty);
  });
  test('relativeAgo formats human readable past intervals', () {
    final now = DateTime(2026, 10, 2, 12, 0);
    expect(relativeAgo(now, now), 'Just now');
    expect(relativeAgo(now.subtract(const Duration(minutes: 5)), now), '5 min ago');
    expect(
      relativeAgo(now.subtract(const Duration(hours: 2, minutes: 14)), now),
      '2 h 14 min ago',
    );
    expect(
      relativeAgo(now.subtract(const Duration(hours: 14, minutes: 48)), now),
      '14 h 48 min ago',
    );
  });
  test('dialTimeLabel formats short 12-hour and 24-hour time', () {
    final t = DateTime(2026, 10, 2, 8, 20);
    expect(dialTimeLabel(t, const BabyProfile(use24Hour: false)), '8:20');
    expect(dialTimeLabel(t, const BabyProfile(use24Hour: true)), '08:20');
    final afternoon = DateTime(2026, 10, 2, 15, 23);
    expect(dialTimeLabel(afternoon, const BabyProfile(use24Hour: false)), '3:23');
    expect(dialTimeLabel(afternoon, const BabyProfile(use24Hour: true)), '15:23');
  });
  test('DialScale derives predicted bedtime when only wake-up is logged', () {
    final wake = DateTime(2026, 10, 1, 7, 20);
    final entries = [
      ActivityEntry(id: 'w', kind: ActivityKind.wakeUp, start: wake),
    ];
    final scale = DialScale(entries, wake);
    expect(scale.wake, wake);
    expect(scale.bed, isNull);
    expect(scale.predictedBed, DateTime(wake.year, wake.month, wake.day, 22));
    expect(scale.until, scale.predictedBed);
  });
}
