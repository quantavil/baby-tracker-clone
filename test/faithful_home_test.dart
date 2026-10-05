import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:baby_tracker/model.dart';
import 'package:baby_tracker/ui/dial.dart';
import 'package:baby_tracker/ui/theme.dart';
import 'package:baby_tracker/ui/home.dart';
import 'package:baby_tracker/controller.dart';
import 'package:baby_tracker/ui/editor.dart';
import 'controller_test.dart' show MemoryStorage;

void main() {
  testWidgets('recorded wake opens a clock summary before editing', (t) async {
    final now = DateTime(2026, 10, 5, 11, 51);
    final c = TrackerController(MemoryStorage(), clock: () => now);
    await c.load();
    await c.saveEntry(
      ActivityEntry(
        id: 'w',
        kind: ActivityKind.wakeUp,
        start: DateTime(2026, 10, 5, 7, 20),
      ),
    );
    await t.pumpWidget(
      MaterialApp(
        theme: trackerTheme(),
        home: Scaffold(
          body: ScheduleDial(controller: c, day: now),
        ),
      ),
    );
    await t.tap(find.byKey(const ValueKey('debug_wake_up_button')));
    await t.pumpAndSettle();
    expect(find.text('Edit'), findsOneWidget);
    expect(find.byType(ActivityEditor), findsNothing);
    expect(find.text('7:20 AM'), findsWidgets);
    expect(find.text('7:20 AM - now'), findsNothing);
  });

  testWidgets(
    'original empty Overview is a four-card grid with missing values',
    (t) async {
      final now = DateTime(2026, 10, 5, 12);
      final c = TrackerController(MemoryStorage(), clock: () => now);
      await c.load();
      await t.pumpWidget(
        MaterialApp(
          theme: trackerTheme(),
          home: Scaffold(
            body: HomePage(controller: c, day: now, onDay: (_) {}),
          ),
        ),
      );
      await t.scrollUntilVisible(find.text('Night sleep'), 400);
      expect(find.text('Daytime awake'), findsOneWidget);
      expect(find.text('Total sleep'), findsOneWidget);
      expect(find.text('Log today’s data'), findsNWidgets(4));
      expect(
        t.getTopLeft(find.text('Day sleep')).dy,
        closeTo(t.getTopLeft(find.text('Night sleep')).dy, 1),
      );
      expect(find.text('Overview · Today'), findsOneWidget);
      expect(t.takeException(), isNull);
    },
  );

  testWidgets('dial anchors align with the painted track endpoints', (t) async {
    final now = DateTime(2026, 10, 5, 11, 51);
    final c = TrackerController(MemoryStorage(), clock: () => now);
    await c.load();
    await c.saveEntry(
      ActivityEntry(
        id: 'w',
        kind: ActivityKind.wakeUp,
        start: DateTime(2026, 10, 5, 11, 23),
      ),
    );
    for (final width in [320.0, 412.0]) {
      await t.pumpWidget(
        MaterialApp(
          theme: trackerTheme(),
          home: Scaffold(
            body: Align(
              alignment: Alignment.topLeft,
              child: SizedBox(
                width: width,
                child: ScheduleDial(controller: c, day: now),
              ),
            ),
          ),
        ),
      );
      await t.pumpAndSettle();
      final painting = find.byType(CustomPaint).first;
      final origin = t.getTopLeft(painting);
      final center = origin + Offset(width / 2, width / 2);
      final wakeIcon = find.byWidgetPredicate(
        (w) =>
            w is Image &&
            w.image is AssetImage &&
            (w.image as AssetImage).assetName.endsWith('/wake_up_icon.png'),
      );
      final expected =
          center +
          Offset(math.cos(math.pi * .75), math.sin(math.pi * .75)) *
              (width * .445);
      expect((t.getCenter(wakeIcon) - expected).distance, lessThan(1));
      expect(
        t.getSize(find.byKey(const ValueKey('debug_wake_up_button'))).width,
        lessThan(width / 2),
      );
      expect(t.takeException(), isNull);
    }
  });

  testWidgets(
    'recorded nap summary exposes confirmed deletion and persists it',
    (t) async {
      final storage = MemoryStorage();
      final c = TrackerController(
        storage,
        clock: () => DateTime(2026, 10, 2, 12),
      );
      await c.load();
      final nap = ActivityEntry(
        id: 'captured-nap',
        kind: ActivityKind.nap,
        start: DateTime(2026, 10, 1, 13, 3),
        end: DateTime(2026, 10, 1, 14, 19),
      );
      await c.saveEntry(nap);
      await t.pumpWidget(
        MaterialApp(
          theme: trackerTheme(),
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => showEntrySummary(context, c, nap),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );
      await t.tap(find.text('Open'));
      await t.pumpAndSettle();
      expect(find.text('1 h 16 min'), findsOneWidget);
      await t.tap(find.byKey(const ValueKey('summary-delete-entry')));
      await t.pumpAndSettle();
      await t.tap(find.text('Cancel'));
      await t.pumpAndSettle();
      expect(c.entries.single.id, nap.id);
      storage.fail = true;
      await t.tap(find.byKey(const ValueKey('summary-delete-entry')));
      await t.pumpAndSettle();
      await t.tap(find.byKey(const ValueKey('confirm-delete')));
      await t.pumpAndSettle();
      expect(c.entries.single.id, nap.id);
      expect(
        find.byKey(const ValueKey('summary-delete-entry')),
        findsOneWidget,
      );
      final afterFailure = TrackerController(
        storage,
        clock: () => DateTime(2026, 10, 2, 12),
      );
      await afterFailure.load();
      expect(afterFailure.entries.single.id, nap.id);
      storage.fail = false;
      await t.tap(find.byKey(const ValueKey('summary-delete-entry')));
      await t.pumpAndSettle();
      await t.tap(find.byKey(const ValueKey('confirm-delete')));
      await t.pumpAndSettle();
      expect(c.entries, isEmpty);
      expect(
        find.byKey(const ValueKey('debug_tracking_event_primary_button')),
        findsNothing,
      );
      final reopened = TrackerController(
        storage,
        clock: () => DateTime(2026, 10, 2, 12),
      );
      await reopened.load();
      expect(reopened.entries, isEmpty);
    },
  );

  testWidgets(
    'learning progress ignores nap dates outside the recovered 30-day window',
    (t) async {
      final now = DateTime(2026, 10, 31, 12);
      final c = TrackerController(MemoryStorage(), clock: () => now);
      await c.load();
      for (final offset in [0, 29, 30, 31, 60]) {
        final start = DateTime(now.year, now.month, now.day - offset, 9);
        await c.saveEntry(
          ActivityEntry(
            id: 'day-$offset',
            kind: ActivityKind.nap,
            start: start,
            end: start.add(const Duration(hours: 1)),
          ),
        );
      }
      await t.pumpWidget(
        MaterialApp(
          theme: trackerTheme(),
          home: Scaffold(
            body: HomePage(
              controller: c,
              day: DateTime(2026, 10, 1),
              onDay: (_) {},
            ),
          ),
        ),
      );
      await t.scrollUntilVisible(
        find.byKey(const ValueKey('main_data_accumulation_banner')),
        300,
      );
      await t.pumpAndSettle();
      expect(
        find.text('Day 2/3 · Log naps to improve predictions'),
        findsOneWidget,
      );
      expect(find.text('2/3'), findsOneWidget);
      expect(t.takeException(), isNull);
    },
  );

  testWidgets(
    'legacy overnight conflict stays in history but cannot distort the daytime dial',
    (t) async {
      final now = DateTime(2026, 10, 2, 19, 49);
      final storage = MemoryStorage();
      final c = TrackerController(storage, clock: () => now);
      await c.load();
      final bad = ActivityEntry(
        id: 'overnight',
        kind: ActivityKind.nap,
        start: DateTime(2026, 10, 1, 19, 53),
        end: now,
      );
      await c.saveEntry(bad);
      await c.saveEntry(
        ActivityEntry(
          id: 'past-wake',
          kind: ActivityKind.wakeUp,
          start: DateTime(2026, 10, 1, 7, 20),
        ),
      );
      final saved = jsonDecode(c.exportJson()) as Map<String, dynamic>;
      (saved['entries'] as List).add(
        ActivityEntry(
          id: 'wake',
          kind: ActivityKind.wakeUp,
          start: DateTime(2026, 10, 2, 8, 49),
        ).toJson(),
      );
      storage.value = jsonEncode(saved);
      await c.load();
      expect(c.error, isNull);
      await t.pumpWidget(
        MaterialApp(
          theme: trackerTheme(),
          home: Scaffold(
            body: ScheduleDial(controller: c, day: now),
          ),
        ),
      );
      final painting =
          t
                  .widgetList<CustomPaint>(find.byType(CustomPaint))
                  .firstWhere((w) => w.painter is DialPainter)
                  .painter!
              as DialPainter;
      expect(painting.entries.where((e) => e.id == bad.id), isEmpty);
      expect(c.entriesForDay(now).where((e) => e.id == bad.id), hasLength(1));
      expect(c.entries.singleWhere((e) => e.id == bad.id).end, now);
      await t.pumpWidget(
        MaterialApp(
          theme: trackerTheme(),
          home: Scaffold(
            body: ScheduleDial(controller: c, day: bad.start),
          ),
        ),
      );
      expect(find.text('0 h 0 min'), findsOneWidget);
      expect(find.text('0 times'), findsOneWidget);
      expect(c.totalForDay(bad.start), const Duration(hours: 4, minutes: 7));
      await t.pumpWidget(
        MaterialApp(
          theme: trackerTheme(),
          home: Scaffold(
            body: HomePage(controller: c, day: now, onDay: (_) {}),
          ),
        ),
      );
      await t.scrollUntilVisible(find.text('Night sleep'), 300);
      expect(find.text('19 h 49 min'), findsNothing);
      expect(find.text('-'), findsWidgets);
    },
  );

  testWidgets(
    'original overlap dialog keeps the draft for Edit time and discards only the draft',
    (t) async {
      final c = TrackerController(
        MemoryStorage(),
        clock: () => DateTime(2026, 10, 2, 19, 49),
      );
      await c.load();
      await c.saveEntry(
        ActivityEntry(
          id: 'overnight',
          kind: ActivityKind.nap,
          start: DateTime(2026, 10, 1, 19, 53),
          end: c.now,
        ),
      );
      await t.pumpWidget(
        MaterialApp(
          theme: trackerTheme(),
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => showEditor(
                  context,
                  c,
                  ActivityKind.wakeUp,
                  initialStart: DateTime(2026, 10, 2, 8, 49),
                ),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );
      await t.tap(find.text('Open'));
      await t.pumpAndSettle();
      await t.tap(
        find.byKey(const ValueKey('debug_tracking_event_primary_button')),
      );
      await t.pumpAndSettle();
      expect(find.text('Overlapping Activity'), findsOneWidget);
      await t.tap(find.byKey(const ValueKey('overlap-edit-time')));
      await t.pumpAndSettle();
      expect(find.text('Overlapping Activity'), findsNothing);
      expect(
        find.byKey(const ValueKey('debug_tracking_event_primary_button')),
        findsOneWidget,
      );
      expect(c.entries.single.id, 'overnight');
      await t.tap(
        find.byKey(const ValueKey('debug_tracking_event_primary_button')),
      );
      await t.pumpAndSettle();
      await t.tap(find.byKey(const ValueKey('overlap-discard')));
      await t.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('debug_tracking_event_primary_button')),
        findsNothing,
      );
      expect(c.entries.single.id, 'overnight');
      expect(t.takeException(), isNull);
    },
  );

  testWidgets(
    'clearing a nap end requires confirmation and saves an unfinished timer',
    (t) async {
      final storage = MemoryStorage();
      final c = TrackerController(
        storage,
        clock: () => DateTime(2026, 10, 2, 12),
      );
      await c.load();
      final nap = ActivityEntry(
        id: 'completed',
        kind: ActivityKind.nap,
        start: DateTime(2026, 10, 2, 10),
        end: DateTime(2026, 10, 2, 11),
      );
      await c.saveEntry(nap);
      await t.pumpWidget(
        MaterialApp(
          theme: trackerTheme(),
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () =>
                    showEditor(context, c, ActivityKind.nap, entry: nap),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );
      await t.tap(find.text('Open'));
      await t.pumpAndSettle();
      await t.tap(
        find.byKey(const ValueKey('debug_tracking_end_time_delete_button')),
      );
      await t.pumpAndSettle();
      expect(find.text('Delete end time'), findsWidgets);
      await t.tap(find.text('Cancel'));
      await t.pumpAndSettle();
      expect(find.text('11:00 AM'), findsOneWidget);
      await t.tap(
        find.byKey(const ValueKey('debug_tracking_end_time_delete_button')),
      );
      await t.pumpAndSettle();
      await t.tap(find.byKey(const ValueKey('confirm-delete-end-time')));
      await t.pumpAndSettle();
      expect(c.entries.single.end, nap.end);
      expect(find.text('Set time'), findsOneWidget);
      await t.tap(
        find.byKey(const ValueKey('debug_tracking_event_primary_button')),
      );
      await t.pumpAndSettle();
      final reopened = TrackerController(storage, clock: () => c.now);
      await reopened.load();
      expect(reopened.active?.id, nap.id);
    },
  );

  for (final dayNumber in [1, 4]) {
    testWidgets('sleep ring computes recorded totals on October $dayNumber', (
      t,
    ) async {
      final day = DateTime(2026, 10, dayNumber);
      final c = TrackerController(
        MemoryStorage(),
        clock: () => DateTime(2026, 10, 5),
      );
      await c.load();
      await c.saveEntry(
        ActivityEntry(
          id: 'wake',
          kind: ActivityKind.wakeUp,
          start: day.add(const Duration(hours: 7, minutes: 20)),
        ),
      );
      var cursor = day.add(const Duration(hours: 8, minutes: 20));
      for (final minutes in [80, 78, 76, 74, 72]) {
        final end = cursor.add(Duration(minutes: minutes));
        await c.saveEntry(
          ActivityEntry(
            id: '$minutes',
            kind: ActivityKind.nap,
            start: cursor,
            end: end,
          ),
        );
        cursor = end.add(const Duration(hours: 1));
      }
      Future<void> mount() => t.pumpWidget(
        MaterialApp(
          theme: trackerTheme(),
          home: Scaffold(
            body: SizedBox(
              width: 412,
              child: ScheduleDial(controller: c, day: day),
            ),
          ),
        ),
      );
      await mount();
      expect(find.text('6 h 20 min'), findsOneWidget);
      expect(find.text('5 times'), findsOneWidget);
      final entry = c.entries.firstWhere((e) => e.id == '80');
      await c.saveEntry(
        entry.copyWith(end: entry.end!.subtract(const Duration(minutes: 20))),
      );
      await mount();
      expect(find.text('6 h 0 min'), findsOneWidget);
      expect(find.text('6 h 20 min'), findsNothing);
      expect(t.takeException(), isNull);
    });
  }

  testWidgets('a timer from yesterday stays visible today and can be stopped', (
    t,
  ) async {
    var now = DateTime(2026, 10, 2, 0, 5);
    final c = TrackerController(MemoryStorage(), clock: () => now);
    await c.load();
    await c.saveEntry(
      ActivityEntry(
        id: 'overnight',
        kind: ActivityKind.nap,
        start: DateTime(2026, 10, 1, 23, 55),
      ),
    );
    Future<void> mount() => t.pumpWidget(
      MaterialApp(
        theme: trackerTheme(),
        home: Scaffold(
          body: HomePage(controller: c, day: now, onDay: (_) {}),
        ),
      ),
    );
    await mount();
    expect(find.text('Running nap'), findsOneWidget);
    expect(find.text('00:10:00'), findsOneWidget);
    now = now.add(const Duration(seconds: 1));
    await mount();
    expect(find.text('00:10:01'), findsOneWidget);
    await t.tap(find.text('Stop timer'));
    await t.pumpAndSettle();
    expect(c.active, isNull);
    await c.saveEntry(
      ActivityEntry(id: 'new', kind: ActivityKind.nap, start: now),
    );
    expect(c.active?.id, 'new');
  });
  testWidgets(
    'historical Home exposes the active timer without replacing its summary',
    (t) async {
      final now = DateTime(2026, 10, 2, 12);
      final c = TrackerController(MemoryStorage(), clock: () => now);
      await c.load();
      await c.saveEntry(
        ActivityEntry(
          id: 'nap',
          kind: ActivityKind.nap,
          start: DateTime(2026, 10, 1, 23),
        ),
      );
      await t.pumpWidget(
        MaterialApp(
          theme: trackerTheme(),
          home: Scaffold(
            body: HomePage(
              controller: c,
              day: DateTime(2026, 10, 1),
              onDay: (_) {},
            ),
          ),
        ),
      );
      expect(find.byKey(const ValueKey('running-session')), findsOneWidget);
      expect(find.text('13:00:00'), findsOneWidget);
      await t.tap(find.text('Stop timer'));
      await t.pumpAndSettle();
      expect(c.active, isNull);
    },
  );

  testWidgets('prediction summary requires Log nap before creating a record', (
    t,
  ) async {
    final c = TrackerController(
      MemoryStorage(),
      clock: () => DateTime(2026, 10, 2, 12),
    );
    await c.load();
    await t.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showPredictionSummary(
                context,
                c,
                ActivityKind.nap,
                start: DateTime(2026, 10, 2, 9),
                end: DateTime(2026, 10, 2, 10, 20),
              ),
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );
    await t.tap(find.text('Open'));
    await t.pumpAndSettle();
    expect(find.text('Predicted nap'), findsOneWidget);
    expect(find.text('1 h 20 min'), findsOneWidget);
    expect(find.byKey(const ValueKey('save-entry')), findsNothing);
    expect(c.entries, isEmpty);
    await t.tap(find.text('Log nap'));
    await t.pumpAndSettle();
    expect(find.byKey(const ValueKey('save-entry')), findsOneWidget);
    await t.tap(find.byKey(const ValueKey('save-entry')));
    await t.pumpAndSettle();
    expect(c.entries.single.start, DateTime(2026, 10, 2, 9));
    expect(c.entries.single.end, DateTime(2026, 10, 2, 10, 20));
  });
  test(
    'untrained schedule uses observed default bedtime rather than wake offset',
    () {
      final day = DateTime(2026, 10, 1);
      final scale = DialScale([
        ActivityEntry(
          id: 'w',
          kind: ActivityKind.wakeUp,
          start: DateTime(2026, 10, 1, 7, 20),
        ),
      ], day);
      expect(scale.predictedBed, DateTime(2026, 10, 1, 22));
    },
  );
  test('historical title includes original weekday', () {
    expect(
      shortDate(DateTime(2026, 10, 1), DateTime(2026, 10, 2)),
      'Thursday, Oct 1',
    );
  });
  testWidgets(
    'wake marker stays on the dial rather than a separate lower row',
    (t) async {
      final c = TrackerController(
        MemoryStorage(),
        clock: () => DateTime(2026, 10, 2),
      );
      await c.load();
      await c.saveEntry(
        ActivityEntry(
          id: 'w',
          kind: ActivityKind.wakeUp,
          start: DateTime(2026, 10, 1, 7, 20),
        ),
      );
      await t.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Align(
              alignment: Alignment.topLeft,
              child: SizedBox(
                width: 412,
                child: ScheduleDial(controller: c, day: DateTime(2026, 10, 1)),
              ),
            ),
          ),
        ),
      );
      await t.pumpAndSettle();
      final dial = t.getRect(find.byType(ScheduleDial));
      final wake = t.getRect(
        find.byKey(const ValueKey('debug_wake_up_button')),
      );
      expect(wake.top - dial.top, lessThan(365));
      expect(dial.height, lessThan(450));
      expect(t.takeException(), isNull);
    },
  );
  testWidgets('past-day overview agrees with its completed dial total', (
    t,
  ) async {
    final c = TrackerController(
      MemoryStorage(),
      clock: () => DateTime(2026, 10, 2, 12),
    );
    await c.load();
    await c.saveEntry(
      ActivityEntry(
        id: 'n',
        kind: ActivityKind.nap,
        start: DateTime(2026, 10, 1, 9),
        end: DateTime(2026, 10, 1, 10),
      ),
    );
    await c.saveEntry(
      ActivityEntry(
        id: 'a',
        kind: ActivityKind.nap,
        start: DateTime(2026, 10, 1, 19),
      ),
    );
    await t.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: HomePage(
            controller: c,
            day: DateTime(2026, 10, 1),
            onDay: (_) {},
          ),
        ),
      ),
    );
    await t.pumpAndSettle();
    await t.scrollUntilVisible(find.text('Logged naps'), 300);
    expect(find.text('1 h 0 min'), findsWidgets);
    expect(find.text('6 h 0 min'), findsNothing);
    expect(t.takeException(), isNull);
  });
  test('missing birthday uses original zero-age six-nap forecast', () {
    final wake = DateTime(2026, 10, 5, 11, 23);
    final now = DateTime(2026, 10, 5, 11, 51, 30);
    final scale = DialScale(
      [ActivityEntry(id: 'w', kind: ActivityKind.wakeUp, start: wake)],
      now,
      const BabyProfile(),
      now,
    );
    expect(scale.scheduled.length, 6);
    expect(
      scale.scheduled
          .map(
            (n) =>
                '${n.start.hour}:${n.start.minute.toString().padLeft(2, '0')}',
          )
          .toList(),
      ['12:23', '14:45', '17:06', '19:26', '21:46', '0:05'],
    );
    expect(scale.scheduled.last.end.hour, 1);
    expect(scale.scheduled.last.end.minute, 14);
    expect(scale.predictedBed, DateTime(2026, 10, 6, 2, 23));
    expect(scale.scheduled.first.start.difference(now).inMinutes, 31);
  });

  test(
    'recovered initial schedule has six naps and a fifteen-hour newborn day',
    () {
      final day = DateTime(2026, 10, 2);
      final scale = DialScale(
        [
          ActivityEntry(
            id: 'w',
            kind: ActivityKind.wakeUp,
            start: DateTime(2026, 10, 2, 8),
          ),
        ],
        day,
        BabyProfile(birthday: DateTime(2026, 10, 1)),
        DateTime(2026, 10, 2, 8, 30),
      );
      expect(scale.scheduled.length, 6);
      expect(scale.scheduled.first.start, DateTime(2026, 10, 2, 9));
      expect(scale.scheduled.first.end.hour, 10);
      expect(scale.scheduled.first.end.minute, 20);
      // Sequential editor captures include logged-minute correction. They must
      // not be treated as an untouched initial schedule (see RECOVERY.md).
      expect(
        scale.scheduled
            .map((n) => n.end.difference(n.start).inMicroseconds)
            .reduce((a, b) => a + b),
        closeTo(450 * 60000000, 6),
      );
      expect(scale.predictedBed, DateTime(2026, 10, 2, 23));
    },
  );
  testWidgets('upcoming nap countdown leads and awake duration is secondary', (
    t,
  ) async {
    final c = TrackerController(
      MemoryStorage(),
      clock: () => DateTime(2026, 10, 2, 8, 30),
    );
    await c.load();
    await c.updateProfile(BabyProfile(birthday: DateTime(2026, 10, 1)));
    await c.saveEntry(
      ActivityEntry(
        id: 'w',
        kind: ActivityKind.wakeUp,
        start: DateTime(2026, 10, 2, 8),
      ),
    );
    await t.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ScheduleDial(controller: c, day: c.now),
        ),
      ),
    );
    await t.pumpAndSettle();
    final primary = t.widget<Text>(
      find.byKey(const ValueKey('debug_schedule_timer_current_label')),
    );
    final secondary = t.widget<Text>(
      find.byKey(const ValueKey('debug_schedule_timer_next_label')),
    );
    expect(primary.data, 'Nap starts in');
    expect(secondary.data, 'Awake for');
    expect(
      t
          .widget<Text>(
            find.byKey(const ValueKey('debug_schedule_timer_current_duration')),
          )
          .data,
      '30 min',
    );
  });
  testWidgets('missed window remains late rather than silently advancing', (
    t,
  ) async {
    final c = TrackerController(
      MemoryStorage(),
      clock: () => DateTime(2026, 10, 2, 11),
    );
    await c.load();
    await c.updateProfile(BabyProfile(birthday: DateTime(2026, 10, 1)));
    await c.saveEntry(
      ActivityEntry(
        id: 'w',
        kind: ActivityKind.wakeUp,
        start: DateTime(2026, 10, 2, 8),
      ),
    );
    await t.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ScheduleDial(controller: c, day: c.now),
        ),
      ),
    );
    await t.pumpAndSettle();
    expect(
      t
          .widget<Text>(
            find.byKey(const ValueKey('debug_schedule_timer_current_label')),
          )
          .data,
      'Late for nap',
    );
    expect(
      t
          .widget<Text>(
            find.byKey(const ValueKey('debug_schedule_timer_current_duration')),
          )
          .data,
      '2 h',
    );
  });
}
