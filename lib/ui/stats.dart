import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../controller.dart';
import '../model.dart';
import 'theme.dart';

class StatsPage extends StatefulWidget {
  const StatsPage({super.key, required this.controller});
  final TrackerController controller;
  @override
  State<StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends State<StatsPage> {
  int offset = 0;
  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    final end = DateTime(c.now.year, c.now.month, c.now.day - offset * 7);
    final days = List.generate(
      7,
      (i) => DateTime(end.year, end.month, end.day - 6 + i),
    );
    final nap = days.map((d) => c.totalForDay(d).inMinutes.toDouble()).toList();
    final night = days
        .map((d) => c.nightSleepForDay(d).inMinutes.toDouble())
        .toList();
    final total = List.generate(7, (i) => nap[i] + night[i]);
    final hasData = days.any((d) => c.entriesForDay(d).isNotEmpty);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
      children: [
        Text('Stats', style: Theme.of(context).textTheme.headlineLarge),
        const SizedBox(height: 24),
        Row(
          children: [
            IconButton(
              tooltip: 'Previous week',
              onPressed: () => setState(() => offset++),
              icon: const Icon(Icons.chevron_left),
            ),
            Expanded(
              child: Text(
                '${shortDate(days.first, c.now)} – ${shortDate(end, c.now)}',
                textAlign: TextAlign.center,
              ),
            ),
            IconButton(
              tooltip: 'Next week',
              onPressed: offset == 0 ? null : () => setState(() => offset--),
              icon: const Icon(Icons.chevron_right),
            ),
          ],
        ),
        if (!hasData) ...[
          Image.asset('assets/tabs/stats/empty_stats.webp', height: 160),
          const Text(
            'Your patterns start here',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 21, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          const Text(
            'Log sleep, feeds and diapers to see your weekly trends.',
            textAlign: TextAlign.center,
            style: TextStyle(color: muted),
          ),
          const SizedBox(height: 24),
        ],
        _sleepCard('Total sleep', total, days),
        _sleepCard('Day sleep', nap, days),
        _sleepCard('Night sleep', night, days),
        _card(
          'Nursing',
          durationLabel(
            Duration(
              minutes:
                  (days
                              .map((d) => c.nursingForDay(d).inMinutes)
                              .fold(0, (a, b) => a + b) /
                          7)
                      .round(),
            ),
          ),
          days.map((d) => c.nursingForDay(d).inMinutes.toDouble()).toList(),
          days,
          'min',
        ),
        _card(
          'Bottle feeding',
          '${(days.map((d) => c.amountForDay(d, ActivityKind.bottleFeeding)).fold(0.0, (a, b) => a + b) / 7 / (c.profile.metric ? 1 : kMlPerFlOz)).toStringAsFixed(1)} ${c.profile.metric ? 'ml' : 'fl oz'}',
          days
              .map(
                (d) =>
                    c.amountForDay(d, ActivityKind.bottleFeeding) /
                    (c.profile.metric ? 1 : kMlPerFlOz),
              )
              .toList(),
          days,
          c.profile.metric ? 'ml' : 'fl oz',
        ),
        _card(
          'Solids',
          '${(days.map((d) => c.amountForDay(d, ActivityKind.solids)).fold(0.0, (a, b) => a + b) / 7 / (c.profile.metric ? 1 : kGramsPerOz)).toStringAsFixed(1)} ${c.profile.metric ? 'g' : 'oz'}',
          days
              .map(
                (d) =>
                    c.amountForDay(d, ActivityKind.solids) /
                    (c.profile.metric ? 1 : kGramsPerOz),
              )
              .toList(),
          days,
          c.profile.metric ? 'g' : 'oz',
        ),
        _card(
          'Diaper changes',
          '${(days.map((d) => c.entriesForDay(d).where((e) => e.kind == ActivityKind.diaperChange).length).fold(0, (a, b) => a + b) / 7).toStringAsFixed(1)} per day',
          days
              .map(
                (d) => c
                    .entriesForDay(d)
                    .where((e) => e.kind == ActivityKind.diaperChange)
                    .length
                    .toDouble(),
              )
              .toList(),
          days,
          'changes',
        ),
        const Text(
          'Averages cover all seven calendar days. Missing logs count as zero; totals reflect only recorded activities.',
          style: TextStyle(color: muted, fontSize: 12),
        ),
      ],
    );
  }

  Widget _sleepCard(String title, List<double> values, List<DateTime> days) =>
      _card(
        title,
        durationLabel(
          Duration(minutes: (values.fold(0.0, (a, b) => a + b) / 7).round()),
        ),
        values,
        days,
        'min',
      );
  Widget _card(
    String title,
    String average,
    List<double> values,
    List<DateTime> days,
    String unit,
  ) {
    final maxValue = math.max(1.0, values.reduce(math.max));
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: surface.withValues(alpha: .8),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 8),
          Text(
            'Avg. $average',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 104 + MediaQuery.textScalerOf(context).scale(16) * 2,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(
                7,
                (i) => Expanded(
                  child: Tooltip(
                    message:
                        '${shortDate(days[i], widget.controller.now)}: ${values[i].toStringAsFixed(1)} $unit',
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        FittedBox(
                          child: Text(
                            values[i] == 0 ? '—' : values[i].toStringAsFixed(0),
                            maxLines: 1,
                            style: const TextStyle(
                              fontSize: 10,
                              color: lavender,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          width: 22,
                          height: math.max(2, values[i] / maxValue * 82),
                          decoration: BoxDecoration(
                            color: values[i] == 0
                                ? muted.withValues(alpha: .2)
                                : lavender,
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        const SizedBox(height: 8),
                        FittedBox(
                          child: Text(
                            '${days[i].day}',
                            maxLines: 1,
                            style: const TextStyle(color: muted, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
