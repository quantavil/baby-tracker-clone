import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../controller.dart';
import '../model.dart';
import '../prediction.dart';
import 'editor.dart';
import 'theme.dart';

enum NapStatus { logged, ongoing, predicted }

class ScheduledNap {
  const ScheduledNap({
    required this.index,
    required this.start,
    required this.end,
    required this.status,
    this.entry,
  });
  final int index;
  final DateTime start;
  final DateTime end;
  final NapStatus status;
  final ActivityEntry? entry;
}

class ScheduleDial extends StatelessWidget {
  const ScheduleDial({
    super.key,
    required this.controller,
    required this.day,
    this.controls = true,
  });
  final TrackerController controller;
  final DateTime day;
  final bool controls;

  @override
  Widget build(BuildContext context) {
    final c = controller;
    final active =
        c.active != null &&
            day.year == c.now.year &&
            day.month == c.now.month &&
            day.day == c.now.day &&
            DateUtils.isSameDay(c.active!.start, day)
        ? c.active
        : null;
    final isToday = DateUtils.isSameDay(day, c.now);
    final visibleEntries = c
        .scheduleEntriesForDay(day)
        .where((e) => isToday || !e.ongoing)
        .toList();
    final scale = DialScale(visibleEntries, day, c.profile, c.now);
    final activeWindow = scale.scheduled
        .where((n) => n.entry?.id == active?.id)
        .firstOrNull;
    final targetSleep = activeWindow == null
        ? Duration.zero
        : activeWindow.end.difference(activeWindow.start);
    final large = MediaQuery.textScalerOf(context).scale(1) > 1.3;
    final completedNaps = c
        .scheduleEntriesForDay(day)
        .where((e) => e.kind == ActivityKind.nap && !e.ongoing)
        .length;
    if (scale.wake == null && active == null && completedNaps == 0) {
      return LayoutBuilder(
        builder: (context, constraints) {
          final size = math.min(constraints.maxWidth, 380.0);
          return SizedBox(
            width: size,
            height: size,
            child: CustomPaint(
              painter: ScheduleTrackPainter(ink.withValues(alpha: .65)),
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      'assets/tracking/icons/wake_up.webp',
                      width: 64,
                      height: 64,
                    ),
                    const SizedBox(height: 16),
                    const Flexible(
                      child: Text(
                        'Tap when your baby wakes up to start a new day',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: muted, fontSize: 16),
                      ),
                    ),
                    const SizedBox(height: 20),
                    if (controls)
                      OutlinedButton(
                        key: const ValueKey('debug_start_day_button'),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: lavender, width: 2),
                        ),
                        onPressed: c.writing
                            ? null
                            : () => showEditor(
                                context,
                                c,
                                ActivityKind.wakeUp,
                                initialStart: isToday
                                    ? c.now
                                    : DateTime(day.year, day.month, day.day, 7),
                              ),
                        child: const Text('Start day'),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final size = math.min(constraints.maxWidth, 412.0);
            return SizedBox(
              width: size,
              height: size * 1.06,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Positioned(
                    left: 0,
                    right: 0,
                    top: 0,
                    height: size,
                    child: CustomPaint(
                      painter: DialPainter(
                        entries: visibleEntries,
                        day: day,
                        now: c.now,
                        scale: scale,
                        profile: c.profile,
                      ),
                    ),
                  ),
                  for (final nap in scale.scheduled.where(
                    (n) =>
                        n.status != NapStatus.predicted ||
                        (isToday && scale.wake != null),
                  ))
                    Positioned(
                      left:
                          size / 2 +
                          math.cos(
                                scale.angle(
                                  nap.start.add(
                                    nap.end.difference(nap.start) ~/ 2,
                                  ),
                                ),
                              ) *
                              size *
                              .445 -
                          16,
                      top:
                          size / 2 +
                          math.sin(
                                scale.angle(
                                  nap.start.add(
                                    nap.end.difference(nap.start) ~/ 2,
                                  ),
                                ),
                              ) *
                              size *
                              .445 -
                          16,
                      child: Semantics(
                        label: 'Nap ${nap.index + 1}',
                        button: true,
                        child: InkResponse(
                          key: ValueKey('nap_${nap.index + 1}'),
                          radius: 20,
                          onTap: () {
                            if (nap.entry != null) {
                              showEntrySummary(context, c, nap.entry!);
                            } else {
                              showPredictionSummary(
                                context,
                                c,
                                ActivityKind.nap,
                                start: nap.start,
                                end: nap.end,
                              );
                            }
                          },
                          child: Container(
                            width: 32,
                            height: 32,
                            alignment: Alignment.center,
                            child: Image.asset(
                              nap.status == NapStatus.ongoing
                                  ? 'assets/main_screen/schedule_info/schedule_circle/active.png'
                                  : 'assets/main_screen/schedule_info/schedule_circle/future_nap.png',
                              width: 24,
                              height: 24,
                              color: nap.status == NapStatus.logged
                                  ? ink
                                  : null,
                            ),
                          ),
                        ),
                      ),
                    ),
                  Positioned(
                    left: 0,
                    right: 0,
                    top: 0,
                    height: size,
                    child: Padding(
                      padding: EdgeInsets.all(size * (large ? .10 : .19)),
                      child: active != null
                          ? FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    key: const ValueKey(
                                      'debug_schedule_timer_current_label',
                                    ),
                                    active.paused
                                        ? 'Paused'
                                        : active.kind ==
                                              ActivityKind.nightWaking
                                        ? 'Awake for'
                                        : 'Asleep for',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: muted,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  FittedBox(
                                    child: Text(
                                      key: const ValueKey(
                                        'debug_schedule_timer_current_duration',
                                      ),
                                      timerLabel(c.elapsed(active)),
                                      style: const TextStyle(
                                        fontSize: 36,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  if (active.kind == ActivityKind.nap &&
                                      c.elapsed(active) > targetSleep) ...[
                                    const SizedBox(height: 4),
                                    const Text(
                                      key: ValueKey(
                                        'debug_schedule_timer_next_label',
                                      ),
                                      'Overslept',
                                      style: TextStyle(
                                        color: muted,
                                        fontSize: 12,
                                      ),
                                    ),
                                    Text(
                                      key: const ValueKey(
                                        'debug_schedule_timer_next_duration',
                                      ),
                                      durationLabel(
                                        c.elapsed(active) - targetSleep,
                                      ),
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ] else if (active.kind ==
                                      ActivityKind.nap) ...[
                                    const SizedBox(height: 4),
                                    const Text(
                                      key: ValueKey(
                                        'debug_schedule_timer_next_label',
                                      ),
                                      'Target sleep',
                                      style: TextStyle(
                                        color: muted,
                                        fontSize: 12,
                                      ),
                                    ),
                                    Text(
                                      key: const ValueKey(
                                        'debug_schedule_timer_next_duration',
                                      ),
                                      scheduleDurationLabel(targetSleep),
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                  if (!large && controls) ...[
                                    const SizedBox(height: 16),
                                    _controls(context, c, active),
                                  ],
                                ],
                              ),
                            )
                          : Center(
                              child: Builder(
                                builder: (context) {
                                  if (!isToday) {
                                    return Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Text(
                                          'Day sleep',
                                          style: TextStyle(
                                            color: muted,
                                            fontSize: 16,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        FittedBox(
                                          child: Text(
                                            durationLabel(
                                              c.totalForDay(
                                                day,
                                                includeOngoing: false,
                                                forSchedule: true,
                                              ),
                                            ),
                                            style: const TextStyle(
                                              fontSize: 40,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        const Text(
                                          'Naps logged',
                                          style: TextStyle(
                                            color: muted,
                                            fontSize: 16,
                                          ),
                                        ),
                                        Text(
                                          '$completedNaps times',
                                          style: const TextStyle(
                                            fontSize: 24,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    );
                                  }
                                  DateTime? lastSleepFinish;
                                  final finishedNaps =
                                      c
                                          .scheduleEntriesForDay(day)
                                          .where(
                                            (e) =>
                                                e.kind == ActivityKind.nap &&
                                                e.end != null,
                                          )
                                          .toList()
                                        ..sort(
                                          (a, b) => b.end!.compareTo(a.end!),
                                        );
                                  if (finishedNaps.isNotEmpty) {
                                    lastSleepFinish = finishedNaps.first.end;
                                  } else if (scale.wake != null) {
                                    lastSleepFinish = scale.wake;
                                  }
                                  final isAwakeTracking =
                                      lastSleepFinish != null && isToday;
                                  final awakeDuration = isAwakeTracking
                                      ? c.now.difference(lastSleepFinish)
                                      : null;

                                  final nextPredicted = scale.scheduled
                                      .where(
                                        (n) => n.status == NapStatus.predicted,
                                      )
                                      .firstOrNull;
                                  final nextTime =
                                      nextPredicted?.start ??
                                      scale.bed ??
                                      scale.predictedBed;
                                  final nextLabelText = nextPredicted != null
                                      ? (c.now.isAfter(
                                              nextPredicted.start.add(
                                                const Duration(minutes: 15),
                                              ),
                                            )
                                            ? 'Late for nap'
                                            : 'Next nap')
                                      : (scale.bed != null
                                            ? 'Bedtime'
                                            : 'Predicted bedtime');
                                  final nextDurationText = nextTime != null
                                      ? 'at ${clockLabel(nextTime, c.profile)}'
                                      : '';

                                  return FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          key: const ValueKey(
                                            'debug_schedule_timer_current_label',
                                          ),
                                          nextPredicted != null
                                              ? (c.now.isBefore(
                                                      nextPredicted.start,
                                                    )
                                                    ? 'Nap starts in'
                                                    : 'Late for nap')
                                              : isAwakeTracking
                                              ? 'Awake for'
                                              : 'Ready for a nap?',
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                            color: muted,
                                            fontSize: 14,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        FittedBox(
                                          child: Text(
                                            key: const ValueKey(
                                              'debug_schedule_timer_current_duration',
                                            ),
                                            nextPredicted != null
                                                ? scheduleDurationLabel(
                                                    c.now.isBefore(
                                                          nextPredicted.start,
                                                        )
                                                        ? nextPredicted.start
                                                              .difference(c.now)
                                                        : c.now.difference(
                                                            nextPredicted.start,
                                                          ),
                                                  )
                                                : isAwakeTracking &&
                                                      awakeDuration != null
                                                ? timerLabel(awakeDuration)
                                                : 'Log your day',
                                            style: const TextStyle(
                                              fontSize: 36,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                        if (!large &&
                                            nextDurationText.isNotEmpty) ...[
                                          const SizedBox(height: 4),
                                          Text(
                                            key: const ValueKey(
                                              'debug_schedule_timer_next_label',
                                            ),
                                            nextPredicted != null
                                                ? 'Awake for'
                                                : nextLabelText,
                                            style: const TextStyle(
                                              color: muted,
                                              fontSize: 12,
                                            ),
                                          ),
                                          Text(
                                            key: const ValueKey(
                                              'debug_schedule_timer_next_duration',
                                            ),
                                            nextPredicted != null &&
                                                    awakeDuration != null
                                                ? scheduleDurationLabel(
                                                    awakeDuration,
                                                  )
                                                : nextDurationText,
                                            style: const TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ],
                                        if (controls && isToday && !large) ...[
                                          const SizedBox(height: 12),
                                          OutlinedButton(
                                            key: const ValueKey(
                                              'debug_start_nap_button',
                                            ),
                                            style: OutlinedButton.styleFrom(
                                              side: const BorderSide(
                                                color: accent,
                                                width: 2,
                                              ),
                                              backgroundColor: surface
                                                  .withValues(alpha: .5),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(14),
                                              ),
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 20,
                                                    vertical: 8,
                                                  ),
                                            ),
                                            onPressed: c.writing
                                                ? null
                                                : () => perform(
                                                    context,
                                                    () => c.saveEntry(
                                                      ActivityEntry(
                                                        id: DateTime.now()
                                                            .microsecondsSinceEpoch
                                                            .toString(),
                                                        kind: ActivityKind.nap,
                                                        start: c.now,
                                                      ),
                                                    ),
                                                  ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Image.asset(
                                                  'assets/main_screen/schedule_info/main_screen_info/buttons/horizontal_button/start_icon.png',
                                                  width: 22,
                                                  height: 22,
                                                ),
                                                const SizedBox(width: 8),
                                                const Text(
                                                  'Start nap',
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w600,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ] else if (!large) ...[
                                          const SizedBox(height: 10),
                                          const Text(
                                            'Build a picture of your baby’s rhythm',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              color: muted,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                    ),
                  ),
                  if (scale.wake != null ||
                      scale.bed != null ||
                      scale.predictedBed != null)
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 30,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Expanded(
                            child: InkWell(
                              key: const ValueKey('debug_wake_up_button'),
                              hoverColor: Colors.transparent,
                              borderRadius: BorderRadius.circular(16),
                              onTap: () {
                                final wakeEntry = c
                                    .scheduleEntriesForDay(day)
                                    .where((e) => e.kind == ActivityKind.wakeUp)
                                    .firstOrNull;
                                showEditor(
                                  context,
                                  c,
                                  ActivityKind.wakeUp,
                                  entry: wakeEntry,
                                  initialStart: isToday
                                      ? c.now
                                      : DateTime(
                                          day.year,
                                          day.month,
                                          day.day,
                                          7,
                                        ),
                                );
                              },
                              child: _anchor(
                                c,
                                scale.wake,
                                'Wake-up',
                                'wake_up_icon.png',
                              ),
                            ),
                          ),
                          Expanded(
                            child: InkWell(
                              key: const ValueKey(
                                'debug_predicted_bedtime_button',
                              ),
                              hoverColor: Colors.transparent,
                              borderRadius: BorderRadius.circular(16),
                              onTap: () {
                                final bedEntry = c
                                    .scheduleEntriesForDay(day)
                                    .where(
                                      (e) => e.kind == ActivityKind.bedtime,
                                    )
                                    .firstOrNull;
                                final start =
                                    scale.bed ??
                                    scale.predictedBed ??
                                    DateTime(day.year, day.month, day.day, 22);
                                if (bedEntry != null) {
                                  showEntrySummary(context, c, bedEntry);
                                } else {
                                  showPredictionSummary(
                                    context,
                                    c,
                                    ActivityKind.bedtime,
                                    start: start,
                                  );
                                }
                              },
                              child: _anchor(
                                c,
                                scale.bed ?? scale.predictedBed,
                                scale.bed != null
                                    ? 'Bedtime'
                                    : 'Predicted bedtime',
                                'bedtime_icon.png',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            );
          },
        ),
        if (active != null && large && controls) _controls(context, c, active),
        if (active == null && large)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Build a picture of your baby’s rhythm',
              textAlign: TextAlign.center,
              style: TextStyle(color: muted),
            ),
          ),
      ],
    );
  }

  Widget _anchor(
    TrackerController c,
    DateTime? time,
    String label,
    String asset,
  ) => Column(
    children: [
      Container(
        padding: const EdgeInsets.all(10),
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Color(0xFF65578B),
        ),
        child: Image.asset(
          'assets/main_screen/schedule_info/schedule_circle/$asset',
          height: 24,
          width: 24,
        ),
      ),
      const SizedBox(height: 6),
      Text(
        time == null ? 'Not logged' : clockLabel(time, c.profile),
        style: TextStyle(
          color: label == 'Wake-up' ? const Color(0xFFE5BBA9) : lavender,
        ),
      ),
      const SizedBox(height: 6),
      Text(label, style: const TextStyle(color: muted, fontSize: 12)),
    ],
  );

  Widget _controls(
    BuildContext context,
    TrackerController c,
    ActivityEntry active,
  ) => Row(
    mainAxisSize: MainAxisSize.min,
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      OutlinedButton(
        key: const ValueKey('debug_pause_tracking_button'),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: accent, width: 2),
          backgroundColor: surface.withValues(alpha: .5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        ),
        onPressed: c.writing
            ? null
            : () => perform(context, active.paused ? c.resume : c.pause),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/main_screen/schedule_info/main_screen_info/buttons/square_button/${active.paused ? 'play_icon.png' : 'pause_icon.png'}',
              width: 24,
              height: 24,
            ),
            const SizedBox(height: 4),
            Text(
              active.paused ? 'Resume' : 'Pause',
              style: const TextStyle(fontSize: 12, color: Colors.white),
            ),
          ],
        ),
      ),
      const SizedBox(width: 12),
      OutlinedButton(
        key: const ValueKey('debug_stop_tracking_button'),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: accent, width: 2),
          backgroundColor: surface.withValues(alpha: .5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        ),
        onPressed: c.writing ? null : () => perform(context, c.stop),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/main_screen/schedule_info/main_screen_info/buttons/square_button/stop_icon.png',
              width: 24,
              height: 24,
            ),
            const SizedBox(height: 4),
            const Text(
              'Stop',
              style: TextStyle(fontSize: 12, color: Colors.white),
            ),
          ],
        ),
      ),
    ],
  );
}

class DialScale {
  DialScale(
    List<ActivityEntry> entries,
    DateTime day, [
    BabyProfile profile = const BabyProfile(),
    DateTime? now,
  ]) {
    final morning = entries
        .where((e) => e.kind == ActivityKind.wakeUp)
        .firstOrNull
        ?.start;
    wake = morning;
    bed = entries
        .where(
          (e) =>
              e.kind == ActivityKind.bedtime &&
              (morning == null || e.start.isAfter(morning)),
        )
        .firstOrNull
        ?.start;
    final age = profile.birthday == null
        ? 9.0
        : ((now ?? day).difference(profile.birthday!).inDays / 30.0).clamp(
            0.0,
            24.0,
          );
    final baseline = SleepBaseline.forAge(age);
    predictedBed = bed == null && morning != null
        ? (now != null && DateUtils.isSameDay(day, now)
              ? morning.add(SleepBaseline.minutes(baseline.dayLength))
              : DateTime(day.year, day.month, day.day, 22))
        : null;
    from = morning ?? DateTime(day.year, day.month, day.day);
    until = bed ?? predictedBed ?? DateTime(day.year, day.month, day.day + 1);
    if (!until.isAfter(from)) {
      until = from.add(const Duration(hours: 14));
    }

    final loggedNaps = entries.where((e) => e.kind == ActivityKind.nap).toList()
      ..sort((a, b) => a.start.compareTo(b.start));

    final targetCount = profile.customNaps
        ? profile.napCount
        : SleepBaseline.initialNapCount(age);
    final totalSlots = math.max(targetCount, loggedNaps.length);

    final wakeWindows = SleepBaseline.windows(baseline.awake, targetCount + 1);
    final napWindows = SleepBaseline.windows(
      baseline.daySleep,
      targetCount,
      reverse: true,
    );
    Duration napDuration(int i) =>
        SleepBaseline.minutes(napWindows[i.clamp(0, napWindows.length - 1)]);
    Duration wakeDuration(int i) =>
        SleepBaseline.minutes(wakeWindows[i.clamp(0, wakeWindows.length - 1)]);

    final refWake =
        wake ??
        (profile.customWakeUp
            ? DateTime(
                day.year,
                day.month,
                day.day,
                profile.wakeUpMinutes ~/ 60,
                profile.wakeUpMinutes % 60,
              )
            : DateTime(day.year, day.month, day.day, 7, 0));

    final list = <ScheduledNap>[];
    for (var i = 0; i < totalSlots; i++) {
      if (i < loggedNaps.length) {
        final e = loggedNaps[i];
        final status = e.ongoing ? NapStatus.ongoing : NapStatus.logged;
        final end =
            e.end ??
            (e.ongoing
                ? e.start.add(napDuration(i))
                : e.start.add(const Duration(hours: 1)));
        list.add(
          ScheduledNap(
            index: i,
            start: e.start,
            end: end,
            status: status,
            entry: e,
          ),
        );
      } else {
        final DateTime prevEnd = list.isNotEmpty ? list.last.end : refWake;
        final ww = wakeDuration(i);
        final pStart = prevEnd.add(ww);
        final pDur = napDuration(i);
        final pEnd = pStart.add(pDur);
        list.add(
          ScheduledNap(
            index: i,
            start: pStart,
            end: pEnd,
            status: NapStatus.predicted,
          ),
        );
      }
    }
    scheduled = List.unmodifiable(list);
  }

  late final DateTime? wake, bed, predictedBed;
  late final List<ScheduledNap> scheduled;
  late DateTime from, until;

  double angle(DateTime t) {
    final span = until.difference(from).inSeconds;
    if (span <= 0) return math.pi * .75;
    final fraction = (t.difference(from).inSeconds / span).clamp(0.0, 1.0);
    return math.pi * .75 + math.pi * 1.5 * fraction;
  }
}

class DialPainter extends CustomPainter {
  DialPainter({
    required this.entries,
    required this.day,
    required this.now,
    this.scale,
    this.profile = const BabyProfile(),
  });
  final List<ActivityEntry> entries;
  final DateTime day, now;
  final DialScale? scale;
  final BabyProfile profile;

  @override
  void paint(Canvas canvas, Size size) {
    final effectiveScale = scale ?? DialScale(entries, day, profile, now);
    final center = size.center(Offset.zero);
    final radius = size.width * .445;
    final rect = Rect.fromCircle(center: center, radius: radius);
    const start = math.pi * .75, sweep = math.pi * 1.5;
    final trackPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..color = const Color(0xFF5B4D77);
    canvas.drawArc(rect, start, sweep, false, trackPaint);

    final from = effectiveScale.from, until = effectiveScale.until;
    double angle(DateTime t) => effectiveScale.angle(t);

    if (effectiveScale.wake != null && DateUtils.isSameDay(day, now)) {
      // 1. Paint predicted nap slots on the track when wake is logged
      for (final nap in effectiveScale.scheduled.where(
        (n) => n.status == NapStatus.predicted,
      )) {
        final a = angle(nap.start.isBefore(from) ? from : nap.start);
        final b = angle(nap.end.isAfter(until) ? until : nap.end);
        if (b > a) {
          final fillPaint = Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 24
            ..strokeCap = StrokeCap.round
            ..color = const Color(0x33B49AD9);
          canvas.drawArc(rect, a, b - a, false, fillPaint);

          final borderPaint = Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5
            ..strokeCap = StrokeCap.round
            ..color = const Color(0x66B49AD9);
          canvas.drawArc(rect, a, b - a, false, borderPaint);

          final offset =
              center + Offset(math.cos(a), math.sin(a)) * (radius + 18);
          final label = TextPainter(
            text: TextSpan(
              text: dialTimeLabel(nap.start, profile),
              style: const TextStyle(
                fontSize: 11,
                color: muted,
                fontWeight: FontWeight.w500,
              ),
            ),
            textDirection: TextDirection.ltr,
          )..layout();
          label.paint(
            canvas,
            offset - Offset(label.width / 2, label.height / 2),
          );
        }
      }
    }

    // 2. Paint logged and active naps / night wakings
    final paint = Paint()..style = PaintingStyle.stroke;
    for (final e in entries.where(
      (e) => e.kind == ActivityKind.nap || e.kind == ActivityKind.nightWaking,
    )) {
      for (final span in e.activeSegments(now)) {
        final a = span.start.isBefore(from) ? from : span.start;
        final b = span.end.isAfter(until) ? until : span.end;
        if (!b.isAfter(a)) continue;
        paint
          ..strokeWidth = 28
          ..strokeCap = StrokeCap.round
          ..color = e.kind == ActivityKind.nap
              ? const Color(0xFFB49AD9)
              : const Color(0xFFDCB4BC);
        if (e.kind == ActivityKind.nap) {
          paint.shader = ui.Gradient.linear(
            center + Offset(math.cos(angle(a)), math.sin(angle(a))) * radius,
            center + Offset(math.cos(angle(b)), math.sin(angle(b))) * radius,
            const [Color(0xFFC6ABB6), Color(0xFFAA8BD5)],
          );
        }
        canvas.drawArc(rect, angle(a), angle(b) - angle(a), false, paint);
        paint.shader = null;
      }
    }

    // Start captions plus the final completed nap's end, as observed in the original.
    if (effectiveScale.wake != null) {
      final naps =
          entries
              .where((e) => e.kind == ActivityKind.nap && !e.ongoing)
              .toList()
            ..sort((a, b) => a.start.compareTo(b.start));
      final times = [
        for (final e in naps) e.start,
        if (naps.isNotEmpty && naps.last.end != null) naps.last.end!,
      ];
      for (final time in times) {
        final a = angle(time);
        final offset =
            center + Offset(math.cos(a), math.sin(a)) * (radius + 20);
        var rotation = a + math.pi / 2;
        if (math.cos(rotation) < 0) rotation += math.pi;
        final label = TextPainter(
          text: TextSpan(
            text: dialTimeLabel(time, profile),
            style: const TextStyle(fontSize: 12, color: muted),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        canvas.save();
        canvas.translate(offset.dx, offset.dy);
        canvas.rotate(rotation);
        label.paint(canvas, Offset(-label.width / 2, -label.height / 2));
        canvas.restore();
      }
    } else {
      for (var hour = 0; hour <= 24; hour += 6) {
        final a = start + sweep * hour / 24;
        final offset =
            center + Offset(math.cos(a), math.sin(a)) * (radius + 13);
        final label = TextPainter(
          text: TextSpan(
            text: '${hour % 24}',
            style: const TextStyle(fontSize: 10, color: muted),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        label.paint(canvas, offset - Offset(label.width / 2, label.height / 2));
      }
    }
  }

  @override
  bool shouldRepaint(covariant DialPainter old) => true;
}

class ScheduleTrackPainter extends CustomPainter {
  const ScheduleTrackPainter(this.color);
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..color = color;
    canvas.drawArc(
      Rect.fromCircle(
        center: size.center(Offset.zero),
        radius: size.shortestSide * .49,
      ),
      math.pi * .75,
      math.pi * 1.5,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(ScheduleTrackPainter oldDelegate) =>
      color != oldDelegate.color;
}
