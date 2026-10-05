enum ActivityKind {
  wakeUp('Wake-up', 'wake_up'),
  nap('Nap', 'nap'),
  bedtime('Bedtime', 'bedtime'),
  nightWaking('Night waking', 'night_waking'),
  nursing('Nursing', 'nursing'),
  bottleFeeding('Bottle feeding', 'bottle_feeding'),
  solids('Solids', 'solids'),
  diaperChange('Diaper change', 'diaper_change');

  const ActivityKind(this.label, this.asset);
  final String label;
  final String asset;
  bool get interval => this == nap || this == nightWaking || this == nursing;
}

class PausePeriod {
  const PausePeriod(this.start, this.end);
  final DateTime start;
  final DateTime? end;
  Map<String, dynamic> toJson() => {
    'start': start.toIso8601String(),
    'end': end?.toIso8601String(),
  };
  factory PausePeriod.fromJson(Map<String, dynamic> j) => PausePeriod(
    DateTime.parse(j['start'] as String),
    j['end'] == null ? null : DateTime.parse(j['end'] as String),
  );
}

const double kMlPerFlOz = 29.5735295625;
const double kGramsPerOz = 28.349523125;

/// Amounts are persisted in ml (bottle) or g (solids), independent of display units.
class TrackingDetails {
  const TrackingDetails({this.amount, this.choice = '', this.food = ''});
  final double? amount;
  final String choice, food;
  Map<String, dynamic> toJson() => {
    'amount': amount,
    'choice': choice,
    'food': food,
  };
  factory TrackingDetails.fromJson(Map<String, dynamic> j) => TrackingDetails(
    amount: (j['amount'] as num?)?.toDouble(),
    choice: j['choice'] as String? ?? '',
    food: j['food'] as String? ?? '',
  );
}

class ActivityEntry {
  ActivityEntry({
    required this.id,
    required this.kind,
    required this.start,
    this.end,
    this.note = '',
    this.details = const TrackingDetails(),
    List<PausePeriod> pauses = const [],
  }) : pauses = List.unmodifiable(pauses);
  final String id;
  final ActivityKind kind;
  final DateTime start;
  final DateTime? end;
  final String note;
  final TrackingDetails details;
  final List<PausePeriod> pauses;
  bool get ongoing => kind.interval && end == null;
  bool get paused => ongoing && pauses.isNotEmpty && pauses.last.end == null;
  ActivityEntry copyWith({DateTime? end, List<PausePeriod>? pauses}) =>
      ActivityEntry(
        id: id,
        kind: kind,
        start: start,
        end: end ?? this.end,
        note: note,
        details: details,
        pauses: pauses ?? this.pauses,
      );

  /// Sleep/awake segments with persisted pauses removed.
  List<({DateTime start, DateTime end})> activeSegments(DateTime now) {
    final finish = end ?? now;
    var cursor = start;
    final segments = <({DateTime start, DateTime end})>[];
    for (final pause in pauses) {
      final before = pause.start.isBefore(finish) ? pause.start : finish;
      if (before.isAfter(cursor)) segments.add((start: cursor, end: before));
      cursor = pause.end ?? finish;
      if (!cursor.isBefore(finish)) break;
    }
    if (finish.isAfter(cursor)) segments.add((start: cursor, end: finish));
    return segments;
  }

  /// Translate the paused pattern with a corrected start and clip to new bounds.
  ActivityEntry revised({
    required DateTime start,
    required DateTime? end,
    required String note,
    TrackingDetails? details,
  }) {
    final shift = start.difference(this.start);
    final updated = <PausePeriod>[];
    for (final p in pauses) {
      var a = p.start.add(shift);
      var b = p.end?.add(shift);
      if (a.isBefore(start)) a = start;
      if (end != null) {
        if (!a.isBefore(end)) continue;
        if (b == null || b.isAfter(end)) b = end;
      }
      if (b != null && !b.isAfter(a)) continue;
      updated.add(PausePeriod(a, b));
    }
    return ActivityEntry(
      id: id,
      kind: kind,
      start: start,
      end: end,
      note: note,
      pauses: updated,
      details: details ?? this.details,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'kind': kind.name,
    'start': start.toIso8601String(),
    'end': end?.toIso8601String(),
    'note': note,
    'details': details.toJson(),
    'pauses': pauses.map((p) => p.toJson()).toList(),
  };
  factory ActivityEntry.fromJson(Map<String, dynamic> j) => ActivityEntry(
    id: j['id'] as String,
    kind: ActivityKind.values.byName(j['kind'] as String),
    start: DateTime.parse(j['start'] as String),
    end: j['end'] == null ? null : DateTime.parse(j['end'] as String),
    note: j['note'] as String,
    details: j['details'] == null
        ? const TrackingDetails()
        : TrackingDetails.fromJson(
            Map<String, dynamic>.from(j['details'] as Map),
          ),
    pauses: (j['pauses'] as List)
        .map((p) => PausePeriod.fromJson(Map<String, dynamic>.from(p as Map)))
        .toList(),
  );
}

class BabyProfile {
  const BabyProfile({
    this.name = 'Baby',
    this.birthday,
    this.use24Hour = false,
    this.metric = true,
    this.notifications = false,
    this.customNaps = false,
    this.napCount = 2,
    this.customWakeUp = false,
    this.wakeUpMinutes = 420,
  });
  final String name;
  final DateTime? birthday;
  final bool use24Hour, metric, notifications, customNaps, customWakeUp;
  final int napCount, wakeUpMinutes;
  BabyProfile copyWith({
    String? name,
    DateTime? birthday,
    bool? use24Hour,
    bool? metric,
    bool? notifications,
    bool? customNaps,
    int? napCount,
    bool? customWakeUp,
    int? wakeUpMinutes,
  }) => BabyProfile(
    name: name ?? this.name,
    birthday: birthday ?? this.birthday,
    use24Hour: use24Hour ?? this.use24Hour,
    metric: metric ?? this.metric,
    notifications: notifications ?? this.notifications,
    customNaps: customNaps ?? this.customNaps,
    napCount: napCount ?? this.napCount,
    customWakeUp: customWakeUp ?? this.customWakeUp,
    wakeUpMinutes: wakeUpMinutes ?? this.wakeUpMinutes,
  );
  Map<String, dynamic> toJson() => {
    'name': name,
    'birthday': birthday?.toIso8601String(),
    'use24Hour': use24Hour,
    'metric': metric,
    'notifications': notifications,
    'customNaps': customNaps,
    'napCount': napCount,
    'customWakeUp': customWakeUp,
    'wakeUpMinutes': wakeUpMinutes,
  };
  factory BabyProfile.fromJson(Map<String, dynamic> j) => BabyProfile(
    name: j['name'] as String,
    birthday: j['birthday'] == null
        ? null
        : DateTime.parse(j['birthday'] as String),
    use24Hour: j['use24Hour'] as bool,
    metric: j['metric'] as bool,
    notifications: j['notifications'] as bool,
    customNaps: j['customNaps'] as bool,
    napCount: j['napCount'] as int,
    customWakeUp: j['customWakeUp'] as bool,
    wakeUpMinutes: j['wakeUpMinutes'] as int,
  );
}
