import 'package:flutter_test/flutter_test.dart';
import 'package:baby_tracker/prediction.dart';

void main() {
  test('snapshot nap-count transitions select the last age threshold', () {
    for (final pair in <(double, int)>[
      (0, 6),
      (1.99, 6),
      (2, 4),
      (3.99, 4),
      (4, 3),
      (8.99, 3),
      (9, 2),
      (18.99, 2),
      (19, 1),
      (40, 1),
    ]) {
      expect(SleepBaseline.initialNapCount(pair.$1), pair.$2);
    }
  });
  test('sleep standards interpolate and clamp to original endpoints', () {
    expect(SleepBaseline.forAge(0).daySleep, 450);
    expect(SleepBaseline.forAge(1.5).daySleep, 420);
    expect(SleepBaseline.forAge(1.5).totalSleep, 975);
    expect(SleepBaseline.forAge(40).nightSleep, 615);
  });
  test('window distribution preserves totals and opposite nap ordering', () {
    final wake = SleepBaseline.windows(450, 7);
    final naps = SleepBaseline.windows(450, 6, reverse: true);
    expect(wake.first, closeTo(60, 1e-10));
    expect(wake.last, closeTo(68.5714285714, 1e-8));
    expect(naps.first, closeTo(80.7692307692, 1e-8));
    expect(naps.last, closeTo(69.2307692308, 1e-8));
    expect(wake.reduce((a, b) => a + b), closeTo(450, 1e-10));
    expect(naps.reduce((a, b) => a + b), closeTo(450, 1e-10));
    expect(SleepBaseline.windows(120, 1), [120]);
  });
}
