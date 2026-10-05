import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:baby_tracker/controller.dart';
import 'package:baby_tracker/app.dart';
import 'package:baby_tracker/model.dart';
import 'package:baby_tracker/ui/dial.dart';
import 'package:baby_tracker/ui/home.dart';
import 'package:baby_tracker/ui/editor.dart';
import 'controller_test.dart' show MemoryStorage;

void main() {
  final now = DateTime(2026, 10, 2, 12);
  Future<TrackerController> controller() async {
    final c = TrackerController(MemoryStorage(), clock: () => now);
    await c.load();
    return c;
  }

  Future<void> mount(WidgetTester t, TrackerController c, DateTime day) async {
    await t.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: ScheduleDial(controller: c, day: day),
          ),
        ),
      ),
    );
    await t.pumpAndSettle();
  }

  testWidgets('unstarted day opens wake-up form without creating a nap', (
    t,
  ) async {
    final c = await controller();
    await mount(t, c, now);
    await t.tap(find.byKey(const ValueKey('debug_start_day_button')));
    await t.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('debug_wake_up_time_field')),
      findsOneWidget,
    );
    expect(c.entries, isEmpty);
    expect(t.takeException(), isNull);
  });
  testWidgets('past day shows completed sleep and count without a live timer', (
    t,
  ) async {
    final c = await controller();
    await c.saveEntry(
      ActivityEntry(
        id: 'wake',
        kind: ActivityKind.wakeUp,
        start: DateTime(2026, 10, 1, 7),
      ),
    );
    await c.saveEntry(
      ActivityEntry(
        id: 'nap',
        kind: ActivityKind.nap,
        start: DateTime(2026, 10, 1, 9),
        end: DateTime(2026, 10, 1, 10),
      ),
    );
    await c.saveEntry(
      ActivityEntry(
        id: 'active',
        kind: ActivityKind.nap,
        start: DateTime(2026, 10, 1, 20),
      ),
    );
    await mount(t, c, DateTime(2026, 10, 1));
    expect(find.text('Day sleep'), findsOneWidget);
    expect(find.text('1 h 0 min'), findsOneWidget);
    expect(find.text('1 times'), findsOneWidget);
    expect(find.text('Awake for'), findsNothing);
  });
  testWidgets('dial opens completed nap summary before editing', (t) async {
    final c = await controller();
    await c.saveEntry(
      ActivityEntry(
        id: 'nap',
        kind: ActivityKind.nap,
        start: DateTime(2026, 10, 2, 9),
        end: DateTime(2026, 10, 2, 10),
      ),
    );
    await mount(t, c, now);
    await t.tap(find.byKey(const ValueKey('nap_1')));
    await t.pumpAndSettle();
    expect(find.text('Edit'), findsOneWidget);
    expect(find.byKey(const ValueKey('entry-note')), findsNothing);
    await t.tap(find.text('Edit'));
    await t.pumpAndSettle();
    expect(find.byKey(const ValueKey('save-entry')), findsOneWidget);
    expect(c.entries.length, 1);
  });
  testWidgets(
    'home can switch from recorded day to empty night and open bedtime',
    (t) async {
      t.view.physicalSize = const Size(390, 900);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.resetPhysicalSize);
      addTearDown(t.view.resetDevicePixelRatio);
      final c = await controller();
      await c.saveEntry(
        ActivityEntry(
          id: 'wake',
          kind: ActivityKind.wakeUp,
          start: DateTime(2026, 10, 2, 7),
        ),
      );
      await t.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HomePage(controller: c, day: now, onDay: (_) {}),
          ),
        ),
      );
      await t.pumpAndSettle();
      await t.ensureVisible(find.byKey(const ValueKey('schedule-night')));
      await t.tap(find.byKey(const ValueKey('schedule-night')));
      await t.pumpAndSettle();
      expect(find.byKey(const ValueKey('night-schedule')), findsOneWidget);
      expect(find.text('Night wakings'), findsOneWidget);
      await t.ensureVisible(find.byKey(const ValueKey('night-bedtime')));
      await t.tap(find.byKey(const ValueKey('night-bedtime')));
      await t.pumpAndSettle();
      expect(find.text('Log bedtime'), findsOneWidget);
      await t.tap(find.text('Log bedtime'));
      await t.pumpAndSettle();
      expect(find.text('Bedtime'), findsWidgets);
      expect(find.byKey(const ValueKey('save-entry')), findsOneWidget);
      expect(c.entries.length, 1);
    },
  );
  testWidgets('corrupt storage recovery is reachable from the error screen', (
    t,
  ) async {
    t.view.physicalSize = const Size(412, 915);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);
    final store = MemoryStorage()..value = '{broken';
    final c = TrackerController(store, clock: () => now);
    await c.load();
    final source = await controller();
    await source.saveEntry(
      ActivityEntry(
        id: 'restored',
        kind: ActivityKind.diaperChange,
        start: DateTime(2026, 10, 2, 8),
      ),
    );
    await t.pumpWidget(BabyTrackerApp(controller: c));
    await t.pumpAndSettle();
    await t.tap(find.text('Restore backup'));
    await t.pumpAndSettle();
    await t.enterText(
      find.byKey(const ValueKey('restore-backup-json')),
      source.exportJson(),
    );
    await t.tap(find.text('Restore'));
    await t.pumpAndSettle();
    expect(c.error, isNull);
    expect(c.entries.single.id, 'restored');
    expect(find.text('Retry loading'), findsNothing);
    expect(t.takeException(), isNull);
  });
  test('valid backup can recover corrupt saved data atomically', () async {
    final store = MemoryStorage()..value = '{broken';
    final c = TrackerController(store, clock: () => now);
    await c.load();
    expect(c.error, isNotNull);
    final source = await controller();
    await source.saveEntry(
      ActivityEntry(
        id: 'restore',
        kind: ActivityKind.diaperChange,
        start: DateTime(2026, 10, 2, 8),
      ),
    );
    await c.importJson(source.exportJson());
    expect(c.error, isNull);
    final reload = TrackerController(store, clock: () => now);
    await reload.load();
    expect(reload.error, isNull);
    expect(reload.entries.single.id, 'restore');
  });
  test('failed backup recovery preserves corrupt original and error', () async {
    final store = MemoryStorage()
      ..value = '{broken'
      ..fail = true;
    final c = TrackerController(store, clock: () => now);
    await c.load();
    final source = await controller();
    await expectLater(c.importJson(source.exportJson()), throwsException);
    expect(store.value, '{broken');
    expect(c.error, isNotNull);
  });
  testWidgets('today without wake-up does not inherit yesterday running nap', (
    t,
  ) async {
    final c = await controller();
    await c.saveEntry(
      ActivityEntry(
        id: 'old',
        kind: ActivityKind.nap,
        start: DateTime(2026, 10, 1, 20),
      ),
    );
    await mount(t, c, now);
    expect(
      find.byKey(const ValueKey('debug_start_day_button')),
      findsOneWidget,
    );
    expect(find.text('Asleep for'), findsNothing);
  });
  testWidgets('awake display advances with the clock without active tracking', (
    t,
  ) async {
    var time = DateTime(2026, 10, 2, 10);
    final c = TrackerController(MemoryStorage(), clock: () => time);
    await c.load();
    await c.saveEntry(
      ActivityEntry(
        id: 'wake',
        kind: ActivityKind.wakeUp,
        start: DateTime(2026, 10, 2, 7),
      ),
    );
    await t.pumpWidget(BabyTrackerApp(controller: c));
    await t.pumpAndSettle();
    expect(find.text('3 h'), findsOneWidget);
    time = DateTime(2026, 10, 2, 10, 1);
    await t.pump(const Duration(seconds: 2));
    expect(find.text('3 h 1 min'), findsOneWidget);
  });
  testWidgets('past day bedtime anchor saves on the selected date', (t) async {
    final c = await controller();
    await c.saveEntry(
      ActivityEntry(
        id: 'wake',
        kind: ActivityKind.wakeUp,
        start: DateTime(2026, 10, 1, 7, 20),
      ),
    );
    await mount(t, c, DateTime(2026, 10, 1));
    await t.ensureVisible(
      find.byKey(const ValueKey('debug_predicted_bedtime_button')),
    );
    await t.tap(find.byKey(const ValueKey('debug_predicted_bedtime_button')));
    await t.pumpAndSettle();
    await t.tap(
      find.byKey(const ValueKey('debug_tracking_event_primary_button')),
    );
    await t.pumpAndSettle();
    await t.tap(find.byKey(const ValueKey('save-entry')));
    await t.pumpAndSettle();
    expect(
      c.entries.singleWhere((e) => e.kind == ActivityKind.bedtime).start,
      DateTime(2026, 10, 1, 22),
    );
  });
  testWidgets('every logged nap retains a dial summary target after six naps', (
    t,
  ) async {
    final c = await controller();
    for (var i = 0; i < 7; i++) {
      await c.saveEntry(
        ActivityEntry(
          id: 'nap$i',
          kind: ActivityKind.nap,
          start: DateTime(2026, 10, 1, 7 + i),
          end: DateTime(2026, 10, 1, 7 + i, 30),
        ),
      );
    }
    await mount(t, c, DateTime(2026, 10, 1));
    expect(find.byKey(const ValueKey('nap_7')), findsOneWidget);
    await t.tap(find.byKey(const ValueKey('nap_7')));
    await t.pumpAndSettle();
    expect(find.text('Edit'), findsOneWidget);
    expect(find.text('1:00 PM - 1:30 PM'), findsOneWidget);
  });
  testWidgets('future prediction stays prefilled and cannot be saved as now', (
    t,
  ) async {
    t.view.physicalSize = const Size(412, 915);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);
    final c = await controller();
    await t.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (ctx) => TextButton(
              onPressed: () => showEditor(
                ctx,
                c,
                ActivityKind.bedtime,
                initialStart: DateTime(2026, 10, 2, 22),
              ),
              child: const Text('Open bedtime'),
            ),
          ),
        ),
      ),
    );
    await t.tap(find.text('Open bedtime'));
    await t.pumpAndSettle();
    expect(find.text('Activity time cannot be in the future'), findsOneWidget);
    final save = t.widget<FilledButton>(
      find.descendant(
        of: find.byKey(const ValueKey('save-entry')),
        matching: find.byType(FilledButton),
      ),
    );
    expect(save.onPressed, isNull);
    expect(c.entries, isEmpty);
  });
  for (final invalid in ['duplicate ids', 'multiple timers']) {
    test(
      'invalid backup $invalid is rejected without replacing storage',
      () async {
        final store = MemoryStorage();
        final c = TrackerController(store, clock: () => now);
        await c.load();
        await c.saveEntry(
          ActivityEntry(
            id: 'keep',
            kind: ActivityKind.diaperChange,
            start: DateTime(2026, 10, 2, 8),
          ),
        );
        final saved = store.value;
        final a = ActivityEntry(
          id: 'a',
          kind: ActivityKind.nap,
          start: DateTime(2026, 10, 2, 9),
          end: invalid == 'duplicate ids' ? DateTime(2026, 10, 2, 9, 30) : null,
        );
        final b = ActivityEntry(
          id: invalid == 'duplicate ids' ? 'a' : 'b',
          kind: ActivityKind.nap,
          start: DateTime(2026, 10, 2, 10),
          end: invalid == 'duplicate ids'
              ? DateTime(2026, 10, 2, 10, 30)
              : null,
        );
        final raw = jsonEncode({
          'version': 1,
          'profile': c.profile.toJson(),
          'entries': [a.toJson(), b.toJson()],
        });
        await expectLater(c.importJson(raw), throwsFormatException);
        expect(store.value, saved);
        expect(c.entries.single.id, 'keep');
      },
    );
  }
}
