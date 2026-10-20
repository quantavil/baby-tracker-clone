import 'dart:math' as math;

/// Initial age standards and window distribution, taken from Baby Tracker 2.9.0.
/// Unverified until the next_nap_* experiments confirm them (see parity.md).
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

class DurationStandard {
  const DurationStandard(this.min, this.max);
  final Duration min, max;
}

class SleepNormBand {
  const SleepNormBand({
    required this.name,
    required this.ageThreshold,
    required this.nightSleep,
    required this.daySleep,
    required this.totalSleep,
    required this.daytimeAwake,
    required this.minNaps,
    required this.maxNaps,
    required this.wakeWindow,
  });
  final String name;
  final double ageThreshold;
  final DurationStandard nightSleep;
  final DurationStandard daySleep;
  final DurationStandard totalSleep;
  final DurationStandard daytimeAwake;
  final int minNaps;
  final int maxNaps;
  final DurationStandard wakeWindow;
}

/// 17 reference age bands recovered from pool slot pp+0xc778 and
/// ReferenceSleepNorms.forAgeInMonths (0x8b0480).
class ReferenceSleepNorms {
  static Duration _m(int minutes) => Duration(minutes: minutes);

  static final List<SleepNormBand> bands = [
    SleepNormBand(
      name: '0-4 weeks',
      ageThreshold: 0.0,
      nightSleep: DurationStandard(_m(510), _m(600)),
      daySleep: DurationStandard(_m(360), _m(540)),
      totalSleep: DurationStandard(_m(870), _m(1140)),
      daytimeAwake: DurationStandard(_m(300), _m(570)),
      minNaps: 4,
      maxNaps: 6,
      wakeWindow: DurationStandard(_m(30), _m(60)),
    ),
    SleepNormBand(
      name: '1 month',
      ageThreshold: 1.0,
      nightSleep: DurationStandard(_m(510), _m(600)),
      daySleep: DurationStandard(_m(360), _m(540)),
      totalSleep: DurationStandard(_m(870), _m(1140)),
      daytimeAwake: DurationStandard(_m(300), _m(570)),
      minNaps: 4,
      maxNaps: 5,
      wakeWindow: DurationStandard(_m(45), _m(60)),
    ),
    SleepNormBand(
      name: '2 months',
      ageThreshold: 2.0,
      nightSleep: DurationStandard(_m(540), _m(600)),
      daySleep: DurationStandard(_m(240), _m(360)),
      totalSleep: DurationStandard(_m(780), _m(960)),
      daytimeAwake: DurationStandard(_m(480), _m(660)),
      minNaps: 3,
      maxNaps: 5,
      wakeWindow: DurationStandard(_m(45), _m(90)),
    ),
    SleepNormBand(
      name: '3 months',
      ageThreshold: 3.0,
      nightSleep: DurationStandard(_m(600), _m(660)),
      daySleep: DurationStandard(_m(180), _m(300)),
      totalSleep: DurationStandard(_m(780), _m(960)),
      daytimeAwake: DurationStandard(_m(480), _m(660)),
      minNaps: 3,
      maxNaps: 4,
      wakeWindow: DurationStandard(_m(75), _m(120)),
    ),
    SleepNormBand(
      name: '4 months',
      ageThreshold: 4.0,
      nightSleep: DurationStandard(_m(600), _m(720)),
      daySleep: DurationStandard(_m(180), _m(240)),
      totalSleep: DurationStandard(_m(780), _m(960)),
      daytimeAwake: DurationStandard(_m(480), _m(660)),
      minNaps: 3,
      maxNaps: 4,
      wakeWindow: DurationStandard(_m(75), _m(120)),
    ),
    SleepNormBand(
      name: '5 months',
      ageThreshold: 5.0,
      nightSleep: DurationStandard(_m(600), _m(720)),
      daySleep: DurationStandard(_m(150), _m(210)),
      totalSleep: DurationStandard(_m(750), _m(930)),
      daytimeAwake: DurationStandard(_m(510), _m(690)),
      minNaps: 3,
      maxNaps: 3,
      wakeWindow: DurationStandard(_m(120), _m(180)),
    ),
    SleepNormBand(
      name: '6 months',
      ageThreshold: 6.0,
      nightSleep: DurationStandard(_m(600), _m(720)),
      daySleep: DurationStandard(_m(150), _m(210)),
      totalSleep: DurationStandard(_m(750), _m(930)),
      daytimeAwake: DurationStandard(_m(510), _m(690)),
      minNaps: 2,
      maxNaps: 3,
      wakeWindow: DurationStandard(_m(120), _m(180)),
    ),
    SleepNormBand(
      name: '7-8 months',
      ageThreshold: 7.0,
      nightSleep: DurationStandard(_m(660), _m(720)),
      daySleep: DurationStandard(_m(120), _m(180)),
      totalSleep: DurationStandard(_m(780), _m(900)),
      daytimeAwake: DurationStandard(_m(540), _m(660)),
      minNaps: 2,
      maxNaps: 3,
      wakeWindow: DurationStandard(_m(150), _m(210)),
    ),
    SleepNormBand(
      name: '9-10 months',
      ageThreshold: 9.0,
      nightSleep: DurationStandard(_m(660), _m(720)),
      daySleep: DurationStandard(_m(120), _m(180)),
      totalSleep: DurationStandard(_m(780), _m(900)),
      daytimeAwake: DurationStandard(_m(540), _m(660)),
      minNaps: 2,
      maxNaps: 2,
      wakeWindow: DurationStandard(_m(150), _m(210)),
    ),
    SleepNormBand(
      name: '11-12 months',
      ageThreshold: 11.0,
      nightSleep: DurationStandard(_m(660), _m(720)),
      daySleep: DurationStandard(_m(120), _m(150)),
      totalSleep: DurationStandard(_m(780), _m(870)),
      daytimeAwake: DurationStandard(_m(570), _m(660)),
      minNaps: 2,
      maxNaps: 2,
      wakeWindow: DurationStandard(_m(180), _m(240)),
    ),
    SleepNormBand(
      name: '13-15 months',
      ageThreshold: 13.0,
      nightSleep: DurationStandard(_m(660), _m(720)),
      daySleep: DurationStandard(_m(120), _m(150)),
      totalSleep: DurationStandard(_m(780), _m(870)),
      daytimeAwake: DurationStandard(_m(570), _m(660)),
      minNaps: 1,
      maxNaps: 2,
      wakeWindow: DurationStandard(_m(180), _m(240)),
    ),
    SleepNormBand(
      name: '16-18 months',
      ageThreshold: 16.0,
      nightSleep: DurationStandard(_m(660), _m(720)),
      daySleep: DurationStandard(_m(90), _m(150)),
      totalSleep: DurationStandard(_m(750), _m(870)),
      daytimeAwake: DurationStandard(_m(570), _m(690)),
      minNaps: 1,
      maxNaps: 1,
      wakeWindow: DurationStandard(_m(240), _m(360)),
    ),
    SleepNormBand(
      name: '18-24 months',
      ageThreshold: 18.0,
      nightSleep: DurationStandard(_m(660), _m(720)),
      daySleep: DurationStandard(_m(60), _m(120)),
      totalSleep: DurationStandard(_m(720), _m(840)),
      daytimeAwake: DurationStandard(_m(600), _m(720)),
      minNaps: 1,
      maxNaps: 1,
      wakeWindow: DurationStandard(_m(300), _m(360)),
    ),
    SleepNormBand(
      name: '2-3 years',
      ageThreshold: 24.0,
      nightSleep: DurationStandard(_m(660), _m(720)),
      daySleep: DurationStandard(_m(60), _m(120)),
      totalSleep: DurationStandard(_m(720), _m(840)),
      daytimeAwake: DurationStandard(_m(660), _m(780)),
      minNaps: 0,
      maxNaps: 1,
      wakeWindow: DurationStandard(_m(300), _m(360)),
    ),
    SleepNormBand(
      name: '3-5 years',
      ageThreshold: 36.0,
      nightSleep: DurationStandard(_m(660), _m(720)),
      daySleep: DurationStandard(_m(0), _m(60)),
      totalSleep: DurationStandard(_m(660), _m(780)),
      daytimeAwake: DurationStandard(_m(660), _m(780)),
      minNaps: 0,
      maxNaps: 1,
      wakeWindow: DurationStandard(_m(300), _m(360)),
    ),
    SleepNormBand(
      name: '6-12 years',
      ageThreshold: 72.0,
      nightSleep: DurationStandard(_m(540), _m(660)),
      daySleep: DurationStandard(_m(0), _m(0)),
      totalSleep: DurationStandard(_m(540), _m(660)),
      daytimeAwake: DurationStandard(_m(780), _m(900)),
      minNaps: 0,
      maxNaps: 0,
      wakeWindow: DurationStandard(_m(360), _m(480)),
    ),
    SleepNormBand(
      name: '13-18 years',
      ageThreshold: 156.0,
      nightSleep: DurationStandard(_m(480), _m(600)),
      daySleep: DurationStandard(_m(0), _m(0)),
      totalSleep: DurationStandard(_m(480), _m(600)),
      daytimeAwake: DurationStandard(_m(840), _m(960)),
      minNaps: 0,
      maxNaps: 0,
      wakeWindow: DurationStandard(_m(480), _m(600)),
    ),
  ];

  static SleepNormBand forAgeInMonths(double months) {
    for (var i = bands.length - 1; i >= 0; i--) {
      if (months >= bands[i].ageThreshold) {
        return bands[i];
      }
    }
    return bands.first;
  }
}

/// Adaptive nap count predictor recovered from 0x801844.
class NapCountPredictor {
  static int predict({
    required double ageInMonths,
    required List<int> historyNaps,
    int? elapsedDaysSinceLast,
    int? customNapCount,
  }) {
    if (customNapCount != null && customNapCount > 0) {
      return customNapCount;
    }
    final norm = ReferenceSleepNorms.forAgeInMonths(ageInMonths);
    if (historyNaps.length < 3) {
      return norm.maxNaps;
    }
    if (isUnrealisticNapData(historyNaps)) {
      return norm.maxNaps;
    }
    final lastNapCount = historyNaps.last;
    if (elapsedDaysSinceLast != null && elapsedDaysSinceLast >= 3) {
      return math.min(lastNapCount, norm.maxNaps);
    }
    if (lastNapCount >= norm.minNaps && lastNapCount <= norm.maxNaps) {
      final sampleCount = historyNaps.length >= 5 ? 5 : 3;
      final sample = historyNaps.sublist(historyNaps.length - sampleCount);
      final avg = sample.reduce((a, b) => a + b) / sample.length;
      return avg.round().clamp(norm.minNaps, norm.maxNaps);
    }
    // Check 3 consecutive extremes
    if (historyNaps.length >= 3) {
      final last3 = historyNaps.sublist(historyNaps.length - 3);
      if (last3.every((c) => c > norm.maxNaps)) {
        return norm.maxNaps + 1;
      }
      if (last3.every((c) => c < norm.minNaps)) {
        return math.max(1, norm.minNaps - 1);
      }
    }
    final sampleCount = historyNaps.length >= 5 ? 5 : 3;
    final sample = historyNaps.sublist(historyNaps.length - sampleCount);
    final avg = sample.reduce((a, b) => a + b) / sample.length;
    return avg.round().clamp(math.max(1, norm.minNaps - 1), norm.maxNaps + 1);
  }

  static bool isUnrealisticNapData(List<int> history) =>
      history.any((c) => c < 0 || c > 10);
}

/// Correction rules for micro-naps and spread adjustments recovered from
/// PredictCorrection (0x8030c4) and Windows.spread (0x80606c).
class PredictCorrection {
  static const double microNapMinutes = 10.0;
  static const double minPostMicroNapWakeWindowMinutes = 60.0;

  static bool isMicroNap(Duration duration) =>
      duration.inMinutes <= microNapMinutes;

  static Duration adjustLastWakeWindowAfterMicroNap(
    Duration previousWakeWindow,
    Duration microNapDuration,
  ) {
    final remaining = previousWakeWindow - microNapDuration;
    final clamped = math.max(
      minPostMicroNapWakeWindowMinutes,
      remaining.inMinutes.toDouble(),
    );
    return Duration(minutes: clamped.round());
  }
}

class Windows {
  static List<Duration> spread(List<Duration> windows, Duration delta) {
    if (windows.isEmpty) return const [];
    final sumMinutes = windows.fold<double>(0.0, (s, w) => s + w.inMinutes);
    if (sumMinutes <= 0) return windows;
    final deltaMinutes = delta.inMinutes.toDouble();
    return windows.map((w) {
      final proportion = w.inMinutes / sumMinutes;
      final adjusted = w.inMinutes + (deltaMinutes * proportion);
      return Duration(minutes: math.max(15, adjusted.round()));
    }).toList();
  }
}

enum WakeWindowStatus { ok, short, long, current }

class WakeWindowItem {
  const WakeWindowItem({
    required this.index,
    required this.start,
    this.end,
    required this.duration,
    required this.status,
  });
  final int index;
  final DateTime start;
  final DateTime? end;
  final Duration duration;
  final WakeWindowStatus status;

  bool get isCurrent => status == WakeWindowStatus.current;

  String get ordinalLabel {
    final s = switch (index) {
      1 => '1st',
      2 => '2nd',
      3 => '3rd',
      _ => '${index}th',
    };
    return '$s wake window';
  }
}
