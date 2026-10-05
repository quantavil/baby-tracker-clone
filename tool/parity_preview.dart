// Test-only entrypoint. In-memory fixtures never read or write user preferences.
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:baby_tracker/app.dart';
import 'package:baby_tracker/controller.dart';
import 'package:baby_tracker/model.dart';
import 'package:baby_tracker/storage.dart';

class FixtureStorage implements TrackerStorage {
  String? value;
  @override
  Future<String?> read() async => value;
  @override
  Future<void> write(String data) async {
    value = data;
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Anchor the comparison date, but let interactive timers advance normally.
  final elapsed = Stopwatch()..start();
  const overlapCase = bool.fromEnvironment('OVERLAP_CASE');
  final fixtureNow = overlapCase
      ? DateTime(2026, 10, 2, 19, 50)
      : const bool.fromEnvironment('PAST_DAY')
      ? DateTime(2026, 10, 2, 19, 40)
      : DateTime(2026, 10, 1, 22, 8, 15);
  final c = TrackerController(
    FixtureStorage(),
    clock: () => fixtureNow.add(elapsed.elapsed),
  );
  await c.load();
  await c.updateProfile(const BabyProfile(name: 'Leo', birthday: null));
  await c.updateProfile(c.profile.copyWith(birthday: DateTime(2026, 10, 1)));
  await c.saveEntry(
    ActivityEntry(
      id: 'fixture-wake',
      kind: ActivityKind.wakeUp,
      start: DateTime(2026, 10, 1, 7, 20),
    ),
  );
  for (final span in [
    (8, 20, 9, 40),
    (10, 42, 12, 0),
    (13, 3, 14, 19),
    (15, 23, 16, 37),
    (17, 43, 18, 55),
  ]) {
    await c.saveEntry(
      ActivityEntry(
        id: 'fixture-${span.$1}',
        kind: ActivityKind.nap,
        start: DateTime(2026, 10, 1, span.$1, span.$2),
        end: DateTime(2026, 10, 1, span.$3, span.$4),
      ),
    );
  }
  if (const bool.fromEnvironment('WITH_ACTIVE_NAP')) {
    await c.saveEntry(
      ActivityEntry(
        id: 'fixture-active',
        kind: ActivityKind.nap,
        start: DateTime(2026, 10, 1, 19, 53, 34),
      ),
    );
  }
  if (overlapCase) {
    // Import a legacy conflict to reproduce the user's Friday screenshot.
    // Normal save validation must reject creating this state in the new app.
    final saved = jsonDecode(c.exportJson()) as Map<String, dynamic>;
    final entries = saved['entries'] as List;
    entries.removeWhere((e) => (e as Map)['id'] == 'fixture-active');
    entries.add(
      ActivityEntry(
        id: 'fixture-active',
        kind: ActivityKind.nap,
        start: DateTime(2026, 10, 1, 19, 53, 34),
        end: DateTime(2026, 10, 2, 19, 49),
      ).toJson(),
    );
    entries.add(
      ActivityEntry(
        id: 'fixture-friday-wake',
        kind: ActivityKind.wakeUp,
        start: DateTime(2026, 10, 2, 8, 49),
      ).toJson(),
    );
    await c.importJson(jsonEncode(saved));
  }
  runApp(BabyTrackerApp(controller: c));
}
