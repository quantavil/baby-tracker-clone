import 'package:flutter_test/flutter_test.dart';
import 'package:baby_tracker/model.dart';
import 'package:baby_tracker/controller.dart';
import 'package:baby_tracker/storage.dart';

class MemoryStorage implements TrackerStorage {
  String? value;
  bool fail = false;
  @override
  Future<String?> read() async => value;
  @override
  Future<void> write(String json) async {
    if (fail) throw Exception('disk full');
    value = json;
  }
}

void main() {
  late MemoryStorage storage;
  late TrackerController c;
  late DateTime now;
  setUp(() async {
    now = DateTime(2026, 10, 2, 12);
    storage = MemoryStorage();
    c = TrackerController(storage, clock: () => now);
    await c.load();
  });
  ActivityEntry nap(String id, DateTime start, DateTime? end) =>
      ActivityEntry(id: id, kind: ActivityKind.nap, start: start, end: end);
  test('original overlap rule blocks a wake inside an overnight nap', () async {
    now = DateTime(2026, 10, 2, 19, 49);
    await c.saveEntry(nap('overnight', DateTime(2026, 10, 1, 19, 53), now));
    final wake = ActivityEntry(
      id: 'wake',
      kind: ActivityKind.wakeUp,
      start: DateTime(2026, 10, 2, 8, 49),
    );
    final before = storage.value;
    await expectLater(c.saveEntry(wake), throwsArgumentError);
    expect(storage.value, before);
    expect(c.entries.length, 1);
  });
  test('editing a nap cannot introduce a conflict with a saved wake', () async {
    now = DateTime(2026, 10, 2, 19, 49);
    await c.saveEntry(
      ActivityEntry(
        id: 'wake',
        kind: ActivityKind.wakeUp,
        start: DateTime(2026, 10, 2, 8, 49),
      ),
    );
    await expectLater(
      c.saveEntry(nap('overnight', DateTime(2026, 10, 1, 19, 53), now)),
      throwsArgumentError,
    );
    await c.saveEntry(
      nap('finished', DateTime(2026, 10, 2, 7), DateTime(2026, 10, 2, 8, 49)),
    );
    expect(c.entries.length, 2);
  });
  test('create edit delete survive repository reload', () async {
    await c.saveEntry(
      nap('a', DateTime(2026, 10, 1, 10), DateTime(2026, 10, 1, 11)),
    );
    await c.saveEntry(
      nap('a', DateTime(2026, 10, 1, 10), DateTime(2026, 10, 1, 12)),
    );
    final reload = TrackerController(storage, clock: () => now);
    await reload.load();
    expect(reload.entries.length, 1);
    expect(reload.totalForDay(DateTime(2026, 10, 1)), const Duration(hours: 2));
    await reload.deleteEntry('a');
    await c.load();
    expect(c.entries, isEmpty);
  });
  test('reject invalid wake-up, reversed interval and future time', () async {
    for (final hour in [2, 16]) {
      expect(
        () => c.saveEntry(
          ActivityEntry(
            id: 'w',
            kind: ActivityKind.wakeUp,
            start: DateTime(2026, 10, 1, hour),
          ),
        ),
        throwsArgumentError,
      );
    }
    for (final hour in [3, 15]) {
      await c.saveEntry(
        ActivityEntry(
          id: 'w$hour',
          kind: ActivityKind.wakeUp,
          start: DateTime(2026, 10, 1, hour),
        ),
      );
    }
    expect(
      () => c.saveEntry(
        nap('bad', DateTime(2026, 10, 1, 12), DateTime(2026, 10, 1, 11)),
      ),
      throwsArgumentError,
    );
    expect(() => c.saveEntry(nap('zero', now, now)), throwsArgumentError);
    expect(
      () => c.saveEntry(nap('future', now.add(const Duration(hours: 1)), null)),
      throwsArgumentError,
    );
  });
  test('midnight nap counts actual intersection per calendar day', () async {
    await c.saveEntry(
      nap('night', DateTime(2026, 10, 1, 23, 30), DateTime(2026, 10, 2, 1, 15)),
    );
    expect(c.totalForDay(DateTime(2026, 10, 1)), const Duration(minutes: 30));
    expect(c.totalForDay(DateTime(2026, 10, 2)), const Duration(minutes: 75));
  });
  test('one active sleep with pause resume reload and stop', () async {
    now = DateTime(2026, 10, 2, 8);
    await c.saveEntry(nap('a', now, null));
    now = now.add(const Duration(minutes: 30));
    await c.pause();
    final reload = TrackerController(storage, clock: () => now);
    await reload.load();
    now = now.add(const Duration(minutes: 20));
    expect(reload.elapsed(reload.active!), const Duration(minutes: 30));
    await reload.resume();
    now = now.add(const Duration(minutes: 10));
    expect(() => reload.saveEntry(nap('b', now, null)), throwsArgumentError);
    await reload.stop();
    expect(reload.active, isNull);
    expect(reload.totalForDay(now), const Duration(minutes: 40));
  });
  test('pause crossing midnight removes the correct daily overlap', () async {
    now = DateTime(2026, 10, 1, 23, 40);
    await c.saveEntry(nap('a', now, null));
    now = DateTime(2026, 10, 1, 23, 50);
    await c.pause();
    now = DateTime(2026, 10, 2, 0, 20);
    await c.resume();
    now = DateTime(2026, 10, 2, 0, 40);
    await c.stop();
    expect(c.totalForDay(DateTime(2026, 10, 1)), const Duration(minutes: 10));
    expect(c.totalForDay(DateTime(2026, 10, 2)), const Duration(minutes: 20));
  });
  test('profile preferences persist on reload', () async {
    await c.updateProfile(
      c.profile.copyWith(
        name: 'Mia',
        birthday: DateTime(2026, 1, 1),
        use24Hour: true,
        metric: false,
        notifications: true,
        customNaps: true,
        napCount: 3,
      ),
    );
    final reload = TrackerController(storage);
    await reload.load();
    expect(reload.profile.name, 'Mia');
    expect(reload.profile.use24Hour, isTrue);
    expect(reload.profile.metric, isFalse);
    expect(reload.profile.napCount, 3);
    expect(
      () => c.updateProfile(c.profile.copyWith(name: '   ')),
      throwsArgumentError,
    );
  });
  test('failed writes leave published state unchanged', () async {
    storage.fail = true;
    expect(
      () => c.saveEntry(nap('a', now.subtract(const Duration(hours: 1)), now)),
      throwsException,
    );
    await Future<void>.delayed(Duration.zero);
    expect(c.entries, isEmpty);
  });
  test('corrupt saved data blocks writes without deleting source', () async {
    storage.value = '{not json';
    await c.load();
    expect(c.error, isNotNull);
    expect(
      () => c.saveEntry(nap('a', now.subtract(const Duration(hours: 1)), now)),
      throwsStateError,
    );
    expect(storage.value, '{not json');
  });
  test('all activity kinds save and reload without entitlements', () async {
    for (final kind in ActivityKind.values) {
      await c.saveEntry(
        ActivityEntry(
          id: kind.name,
          kind: kind,
          start: DateTime(2026, 10, 1, 8),
          end: kind.interval ? DateTime(2026, 10, 1, 9) : null,
        ),
      );
    }
    await c.load();
    expect(c.error, isNull);
    expect(c.entries.length, 8);
  });
  test('overlapping completed naps count sleep once across midnight', () async {
    await c.saveEntry(
      nap('a', DateTime(2026, 10, 1, 23, 30), DateTime(2026, 10, 2, 0, 30)),
    );
    await c.saveEntry(
      nap('b', DateTime(2026, 10, 1, 23, 45), DateTime(2026, 10, 2, 0, 45)),
    );
    expect(c.totalForDay(DateTime(2026, 10, 1)), const Duration(minutes: 30));
    expect(c.totalForDay(DateTime(2026, 10, 2)), const Duration(minutes: 45));
  });
  test(
    'revising paused entries closes or translates pauses with boundaries',
    () async {
      now = DateTime(2026, 10, 2, 8);
      await c.saveEntry(nap('a', now, null));
      now = DateTime(2026, 10, 2, 8, 30);
      await c.pause();
      now = DateTime(2026, 10, 2, 9);
      await c.saveEntry(
        c.active!.revised(
          start: DateTime(2026, 10, 2, 8),
          end: now,
          note: 'Finished',
        ),
      );
      expect(c.active, isNull);
      expect(c.totalForDay(now), const Duration(minutes: 30));
      final e = c.entries.single;
      await c.saveEntry(
        e.revised(
          start: DateTime(2026, 10, 1, 7),
          end: DateTime(2026, 10, 1, 8),
          note: 'Date correction',
        ),
      );
      expect(c.totalForDay(DateTime(2026, 10, 1)), const Duration(minutes: 30));
      expect(
        c.entries.single.pauses.single.start,
        DateTime(2026, 10, 1, 7, 30),
      );
    },
  );
  test('paused dial segments stop growing until resume', () async {
    now = DateTime(2026, 10, 2, 8);
    await c.saveEntry(nap('a', now, null));
    now = DateTime(2026, 10, 2, 8, 30);
    await c.pause();
    now = DateTime(2026, 10, 2, 9);
    final segments = c.active!.activeSegments(now);
    expect(segments.length, 1);
    expect(segments.single.end, DateTime(2026, 10, 2, 8, 30));
    await c.resume();
    now = DateTime(2026, 10, 2, 9, 10);
    expect(c.active!.activeSegments(now).length, 2);
  });
  test('exportJson, importJson and clearAll restore state cleanly', () async {
    await c.saveEntry(
      nap('n1', DateTime(2026, 10, 1, 9), DateTime(2026, 10, 1, 10)),
    );
    await c.updateProfile(c.profile.copyWith(name: 'Oliver', metric: true));
    final exported = c.exportJson();
    expect(exported, contains('Oliver'));
    expect(exported, contains('n1'));

    await c.clearAll();
    expect(c.entries, isEmpty);
    expect(c.profile.name, 'Oliver');

    await c.importJson(exported);
    expect(c.entries.length, 1);
    expect(c.entries.single.id, 'n1');
    expect(c.profile.name, 'Oliver');
  });
  test(
    'consecutive bedtimes without wake-up close gracefully without leaking',
    () async {
      now = DateTime(2026, 10, 3, 12);
      // Bedtime 1 on Oct 1 at 20:00
      await c.saveEntry(
        ActivityEntry(
          id: 'bed1',
          kind: ActivityKind.bedtime,
          start: DateTime(2026, 10, 1, 20),
        ),
      );
      // Bedtime 2 on Oct 2 at 21:00 (Oct 1 bedtime forgot to log wake-up)
      await c.saveEntry(
        ActivityEntry(
          id: 'bed2',
          kind: ActivityKind.bedtime,
          start: DateTime(2026, 10, 2, 21),
        ),
      );
      // Wake up on Oct 3 at 07:00
      await c.saveEntry(
        ActivityEntry(
          id: 'wake3',
          kind: ActivityKind.wakeUp,
          start: DateTime(2026, 10, 3, 7),
        ),
      );

      // Oct 1 should have 4 hours (20:00 - 24:00)
      expect(
        c.nightSleepForDay(DateTime(2026, 10, 1)),
        const Duration(hours: 4),
      );
      // Oct 2 should have 8 hours (00:00 - 08:00 from bed1 capped at 12h) + 3 hours (21:00 - 24:00 from bed2) = 11h
      expect(
        c.nightSleepForDay(DateTime(2026, 10, 2)),
        const Duration(hours: 11),
      );
      // Oct 3 should have 7 hours (00:00 - 07:00 from bed2 to wake3)
      expect(
        c.nightSleepForDay(DateTime(2026, 10, 3)),
        const Duration(hours: 7),
      );
    },
  );
}
