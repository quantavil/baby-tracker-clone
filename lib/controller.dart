import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'model.dart';
import 'storage.dart';

class ActivityOverlapError extends ArgumentError {
  ActivityOverlapError()
    : super('This activity overlaps with an existing one.');
}

bool _wakeInsideNap(ActivityEntry a, ActivityEntry b) {
  final nap = a.kind == ActivityKind.nap ? a : b;
  final wake = a.kind == ActivityKind.wakeUp ? a : b;
  if (nap.kind != ActivityKind.nap || wake.kind != ActivityKind.wakeUp) {
    return false;
  }
  return nap.start.isBefore(wake.start) &&
      (nap.end == null || nap.end!.isAfter(wake.start));
}

class TrackerController extends ChangeNotifier {
  TrackerController(this._storage, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;
  final TrackerStorage _storage;
  final DateTime Function() _clock;
  DateTime get now => _clock();

  /// HomeTabCubit scans offsets 0..29 from AppClock.now (0x8af5df).
  /// Calendar-date nap grouping remains provisional until logical-day mapping
  /// and the original qualifying-day fields are fully interpreted.
  int get learningDays {
    final current = now;
    final today = DateTime(current.year, current.month, current.day);
    final first = DateTime(today.year, today.month, today.day - 29);
    final dates = entries
        .where((e) => e.kind == ActivityKind.nap)
        .map((e) => DateTime(e.start.year, e.start.month, e.start.day))
        .where((date) => !date.isBefore(first) && !date.isAfter(today))
        .toSet();
    return dates.length.clamp(1, 3);
  }

  List<ActivityEntry> _entries = const [];
  BabyProfile _profile = const BabyProfile();
  String? _error;
  bool _loaded = false, _writing = false;
  List<ActivityEntry> get entries => _entries;
  BabyProfile get profile => _profile;
  String? get error => _error;
  bool get loaded => _loaded;
  bool get writing => _writing;
  ActivityEntry? get active => _entries
      .where((e) => e.ongoing && e.kind != ActivityKind.nursing)
      .firstOrNull;
  ActivityEntry? get activeNursing => _entries
      .where((e) => e.ongoing && e.kind == ActivityKind.nursing)
      .firstOrNull;
  Future<void> finishNursing() async {
    final e = activeNursing;
    if (e == null) return;
    await saveEntry(e.copyWith(end: now));
  }

  Future<void> load() async {
    try {
      final raw = await _storage.read();
      if (raw != null) {
        final j = jsonDecode(raw) as Map<String, dynamic>;
        if (j['version'] != 1) {
          throw const FormatException('Unsupported saved version');
        }
        final profile = BabyProfile.fromJson(
          Map<String, dynamic>.from(j['profile'] as Map),
        );
        final entries = (j['entries'] as List)
            .map(
              (e) =>
                  ActivityEntry.fromJson(Map<String, dynamic>.from(e as Map)),
            )
            .toList();
        _validateProfile(profile);
        if (entries.map((e) => e.id).toSet().length != entries.length ||
            entries
                    .where((e) => e.ongoing && e.kind != ActivityKind.nursing)
                    .length >
                1 ||
            entries
                    .where((e) => e.ongoing && e.kind == ActivityKind.nursing)
                    .length >
                1) {
          throw const FormatException('Invalid saved records');
        }
        for (final e in entries) {
          _validateEntry(e);
        }
        _entries = List.unmodifiable(entries);
        _profile = profile;
      } else {
        _entries = const [];
        _profile = const BabyProfile();
      }
      _error = null;
    } catch (_) {
      _error =
          'Saved data could not be read. Your stored data has been kept. Retry loading or restore a valid backup.';
    }
    _loaded = true;
    notifyListeners();
  }

  void _validateProfile(BabyProfile p) {
    if (p.name.trim().isEmpty || p.name.length > 80) {
      throw ArgumentError('Enter a name of 1–80 characters');
    }
    if (p.birthday != null && p.birthday!.isAfter(now)) {
      throw ArgumentError('Birthday cannot be in the future');
    }
    if (p.napCount < 1 ||
        p.napCount > 8 ||
        p.wakeUpMinutes < 180 ||
        p.wakeUpMinutes > 900) {
      throw ArgumentError('Choose a valid sleep preference');
    }
  }

  void _validateEntry(ActivityEntry e) {
    final amount = e.details.amount;
    if (amount != null && (!amount.isFinite || amount <= 0)) {
      throw ArgumentError('Enter an amount greater than zero');
    }
    final choices = switch (e.kind) {
      ActivityKind.nursing => ['Left', 'Right', 'Both'],
      ActivityKind.bottleFeeding => ['Breast milk', 'Formula'],
      ActivityKind.diaperChange => ['Wet', 'Dirty', 'Mixed', 'Dry'],
      _ => <String>[],
    };
    if (e.details.choice.isNotEmpty && !choices.contains(e.details.choice)) {
      throw ArgumentError('Choose a valid activity type');
    }
    if (e.id.isEmpty ||
        e.start.isAfter(now) ||
        (e.end?.isAfter(now) ?? false)) {
      throw ArgumentError('Activity time cannot be in the future');
    }
    if (e.kind == ActivityKind.wakeUp &&
        (e.start.hour * 60 + e.start.minute < 180 ||
            e.start.hour * 60 + e.start.minute > 900)) {
      throw ArgumentError('Choose wake-up between 3:00 AM and 3:00 PM');
    }
    if (e.kind.interval && e.end != null && !e.end!.isAfter(e.start)) {
      throw ArgumentError('End must be after start');
    }
    if (!e.kind.interval && (e.end != null || e.pauses.isNotEmpty)) {
      throw ArgumentError('This activity has only one time');
    }
    DateTime boundary = e.start;
    for (final p in e.pauses) {
      if (p.start.isBefore(boundary) ||
          p.start.isAfter(e.end ?? now) ||
          (p.end != null &&
              (p.end!.isBefore(p.start) || p.end!.isAfter(e.end ?? now)))) {
        throw ArgumentError('Invalid paused interval');
      }
      if (p.end == null && (!e.ongoing || p != e.pauses.last)) {
        throw ArgumentError('Invalid open pause');
      }
      boundary = p.end ?? now;
    }
  }

  Future<void> _commit(
    List<ActivityEntry> entries,
    BabyProfile profile, {
    bool restoring = false,
  }) async {
    if (!_loaded || (_error != null && !restoring)) {
      throw StateError(
        'Saved data must be loaded successfully before changing it',
      );
    }
    if (_writing) throw StateError('A save is already in progress');
    _writing = true;
    notifyListeners();
    try {
      await _storage.write(
        jsonEncode({
          'version': 1,
          'profile': profile.toJson(),
          'entries': entries.map((e) => e.toJson()).toList(),
        }),
      );
      _entries = List.unmodifiable(entries);
      _profile = profile;
      if (restoring) _error = null;
    } finally {
      _writing = false;
      notifyListeners();
    }
  }

  Future<void> saveEntry(ActivityEntry e) async {
    _validateEntry(e);
    if (_entries.any((other) => other.id != e.id && _wakeInsideNap(e, other))) {
      throw ActivityOverlapError();
    }
    if (e.ongoing &&
        _entries.any(
          (a) =>
              a.ongoing &&
              a.id != e.id &&
              (a.kind == ActivityKind.nursing) ==
                  (e.kind == ActivityKind.nursing),
        )) {
      throw ArgumentError('Stop the current timer before starting another');
    }
    final updated = [..._entries.where((a) => a.id != e.id), e]
      ..sort((a, b) => b.start.compareTo(a.start));
    await _commit(updated, _profile);
  }

  Future<void> deleteEntry(String id) =>
      _commit(_entries.where((e) => e.id != id).toList(), _profile);
  Future<void> updateProfile(BabyProfile profile) async {
    _validateProfile(profile);
    await _commit(_entries, profile.copyWith(name: profile.name.trim()));
  }

  Future<void> pause() async {
    final e = active;
    if (e == null || e.paused) return;
    await saveEntry(e.copyWith(pauses: [...e.pauses, PausePeriod(now, null)]));
  }

  Future<void> resume() async {
    final e = active;
    if (e == null || !e.paused) return;
    await saveEntry(
      e.copyWith(
        pauses: [
          ...e.pauses.take(e.pauses.length - 1),
          PausePeriod(e.pauses.last.start, now),
        ],
      ),
    );
  }

  Future<void> stop() async {
    final e = active;
    if (e == null) return;
    final end = now;
    if (!end.isAfter(e.start)) {
      throw ArgumentError('Let the timer run before stopping it');
    }
    final pauses = e.paused
        ? [
            ...e.pauses.take(e.pauses.length - 1),
            PausePeriod(e.pauses.last.start, end),
          ]
        : e.pauses;
    await saveEntry(e.copyWith(end: end, pauses: pauses));
  }

  Duration elapsed(ActivityEntry e) =>
      _durationBetween(e, e.start, e.end ?? now);
  Duration _durationBetween(ActivityEntry e, DateTime from, DateTime to) {
    final left = e.start.isAfter(from) ? e.start : from;
    final right = (e.end ?? now).isBefore(to) ? e.end ?? now : to;
    if (!right.isAfter(left)) return Duration.zero;
    var duration = right.difference(left);
    for (final p in e.pauses) {
      final a = p.start.isAfter(left) ? p.start : left;
      final b = (p.end ?? now).isBefore(right) ? p.end ?? now : right;
      if (b.isAfter(a)) duration -= b.difference(a);
    }
    return duration.isNegative ? Duration.zero : duration;
  }

  Duration totalForDay(
    DateTime day, {
    bool includeOngoing = true,
    bool forSchedule = false,
  }) {
    final from = DateTime(day.year, day.month, day.day);
    final to = DateTime(day.year, day.month, day.day + 1);
    final segments = <({DateTime start, DateTime end})>[];
    final source = forSchedule ? scheduleEntriesForDay(day) : _entries;
    for (final entry in source.where(
      (e) => e.kind == ActivityKind.nap && (includeOngoing || !e.ongoing),
    )) {
      for (final span in entry.activeSegments(now)) {
        final a = span.start.isBefore(from) ? from : span.start;
        final b = span.end.isAfter(to) ? to : span.end;
        if (b.isAfter(a)) segments.add((start: a, end: b));
      }
    }
    segments.sort((a, b) => a.start.compareTo(b.start));
    if (segments.isEmpty) return Duration.zero;
    var left = segments.first.start;
    var right = segments.first.end;
    var sum = Duration.zero;
    for (final span in segments.skip(1)) {
      if (!span.start.isAfter(right)) {
        if (span.end.isAfter(right)) right = span.end;
      } else {
        sum += right.difference(left);
        left = span.start;
        right = span.end;
      }
    }
    return sum + right.difference(left);
  }

  /// Calendar-day portions of bedtime-to-wake-up sleep, excluding wakings.
  Duration nightSleepForDay(DateTime day) {
    final from = DateTime(day.year, day.month, day.day);
    final to = DateTime(day.year, day.month, day.day + 1);
    final ordered = [...entries]..sort((a, b) => a.start.compareTo(b.start));
    final spans = <({DateTime start, DateTime end})>[];
    DateTime? bed;
    for (final e in ordered) {
      if (e.kind == ActivityKind.bedtime) {
        if (bed != null) {
          final maxSpan = bed.add(const Duration(hours: 12));
          final cap = maxSpan.isBefore(e.start) ? maxSpan : e.start;
          if (cap.isAfter(bed)) spans.add((start: bed, end: cap));
        }
        bed = e.start;
      }
      if (e.kind == ActivityKind.wakeUp && bed != null) {
        if (e.start.isAfter(bed)) {
          spans.add((start: bed, end: e.start));
        }
        bed = null;
      }
    }
    if (bed != null) {
      final maxSpan = bed.add(const Duration(hours: 14));
      final finish = now.isBefore(maxSpan) ? now : maxSpan;
      if (finish.isAfter(bed)) spans.add((start: bed, end: finish));
    }
    var total = Duration.zero;
    for (final span in spans) {
      final a = span.start.isBefore(from) ? from : span.start;
      final b = span.end.isAfter(to) ? to : span.end;
      if (!b.isAfter(a)) continue;
      final wakings = <({DateTime start, DateTime end})>[];
      for (final e in entries.where(
        (e) => e.kind == ActivityKind.nightWaking,
      )) {
        for (final awake in e.activeSegments(now)) {
          final x = awake.start.isBefore(a) ? a : awake.start;
          final y = awake.end.isAfter(b) ? b : awake.end;
          if (y.isAfter(x)) {
            wakings.add((start: x, end: y));
          }
        }
      }
      wakings.sort((x, y) => x.start.compareTo(y.start));
      var cursor = a;
      for (final awake in wakings) {
        if (awake.start.isAfter(cursor)) {
          total += awake.start.difference(cursor);
        }
        if (awake.end.isAfter(cursor)) {
          cursor = awake.end;
        }
      }
      if (b.isAfter(cursor)) total += b.difference(cursor);
    }
    return total;
  }

  double amountForDay(DateTime day, ActivityKind kind) => entriesForDay(day)
      .where((e) => e.kind == kind)
      .fold(0.0, (sum, e) => sum + (e.details.amount ?? 0));
  Duration nursingForDay(DateTime day) {
    final from = DateTime(day.year, day.month, day.day);
    final to = DateTime(day.year, day.month, day.day + 1);
    return entries
        .where((e) => e.kind == ActivityKind.nursing)
        .fold(Duration.zero, (sum, e) => sum + _durationBetween(e, from, to));
  }

  /// Old saved records remain available for correction in History. A sleep
  /// interval containing an explicit wake-up cannot drive the day schedule.
  List<ActivityEntry> scheduleEntriesForDay(DateTime day) => entriesForDay(day)
      .where(
        (e) =>
            e.kind != ActivityKind.nap ||
            !entries.any(
              (other) => other.id != e.id && _wakeInsideNap(e, other),
            ),
      )
      .toList();

  List<ActivityEntry> conflictingNapsForDay(DateTime day) => entriesForDay(day)
      .where(
        (e) =>
            e.kind == ActivityKind.nap &&
            entries.any(
              (other) => other.id != e.id && _wakeInsideNap(e, other),
            ),
      )
      .toList();

  List<ActivityEntry> entriesForDay(DateTime day) {
    final from = DateTime(day.year, day.month, day.day);
    final to = DateTime(day.year, day.month, day.day + 1);
    return _entries
        .where(
          (e) => e.kind.interval
              ? e.start.isBefore(to) && (e.end ?? now).isAfter(from)
              : !e.start.isBefore(from) && e.start.isBefore(to),
        )
        .toList();
  }

  String exportJson() => jsonEncode({
    'version': 1,
    'exportedAt': now.toIso8601String(),
    'profile': _profile.toJson(),
    'entries': _entries.map((e) => e.toJson()).toList(),
  });

  Future<void> importJson(String raw) async {
    final j = jsonDecode(raw) as Map<String, dynamic>;
    if (j['version'] != 1) {
      throw const FormatException('Unsupported backup version');
    }
    final profile = BabyProfile.fromJson(
      Map<String, dynamic>.from(j['profile'] as Map),
    );
    final entries = (j['entries'] as List)
        .map((e) => ActivityEntry.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
    _validateProfile(profile);
    if (entries.map((e) => e.id).toSet().length != entries.length ||
        entries
                .where((e) => e.ongoing && e.kind != ActivityKind.nursing)
                .length >
            1 ||
        entries
                .where((e) => e.ongoing && e.kind == ActivityKind.nursing)
                .length >
            1) {
      throw const FormatException('Invalid backup records');
    }
    entries.sort((a, b) => b.start.compareTo(a.start));
    for (final e in entries) {
      _validateEntry(e);
    }
    await _commit(entries, profile, restoring: true);
  }

  Future<void> clearAll() => _commit(const [], _profile);
}
