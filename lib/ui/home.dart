import 'package:flutter/material.dart';
import '../controller.dart';
import '../model.dart';
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
        ListView(
          padding: const EdgeInsets.fromLTRB(0, 16, 0, 24),
          children:
              [
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
                    if (c.conflictingNapsForDay(day).isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
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
                                  entry: c.conflictingNapsForDay(day).first,
                                ),
                        ),
                      ),
                    if (c.active != null &&
                        (!DateUtils.isSameDay(day, c.now) ||
                            !DateUtils.isSameDay(c.active!.start, day) ||
                            showNight)) ...[
                      const SizedBox(height: 12),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
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
                                  crossAxisAlignment: CrossAxisAlignment.start,
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
                                        c.active!.paused ? c.resume : c.pause,
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
                    ],
                    const SizedBox(height: 14),
                    DayStrip(day: day, now: c.now, onDay: onDay),
                    const SizedBox(height: 24),
                    if (showNight)
                      _NightSchedule(controller: c, day: day)
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
                                      value ? 'schedule-night' : 'schedule-day',
                                    ),
                                    style: TextButton.styleFrom(
                                      minimumSize: const Size(76, 42),
                                      foregroundColor: const Color(0xFFE6D8FF),
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
                                      style: const TextStyle(fontSize: 16),
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
                      key: const ValueKey('main_data_accumulation_banner'),
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
                              crossAxisAlignment: CrossAxisAlignment.start,
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
                                  valueColor: const AlwaysStoppedAnimation(
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
                                  : () => perform(context, c.finishNursing),
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
                            'Overview · ${shortDate(day, c.now)}',
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                        ),
                        InkWell(
                          key: const ValueKey('debug_share_button_overview'),
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
                    _overview(
                      context,
                      'Day sleep',
                      durationLabel(
                        c.totalForDay(
                          day,
                          forSchedule: true,
                          includeOngoing:
                              DateUtils.isSameDay(day, c.now) &&
                              c.active != null &&
                              DateUtils.isSameDay(c.active!.start, day),
                        ),
                      ),
                      'Logged naps',
                    ),
                    const SizedBox(height: 12),
                    _overview(
                      context,
                      'Night sleep',
                      durationLabel(c.nightSleepForDay(day)),
                      'Logged bedtime to wake-up',
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Add bedtime and wake-up logs to complete your night-sleep history.',
                      style: TextStyle(color: muted, fontSize: 12),
                    ),
                  ]
                  .map(
                    (child) => child is _DaySchedule || child is _NightSchedule
                        ? child
                        : Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: child,
                          ),
                  )
                  .toList(),
        ),
      ],
    );
  }

  Widget _overview(
    BuildContext context,
    String title,
    String value,
    String caption,
  ) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: surface.withValues(alpha: .75),
      borderRadius: BorderRadius.circular(18),
    ),
    child: Row(
      children: [
        const Icon(Icons.bedtime_outlined, color: lavender, size: 28),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title),
              const SizedBox(height: 5),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 23,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(caption, style: const TextStyle(color: muted, fontSize: 12)),
            ],
          ),
        ),
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
  const _NightSchedule({required this.controller, required this.day});
  final TrackerController controller;
  final DateTime day;
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
    final defaultBed = DateTime(day.year, day.month, day.day, 22);
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
