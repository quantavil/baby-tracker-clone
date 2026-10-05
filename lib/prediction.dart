import 'dart:math' as math;

/// Initial age standards and window distribution recovered from Baby Tracker
/// 2.9.0's Dart snapshot. Receipts: docs/faithful-reconstruction/RECOVERY.md.
/// Historical adaptation and micro-nap correction are separate algorithms.
class SleepBaseline {
  const SleepBaseline(this.totalSleep, this.nightSleep, this.daySleep);
  final double totalSleep, nightSleep, daySleep;
  double get awake => 1440 - totalSleep;
  double get dayLength => 1440 - nightSleep;

  static const _standards = <List<double>>[
    [1, 990, 540, 450],
    [2, 960, 540, 390],
    [3, 900, 600, 330],
    [4.5, 900, 585, 270],
    [7, 870, 645, 210],
    [10.5, 840, 645, 165],
    [15.5, 810, 675, 135],
    [24.5, 765, 645, 120],
    [33.5, 720, 615, 75],
  ];

  static SleepBaseline forAge(double months) {
    final age = months.clamp(_standards.first[0], _standards.last[0]);
    var upper = _standards.indexWhere((s) => s[0] >= age);
    upper = math.max(0, upper);
    final b = _standards[upper];
    final a = _standards[math.max(0, upper - 1)];
    final t = a[0] == b[0] ? 0.0 : (age - a[0]) / (b[0] - a[0]);
    double value(int index) => a[index] + (b[index] - a[index]) * t;
    return SleepBaseline(value(1), value(2), value(3));
  }

  /// findRangeForAge selects the last threshold <= age; insufficient tracked
  /// days return that range's maximum in NapCountPredictor.predict.
  static int initialNapCount(double months) {
    const ranges = [(1, 6), (2, 4), (4, 3), (6, 3), (9, 2), (13, 2), (19, 1)];
    return ranges
        .lastWhere((r) => months >= r.$1, orElse: () => ranges.first)
        .$2;
  }

  static List<double> windows(
    double totalMinutes,
    int count, {
    bool reverse = false,
  }) {
    if (count <= 0) return const [];
    if (count == 1) return [totalMinutes];
    final n = math.max(count, 3);
    final raw = List.generate(
      count,
      (i) => totalMinutes * (1 + i / (n * (n - 1))),
    );
    final sum = raw.fold(0.0, (a, b) => a + b);
    final normalized = raw.map((v) => v * totalMinutes / sum).toList();
    return reverse ? normalized.reversed.toList() : normalized;
  }

  static Duration minutes(double value) =>
      Duration(microseconds: (value * 60000000).truncate());
}
