import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:baby_tracker/app.dart';
import 'package:baby_tracker/controller.dart';
import 'package:baby_tracker/model.dart';
import 'controller_test.dart' show MemoryStorage;

void main() {
  late TrackerController c;
  setUp(() async {
    c = TrackerController(
      MemoryStorage(),
      clock: () => DateTime(2026, 10, 1, 10),
    );
    await c.load();
  });
  Future<void> mount(
    WidgetTester t, {
    Size size = const Size(412, 915),
    double scale = 1,
  }) async {
    t.view.physicalSize = size;
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);
    await t.pumpWidget(BabyTrackerApp(controller: c, textScale: scale));
    await t.pumpAndSettle();
  }

  testWidgets('all four tabs navigate and all eight free editors open', (
    t,
  ) async {
    await mount(t);
    for (final tab in ['History', 'Stats', 'Settings', 'Home']) {
      await t.tap(find.byKey(ValueKey('tab-$tab')));
      await t.pumpAndSettle();
      expect(t.takeException(), isNull);
    }
    for (final kind in ActivityKind.values) {
      await t.tap(find.byKey(const ValueKey('add-activity')));
      await t.pumpAndSettle();
      await t.ensureVisible(find.byKey(ValueKey('activity-${kind.name}')));
      await t.tap(find.byKey(ValueKey('activity-${kind.name}')));
      await t.pumpAndSettle();
      expect(find.byKey(const ValueKey('save-entry')), findsOneWidget);
      expect(find.text('Try for free'), findsNothing);
      await t.tap(find.byTooltip('Close'));
      await t.pumpAndSettle();
    }
  });
  testWidgets('create nap then edit note and delete through history', (
    t,
  ) async {
    await mount(t);
    await t.tap(find.byKey(const ValueKey('add-activity')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const ValueKey('activity-nap')));
    await t.pumpAndSettle();
    await t.enterText(find.byKey(const ValueKey('entry-note')), 'Quiet room');
    await t.tap(find.byKey(const ValueKey('save-entry')));
    await t.pumpAndSettle();
    expect(c.active?.note, 'Quiet room');
    await t.tap(find.byKey(const ValueKey('tab-History')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(ValueKey('entry-${c.active!.id}')));
    await t.pumpAndSettle();
    await t.enterText(find.byKey(const ValueKey('entry-note')), 'After feed');
    await t.tap(find.byKey(const ValueKey('save-entry')));
    await t.pumpAndSettle();
    expect(c.active?.note, 'After feed');
    await t.tap(find.byKey(ValueKey('entry-${c.active!.id}')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const ValueKey('delete-entry')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const ValueKey('confirm-delete')));
    await t.pumpAndSettle();
    expect(c.entries, isEmpty);
  });
  testWidgets('settings change profile and regional format', (t) async {
    await mount(t);
    await t.tap(find.byKey(const ValueKey('tab-Settings')));
    await t.pumpAndSettle();
    await t.tap(find.text('Name'));
    await t.pumpAndSettle();
    await t.enterText(find.byKey(const ValueKey('baby-name')), 'Mia');
    await t.tap(find.text('Save'));
    await t.pumpAndSettle();
    expect(c.profile.name, 'Mia');
    await t.ensureVisible(find.text('Regional settings'));
    await t.tap(find.text('Regional settings'));
    await t.pumpAndSettle();
    await t.tap(
      find.ancestor(
        of: find.text('Time format').last,
        matching: find.byType(ListTile),
      ),
    );
    await t.pumpAndSettle();
    await t.tap(find.text('24-hour'));
    await t.pumpAndSettle();
    expect(c.profile.use24Hour, isTrue);
  });
  testWidgets('small viewport and large text retain tracking actions', (
    t,
  ) async {
    await mount(t, size: const Size(320, 640), scale: 1.6);
    expect(t.takeException(), isNull);
    await t.tap(find.byKey(const ValueKey('add-activity')));
    await t.pumpAndSettle();
    await t.ensureVisible(find.byKey(const ValueKey('activity-wakeUp')));
    await t.tap(find.byKey(const ValueKey('activity-wakeUp')));
    await t.pumpAndSettle();
    await t.scrollUntilVisible(
      find.byKey(const ValueKey('entry-note')),
      150,
      scrollable: find.byType(Scrollable).last,
    );
    await t.enterText(find.byKey(const ValueKey('entry-note')), 'Morning');
    await t.tap(find.byKey(const ValueKey('save-entry')));
    await t.pumpAndSettle();
    expect(c.entries.single.kind, ActivityKind.wakeUp);
    expect(t.takeException(), isNull);
  });
  testWidgets('failed nap-count save shows persisted value', (t) async {
    final storage = MemoryStorage();
    c = TrackerController(storage, clock: () => DateTime(2026, 10, 1, 10));
    await c.load();
    await c.updateProfile(c.profile.copyWith(customNaps: true));
    storage.fail = true;
    await mount(t);
    await t.tap(find.byKey(const ValueKey('tab-Settings')));
    await t.pumpAndSettle();
    await t.tap(find.text('Sleep settings'));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const ValueKey('nap-count')));
    await t.pumpAndSettle();
    await t.tap(find.text('3').last);
    await t.pumpAndSettle();
    expect(c.profile.napCount, 2);
    expect(find.text('3'), findsNothing);
    expect(find.text('2'), findsOneWidget);
  });

  testWidgets('paused nap can be completed from history editor', (t) async {
    var now = DateTime(2026, 10, 1, 9);
    c = TrackerController(MemoryStorage(), clock: () => now);
    await c.load();
    await c.saveEntry(
      ActivityEntry(id: 'paused', kind: ActivityKind.nap, start: now),
    );
    now = DateTime(2026, 10, 1, 9, 30);
    await c.pause();
    now = DateTime(2026, 10, 1, 10);
    await mount(t);
    await t.tap(find.byKey(const ValueKey('tab-History')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const ValueKey('entry-paused')));
    await t.pumpAndSettle();
    await t.tap(find.text('Set time'));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const ValueKey('picker-save')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const ValueKey('save-entry')));
    await t.pumpAndSettle();
    expect(c.active, isNull);
    expect(c.totalForDay(now), const Duration(minutes: 30));
  });
  testWidgets(
    'free bottle form converts units and preserves amount on note edit',
    (t) async {
      await c.updateProfile(c.profile.copyWith(metric: false));
      await mount(t);
      await t.tap(find.byKey(const ValueKey('add-activity')));
      await t.pumpAndSettle();
      await t.ensureVisible(
        find.byKey(const ValueKey('activity-bottleFeeding')),
      );
      await t.tap(find.byKey(const ValueKey('activity-bottleFeeding')));
      await t.pumpAndSettle();
      await t.ensureVisible(find.byKey(const ValueKey('entry-amount')));
      await t.enterText(find.byKey(const ValueKey('entry-amount')), '4.5');
      await t.tap(find.text('Formula'));
      await t.pumpAndSettle();
      await t.tap(find.byKey(const ValueKey('save-entry')));
      await t.pumpAndSettle();
      expect(c.entries.single.details.amount, closeTo(133.080883, 0.000001));
      expect(c.entries.single.details.choice, 'Formula');
      final original = c.entries.single.details.amount;
      await t.tap(find.byKey(const ValueKey('tab-History')));
      await t.pumpAndSettle();
      await t.tap(find.byKey(ValueKey('entry-${c.entries.single.id}')));
      await t.pumpAndSettle();
      await t.ensureVisible(find.byKey(const ValueKey('entry-note')));
      await t.enterText(find.byKey(const ValueKey('entry-note')), 'After nap');
      await t.tap(find.byKey(const ValueKey('save-entry')));
      await t.pumpAndSettle();
      expect(c.entries.single.details.amount, original);
      await c.load();
      expect(c.entries.single.note, 'After nap');
      expect(t.takeException(), isNull);
    },
  );
  testWidgets('stats compute recorded sleep rather than promotional averages', (
    t,
  ) async {
    await c.saveEntry(
      ActivityEntry(
        id: 'week-nap',
        kind: ActivityKind.nap,
        start: DateTime(2026, 10, 1, 8),
        end: DateTime(2026, 10, 1, 9, 10),
      ),
    );
    await mount(t);
    await t.tap(find.byKey(const ValueKey('tab-Stats')));
    await t.pumpAndSettle();
    expect(find.text('Avg. 0 h 10 min'), findsNWidgets(2));
    expect(find.text('Try for free'), findsNothing);
    expect(find.text('Your patterns start here'), findsNothing);
    expect(t.takeException(), isNull);
  });
  testWidgets('ongoing nursing can finish alongside sleep from Home', (
    t,
  ) async {
    var now = DateTime(2026, 10, 1, 9);
    c = TrackerController(MemoryStorage(), clock: () => now);
    await c.load();
    await c.saveEntry(
      ActivityEntry(id: 'sleep', kind: ActivityKind.nap, start: now),
    );
    await c.saveEntry(
      ActivityEntry(id: 'nursing', kind: ActivityKind.nursing, start: now),
    );
    now = DateTime(2026, 10, 1, 9, 15);
    await mount(t);
    await t.ensureVisible(find.text('Stop nursing'));
    await t.tap(find.text('Stop nursing'));
    await t.pumpAndSettle();
    expect(c.activeNursing, isNull);
    expect(c.active?.id, 'sleep');
    expect(c.nursingForDay(now), const Duration(minutes: 15));
    expect(t.takeException(), isNull);
  });
  testWidgets(
    'a past day keeps its summary and exposes separate timer controls',
    (t) async {
      await c.saveEntry(
        ActivityEntry(
          id: 'current-nap',
          kind: ActivityKind.nap,
          start: DateTime(2026, 10, 1, 9),
        ),
      );
      await mount(t);
      expect(find.text('Asleep for'), findsOneWidget);
      await t.tap(find.byKey(const ValueKey('day-2026-09-30')));
      await t.pumpAndSettle();
      expect(find.text('Asleep for'), findsNothing);
      expect(find.text('Stop'), findsNothing);
      expect(find.text('Stop timer'), findsOneWidget);
      await t.tap(find.text('Pause'));
      await t.pumpAndSettle();
      expect(c.active!.paused, isTrue);
      await t.tap(find.text('Resume'));
      await t.pumpAndSettle();
      expect(c.active!.paused, isFalse);
      await t.tap(find.text('Stop timer'));
      await t.pumpAndSettle();
      expect(c.active, isNull);
      expect(find.byKey(const ValueKey('running-session')), findsNothing);
    },
  );
}
