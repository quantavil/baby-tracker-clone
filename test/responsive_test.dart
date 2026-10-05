import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:baby_tracker/controller.dart';
import 'package:baby_tracker/model.dart';
import 'package:baby_tracker/ui/share.dart';
import 'package:baby_tracker/ui/stats.dart';
import 'package:baby_tracker/storage.dart';

class Store implements TrackerStorage {
  @override
  Future<String?> read() async => null;
  @override
  Future<void> write(String s) async {}
}

void main() {
  for (final kind in ['share', 'stats']) {
    testWidgets('$kind narrow large text', (t) async {
      t.view.physicalSize = const Size(320, 900);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.resetPhysicalSize);
      addTearDown(t.view.resetDevicePixelRatio);
      final c = TrackerController(
        Store(),
        clock: () => DateTime(2026, 10, 2, 12),
      );
      await c.load();
      await c.saveEntry(
        ActivityEntry(
          id: 'n',
          kind: ActivityKind.nap,
          start: DateTime(2026, 10, 2, 9),
          end: DateTime(2026, 10, 2, 10),
        ),
      );
      await t.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(320, 900),
              textScaler: TextScaler.linear(2),
            ),
            child: Scaffold(
              body: kind == 'share'
                  ? SharePreview(controller: c, day: c.now)
                  : StatsPage(controller: c),
            ),
          ),
        ),
      );
      await t.pumpAndSettle();
      expect(t.takeException(), isNull);
    });
  }
}
