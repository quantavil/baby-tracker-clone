import 'package:flutter/material.dart';
import '../controller.dart';
import '../model.dart';
import '../prediction.dart';
import 'theme.dart';
import 'dial.dart';
import 'share.dart';
import 'editor.dart';

class HomePage extends StatefulWidget {
  const HomePage({
    super.key,
    required this.controller,
    required this.day,
    required this.onDay,
  });
  final TrackerController controller;
  final DateTime day;
  final ValueChanged<DateTime> onDay;
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool night = false;
  TrackerController get controller => widget.controller;
  DateTime get day => widget.day;
  ValueChanged<DateTime> get onDay => widget.onDay;
  @override
  Widget build(BuildContext context) {
    final c = controller;
    final learningDays = c.learningDays;
    final hasSchedule = c
        .entriesForDay(day)
        .any(
          (e) =>
              e.kind == ActivityKind.wakeUp || e.kind == ActivityKind.bedtime,
        );
    final showNight = night && hasSchedule;
    final scheduleEntries = c.scheduleEntriesForDay(day);
    final visibleEntries = scheduleEntries
        .where((e) => DateUtils.isSameDay(day, c.now) || !e.ongoing)
        .toList();
    final scale = DialScale(visibleEntries, day, c.profile, c.now);
    final daySleep = c.totalForDay(
      day,
      forSchedule: true,
      includeOngoing: DateUtils.isSameDay(day, c.now),
    );
    final nightSleep = c.nightSleepForDay(day);
    final hasDaySleep = scheduleEntries.any((e) => e.kind == ActivityKind.nap);
    final hasNightSleep = nightSleep > Duration.zero;
    final wake = scheduleEntries
        .where((e) => e.kind == ActivityKind.wakeUp)
        .firstOrNull
        ?.start;
    final bed = scheduleEntries
        .where(
          (e) =>
              e.kind == ActivityKind.bedtime &&
              (wake == null || e.start.isAfter(wake)),
        )
        .firstOrNull
        ?.start;
    final awakeEnd = bed ?? (DateUtils.isSameDay(day, c.now) ? c.now : null);
    final awake = wake != null && awakeEnd != null && awakeEnd.isAfter(wake)
        ? awakeEnd.difference(wake) - daySleep
        : null;

    final prevDay = DateTime(day.year, day.month, day.day - 1);
    final prevDaySleep = c.totalForDay(
      prevDay,
      forSchedule: true,
      includeOngoing: false,
    );
    final prevNightSleep = c.nightSleepForDay(prevDay);
    final prevTotalSleep = prevDaySleep + prevNightSleep;
    final prevAwake = c.daytimeAwakeForDay(prevDay);

    final hasPrevDaySleep = c.hasDaySleepForDay(prevDay);
    final hasPrevNightSleep = c.hasNightSleepForDay(prevDay);
    final hasPrevTotalSleep = c.hasTotalSleepForDay(prevDay);
    final hasPrevAwake = prevAwake != null;

    final daySleepCaption = c.previousDayComparisonCaption(
      day: day,
      currentDuration: daySleep,
      previousDuration: prevDaySleep,
      hasCurrentData: hasDaySleep,
      hasPreviousData: hasPrevDaySleep,
    );
    final nightSleepCaption = c.previousDayComparisonCaption(
      day: day,
      currentDuration: nightSleep,
      previousDuration: prevNightSleep,
      hasCurrentData: hasNightSleep,
      hasPreviousData: hasPrevNightSleep,
    );
    final totalSleepCaption = c.previousDayComparisonCaption(
      day: day,
      currentDuration: daySleep + nightSleep,
      previousDuration: prevTotalSleep,
      hasCurrentData: hasDaySleep || hasNightSleep,
      hasPreviousData: hasPrevTotalSleep,
    );
    final awakeCaption = c.previousDayComparisonCaption(
      day: day,
      currentDuration: awake,
      previousDuration: prevAwake,
      hasCurrentData: awake != null,
      hasPreviousData: hasPrevAwake,
    );

    return Stack(
      children: [
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Image.asset(
            showNight
                ? 'assets/main_screen/background_night.webp'
                : 'assets/tabs/home/app_bar_background.webp',
            fit: BoxFit.fitWidth,
          ),
        ),
        Column(
          children: [
            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Column(
                  key: const ValueKey('home_pinned_header'),
                  children: [
                    Row(
                      children: [
                        IconButton(
                          tooltip: 'All features are free',
                          onPressed: () =>
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'All features are available for free',
                                  ),
                                ),
                              ),
                          icon: Image.asset(
                            'assets/common/premium/premium_icon.webp',
                            width: 28,
                            height: 28,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            shortDate(day, c.now),
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                        ),
                        const SizedBox(width: 48),
                      ],
                    ),
                    const SizedBox(height: 12),
                    DayStrip(day: day, now: c.now, onDay: onDay),
                  ],
                ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(0, 8, 0, 32),
                children:
                    [
                          if (c.conflictingNapsForDay(day).isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
                              child: TextButton.icon(
                                key: const ValueKey('repair-overlapping-nap'),
                                icon: const Icon(Icons.info_outline),
                                label: const Text(
                                  'A nap overlaps a wake-up. Edit its time.',
                                ),
                                onPressed: c.writing
                                    ? null
                                    : () => showEditor(
                                        context,
                                        c,
                                        ActivityKind.nap,
                                        entry: c
                                            .conflictingNapsForDay(day)
                                            .first,
                                      ),
                              ),
                            ),
                          if (c.active != null &&
                              (!DateUtils.isSameDay(day, c.now) ||
                                  !DateUtils.isSameDay(c.active!.start, day) ||
                                  showNight)) ...[
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              child: Container(
                                key: const ValueKey('running-session'),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: surface.withValues(alpha: .8),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '${c.active!.paused ? 'Paused' : 'Running'} ${c.active!.kind.label.toLowerCase()}',
                                          ),
                                          Text(
                                            timerLabel(c.elapsed(c.active!)),
                                            style: const TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: c.writing
                                          ? null
                                          : () => perform(
                                              context,
                                              c.active!.paused
                                                  ? c.resume
                                                  : c.pause,
                                            ),
                                      child: Text(
                                        c.active!.paused ? 'Resume' : 'Pause',
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: c.writing
                                          ? null
                                          : () => perform(context, c.stop),
                                      child: const Text('Stop timer'),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],
                          const SizedBox(height: 12),
                          if (showNight)
                            _NightSchedule(
                              controller: c,
                              day: day,
                              scale: scale,
                            )
                          else
                            _DaySchedule(controller: c, day: day),
                          if (hasSchedule) ...[
                            const SizedBox(height: 10),
                            Center(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: const Color(0xFF292534),
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    for (final value in [false, true])
                                      Semantics(
                                        selected: showNight == value,
                                        child: TextButton(
                                          key: ValueKey(
                                            value
                                                ? 'schedule-night'
                                                : 'schedule-day',
                                          ),
                                          style: TextButton.styleFrom(
                                            minimumSize: const Size(76, 42),
                                            foregroundColor: const Color(
                                              0xFFE6D8FF,
                                            ),
                                            side: BorderSide(
                                              color: showNight == value
                                                  ? const Color(0xFFC6ABB6)
                                                  : Colors.transparent,
                                              width: 2,
                                            ),
                                            shape: const StadiumBorder(),
                                          ),
                                          onPressed: () =>
                                              setState(() => night = value),
                                          child: Text(
                                            value ? 'Night' : 'Day',
                                            style: const TextStyle(
                                              fontSize: 16,
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: 40),
                          Container(
                            key: const ValueKey(
                              'main_data_accumulation_banner',
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: surface.withValues(alpha: .8),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  padding: const EdgeInsets.all(5),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: muted.withValues(alpha: .35),
                                      width: 2,
                                    ),
                                    color: ink.withValues(alpha: .2),
                                  ),
                                  child: Image.asset(
                                    'assets/main_screen/night_waking_empty.webp',
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Learning ${c.profile.name}'s rhythm",
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 16,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Day $learningDays/3 · Log naps to improve predictions',
                                        style: const TextStyle(
                                          color: muted,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    SizedBox(
                                      width: 40,
                                      height: 40,
                                      child: CircularProgressIndicator(
                                        value: learningDays / 3,
                                        strokeWidth: 3,
                                        backgroundColor: ink,
                                        valueColor:
                                            const AlwaysStoppedAnimation(
                                              lavender,
                                            ),
                                      ),
                                    ),
                                    Text(
                                      '$learningDays/3',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          if (c.activeNursing != null) ...[
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: surface,
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.child_care, color: lavender),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      'Nursing · ${timerLabel(c.elapsed(c.activeNursing!))}',
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: c.writing
                                        ? null
                                        : () => perform(
                                            context,
                                            c.finishNursing,
                                          ),
                                    child: const Text('Stop nursing'),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          const SizedBox(height: 32),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Overview · ${homeDayLabel(day, c.now)}',
                                  style: Theme.of(
                                    context,
                                  ).textTheme.headlineMedium,
                                ),
                              ),
                              InkWell(
                                key: const ValueKey(
                                  'debug_share_button_overview',
                                ),
                                onTap: () => showShare(context, c, day),
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: surface.withValues(alpha: .7),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Image.asset(
                                    'assets/common/share.webp',
                                    width: 20,
                                    height: 20,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          for (final row in [
                            [
                              (
                                'Day sleep',
                                hasDaySleep ? durationLabel(daySleep) : '-',
                                'nap',
                                daySleepCaption,
                              ),
                              (
                                'Night sleep',
                                hasNightSleep
                                    ? durationLabel(nightSleep)
                                    : '-',
                                'bedtime',
                                nightSleepCaption,
                              ),
                            ],
                            [
                              (
                                'Total sleep',
                                hasDaySleep || hasNightSleep
                                    ? durationLabel(daySleep + nightSleep)
                                    : '-',
                                'total_sleep',
                                totalSleepCaption,
                              ),
                              (
                                'Daytime awake',
                                awake != null
                                    ? durationLabel(
                                        awake < Duration.zero
                                            ? Duration.zero
                                            : awake,
                                      )
                                    : '-',
                                'activity_time',
                                awakeCaption,
                              ),
                            ],
                          ]) ...[
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                for (var i = 0; i < row.length; i++) ...[
                                  if (i > 0) const SizedBox(width: 12),
                                  Expanded(
                                    child: _overview(
                                      context,
                                      row[i].$1,
                                      row[i].$2,
                                      row[i].$4,
                                      row[i].$3,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 12),
                          ],
                          const SizedBox(height: 24),
                          WakeWindowsSection(scale: scale, day: day),
                        ]
                        .map(
                          (child) =>
                              child is _DaySchedule || child is _NightSchedule
                                  ? child
                                  : Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                      ),
                                      child: child,
                                    ),
                        )
                        .toList(),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _overview(
    BuildContext context,
    String title,
    String value,
    String caption,
    String asset,
  ) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: surface.withValues(alpha: .75),
      borderRadius: BorderRadius.circular(18),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Image.asset(
              'assets/tracking/icons/$asset.webp',
              width: 28,
              height: 28,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(color: muted, fontSize: 14),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Text(
          value,
          style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Text(caption, style: const TextStyle(color: muted, fontSize: 12)),
      ],
    ),
  );
}

class DayStrip extends StatelessWidget {
  const DayStrip({
    super.key,
    required this.day,
    required this.now,
    required this.onDay,
  });
  final DateTime day, now;
  final ValueChanged<DateTime> onDay;
  @override
  Widget build(BuildContext context) => Row(
    children: List.generate(7, (i) {
      final d = DateTime(now.year, now.month, now.day - 6 + i);
      final selected =
          d.year == day.year && d.month == day.month && d.day == day.day;
      return Expanded(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 3),
          child: KeyedSubtree(
            key: ValueKey('day_${i + 1}'),
            child: InkWell(
              key: ValueKey('day-${d.toIso8601String().substring(0, 10)}'),
              onTap: () => onDay(d),
              customBorder: const CircleBorder(),
              child: SizedBox(
                height: 40,
                child: Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: surface.withValues(alpha: .8),
                    border: selected
                        ? Border.all(color: lavender, width: 2)
                        : null,
                  ),
                  child: Text(
                    ['M', 'T', 'W', 'T', 'F', 'S', 'S'][d.weekday - 1],
                    style: TextStyle(
                      color: selected ? lavender : muted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }),
  );
}

class _NightSchedule extends StatelessWidget {
  const _NightSchedule({
    required this.controller,
    required this.day,
    this.scale,
  });
  final TrackerController controller;
  final DateTime day;
  final DialScale? scale;

  @override
  Widget build(BuildContext context) {
    final c = controller;
    final entries = c.entriesForDay(day);
    final bed = entries
        .where((e) => e.kind == ActivityKind.bedtime)
        .firstOrNull;
    final wakings = entries
        .where((e) => e.kind == ActivityKind.nightWaking)
        .length;
    final defaultBed =
        scale?.predictedBed ?? DateTime(day.year, day.month, day.day, 22);
    return Column(
      key: const ValueKey('night-schedule'),
      children: [
        AspectRatio(
          aspectRatio: 1,
          child: CustomPaint(
            painter: const ScheduleTrackPainter(Color(0xFF65578B)),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Night sleep',
                  style: TextStyle(color: muted, fontSize: 16),
                ),
                const SizedBox(height: 8),
                Text(
                  bed == null ? '-' : durationLabel(c.nightSleepForDay(day)),
                  style: const TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Night wakings',
                  style: TextStyle(color: muted, fontSize: 16),
                ),
                const SizedBox(height: 8),
                Text(
                  wakings == 0 ? '-' : '$wakings times',
                  style: const TextStyle(fontSize: 24),
                ),
              ],
            ),
          ),
        ),
        TextButton(
          key: const ValueKey('night-bedtime'),
          onPressed: () {
            if (bed != null) {
              showEditor(context, c, ActivityKind.bedtime, entry: bed);
              return;
            }
            showModalBottomSheet<void>(
              context: context,
              useSafeArea: true,
              backgroundColor: ink,
              builder: (ctx) => SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          const SizedBox(width: 48),
                          const Expanded(
                            child: Text(
                              'Predicted bedtime',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 22),
                            ),
                          ),
                          IconButton(
                            tooltip: 'Close',
                            onPressed: () => Navigator.pop(ctx),
                            icon: const Icon(Icons.close),
                          ),
                        ],
                      ),
                      Image.asset(
                        'assets/tracking/headers/bedtime.webp',
                        height: 148,
                      ),
                      Text(
                        clockLabel(defaultBed, c.profile),
                        style: const TextStyle(fontSize: 36),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: () => showEditor(
                            ctx,
                            c,
                            ActivityKind.bedtime,
                            initialStart: defaultBed,
                          ),
                          child: const Text('Log bedtime'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
          child: Column(
            children: [
              Image.asset(
                'assets/main_screen/schedule_info/schedule_circle/bedtime_icon.png',
                width: 32,
                height: 32,
              ),
              Text(clockLabel(bed?.start ?? defaultBed, c.profile)),
              const Text('Bedtime', style: TextStyle(color: muted)),
            ],
          ),
        ),
      ],
    );
  }
}

class _DaySchedule extends StatelessWidget {
  const _DaySchedule({required this.controller, required this.day});
  final TrackerController controller;
  final DateTime day;
  @override
  Widget build(BuildContext context) {
    final c = controller;
    return Stack(
      children: [
        ScheduleDial(controller: c, day: day),
        Positioned(
          top: 8,
          right: 16,
          child: InkWell(
            key: const ValueKey('debug_share_button_day_schedule'),
            onTap: () => showShare(context, c, day),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: surface.withValues(alpha: .7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Image.asset(
                'assets/common/share.webp',
                width: 20,
                height: 20,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class WakeWindowsSection extends StatelessWidget {
  const WakeWindowsSection({
    super.key,
    required this.scale,
    required this.day,
  });

  final DialScale scale;
  final DateTime day;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey('wake_windows_section'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Wake windows',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontFamily: 'SourceSerif4',
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        WakeWindowsCard(scale: scale),
      ],
    );
  }
}

class WakeWindowsCard extends StatefulWidget {
  const WakeWindowsCard({
    super.key,
    required this.scale,
  });

  final DialScale scale;

  @override
  State<WakeWindowsCard> createState() => _WakeWindowsCardState();
}

class _WakeWindowsCardState extends State<WakeWindowsCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final norm = widget.scale.norm;
    final items = widget.scale.wakeWindows;
    final showItems = _expanded ? items : items.take(3).toList();

    return Container(
      key: const ValueKey('wake_windows_card'),
      decoration: BoxDecoration(
        color: surface.withValues(alpha: .8),
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          WakeWindowCommonRangeLabel(norm: norm),
          const SizedBox(height: 12),
          if (items.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Text(
                  'No wake windows recorded yet',
                  style: TextStyle(color: muted, fontSize: 14),
                ),
              ),
            )
          else ...[
            for (int i = 0; i < showItems.length; i++) ...[
              if (i > 0)
                Divider(
                  height: 1,
                  color: muted.withValues(alpha: .2),
                ),
              WakeWindowTile(item: showItems[i]),
            ],
            if (items.length > 3) ...[
              const SizedBox(height: 8),
              Center(
                child: TextButton(
                  key: const ValueKey('wake_windows_toggle_button'),
                  onPressed: () => setState(() => _expanded = !_expanded),
                  child: Text(
                    _expanded ? 'Show less' : 'Show all (${items.length})',
                    style: const TextStyle(color: Color(0xFFC6ABB6)),
                  ),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class WakeWindowCommonRangeLabel extends StatelessWidget {
  const WakeWindowCommonRangeLabel({
    super.key,
    required this.norm,
  });

  final SleepNormBand norm;

  static String _formatHours(double minutes) {
    final hours = minutes / 60.0;
    if (hours == hours.roundToDouble()) {
      return hours.toInt().toString();
    }
    return hours.toStringAsFixed(1);
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      'Common for this age: ${_formatHours(norm.wakeWindow.min.inMinutes.toDouble())} - ${_formatHours(norm.wakeWindow.max.inMinutes.toDouble())} h',
      key: const ValueKey('wake_windows_common_range'),
      style: const TextStyle(
        color: muted,
        fontSize: 14,
        fontWeight: FontWeight.w400,
      ),
    );
  }
}

class WakeWindowTile extends StatelessWidget {
  const WakeWindowTile({
    super.key,
    required this.item,
  });

  final WakeWindowItem item;

  String _ordinalLabel(int index, bool isCurrent) {
    if (isCurrent) return 'Current wake window';
    switch (index) {
      case 1:
        return '1st wake window';
      case 2:
        return '2nd wake window';
      case 3:
        return '3rd wake window';
      case 4:
        return '4th wake window';
      case 5:
        return '5th wake window';
      case 6:
        return '6th wake window';
      case 7:
        return '7th wake window';
      case 8:
        return '8th wake window';
      case 9:
        return '9th wake window';
      case 10:
        return '10th wake window';
      case 11:
        return '11th wake window';
      default:
        return '${index}th wake window';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _ordinalLabel(item.index, item.isCurrent),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  durationLabel(item.duration),
                  style: const TextStyle(
                    color: muted,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          WakeWindowBadge(status: item.status),
        ],
      ),
    );
  }
}

class WakeWindowBadge extends StatelessWidget {
  const WakeWindowBadge({
    super.key,
    required this.status,
  });

  final WakeWindowStatus status;

  @override
  Widget build(BuildContext context) {
    final Color bg;
    final Color fg;
    final String label;
    final bool showDot;

    switch (status) {
      case WakeWindowStatus.current:
        bg = const Color(0xFF1E382A);
        fg = const Color(0xFF81C784);
        label = 'Ongoing';
        showDot = true;
        break;
      case WakeWindowStatus.ok:
        bg = const Color(0xFF1E382A);
        fg = const Color(0xFF81C784);
        label = 'Within range';
        showDot = false;
        break;
      case WakeWindowStatus.short:
        bg = const Color(0xFF3E3228);
        fg = const Color(0xFFFFA726);
        label = 'Short';
        showDot = false;
        break;
      case WakeWindowStatus.long:
        bg = const Color(0xFF382A45);
        fg = const Color(0xFFCE93D8);
        label = 'Long';
        showDot = false;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showDot) ...[
            const WakeWindowPulsingDot(),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: TextStyle(
              color: fg,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class WakeWindowPulsingDot extends StatefulWidget {
  const WakeWindowPulsingDot({super.key});

  @override
  State<WakeWindowPulsingDot> createState() => _WakeWindowPulsingDotState();
}

class _WakeWindowPulsingDotState extends State<WakeWindowPulsingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _animation = Tween<double>(begin: 0.3, end: 1.0).animate(_controller);
    if (!WidgetsBinding.instance.runtimeType.toString().contains('Test')) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _animation,
      child: Container(
        width: 8,
        height: 8,
        decoration: const BoxDecoration(
          color: Color(0xFF81C784),
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

