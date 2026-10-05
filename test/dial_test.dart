import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:baby_tracker/model.dart';
import 'package:baby_tracker/ui/dial.dart';

void main() {
  test('dial does not paint paused wall time as sleep', () async {
    final now = DateTime(2026, 10, 1, 10);
    final entry = ActivityEntry(
      id: 'a',
      kind: ActivityKind.nap,
      start: DateTime(2026, 10, 1, 8),
      pauses: [PausePeriod(DateTime(2026, 10, 1, 8, 30), null)],
    );
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    DialPainter(
      entries: [entry],
      day: now,
      now: now,
    ).paint(canvas, const Size(400, 400));
    final picture = recorder.endRecording();
    final image = await picture.toImage(400, 400);
    final bytes = (await image.toByteData(format: ui.ImageByteFormat.rawRgba))!;
    int redAt(int minutes) {
      final angle = math.pi * .75 + math.pi * 1.5 * minutes / 1440;
      final x = (200 + 172 * math.cos(angle)).round();
      final y = (200 + 172 * math.sin(angle)).round();
      return bytes.getUint8((y * 400 + x) * 4);
    }

    expect(redAt(8 * 60 + 15), greaterThan(150));
    expect(redAt(9 * 60 + 15), lessThan(140));
    image.dispose();
    picture.dispose();
  });
}
