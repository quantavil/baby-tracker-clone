import 'package:flutter/material.dart';
import '../controller.dart';
import 'theme.dart';
import 'editor.dart';
import 'share.dart';

class HistoryPage extends StatelessWidget {
  const HistoryPage({
    super.key,
    required this.controller,
    required this.day,
    required this.onDay,
  });
  final TrackerController controller;
  final DateTime day;
  final ValueChanged<DateTime> onDay;
  @override
  Widget build(BuildContext context) {
    final c = controller;
    final entries = c.entriesForDay(day);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
      children: [
        Text('History', style: Theme.of(context).textTheme.headlineLarge),
        const SizedBox(height: 18),
        Row(
          children: [
            IconButton(
              onPressed: () =>
                  onDay(DateTime(day.year, day.month, day.day - 1)),
              tooltip: 'Previous day',
              icon: const Icon(Icons.chevron_left),
            ),
            Expanded(
              child: Text(
                shortDate(day, c.now),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            IconButton(
              onPressed:
                  day.isBefore(DateTime(c.now.year, c.now.month, c.now.day))
                  ? () => onDay(DateTime(day.year, day.month, day.day + 1))
                  : null,
              tooltip: 'Next day',
              icon: const Icon(Icons.chevron_right),
            ),
            InkWell(
              key: const ValueKey('debug_share_button_history'),
              onTap: () => showShare(context, c, day),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: surface.withValues(alpha: .7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Image.asset(
                  'assets/tabs/home/share_app_button.webp',
                  width: 20,
                  height: 20,
                ),
              ),
            ),
          ],
        ),
        if (entries.isEmpty) ...[
          const SizedBox(height: 36),
          Image.asset('assets/tabs/history/empty_history.webp', height: 180),
          const SizedBox(height: 18),
          const Center(
            child: Text(
              'Your story starts here',
              style: TextStyle(fontSize: 21, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 8),
          const Center(
            child: Text(
              'Tap + to log your first activity',
              style: TextStyle(color: muted),
            ),
          ),
        ],
        for (final e in entries)
          InkWell(
            key: ValueKey('entry-${e.id}'),
            onTap: () => showEditor(context, c, e.kind, entry: e),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 78,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          clockLabel(e.start, c.profile),
                          style: const TextStyle(fontSize: 13),
                        ),
                        if (e.kind.interval)
                          Text(
                            e.end == null
                                ? 'now'
                                : clockLabel(e.end!, c.profile),
                            style: const TextStyle(color: muted, fontSize: 13),
                          ),
                      ],
                    ),
                  ),
                  Container(
                    width: 3,
                    height: 46,
                    margin: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: e.kind.interval ? muted : const Color(0xFFD6AD70),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  ActivityIcon(e.kind, size: 32),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${e.kind.label}${e.kind.interval ? ' · ${durationLabel(c.elapsed(e))}' : ''}',
                          style: const TextStyle(fontSize: 17),
                        ),
                        if (e.details.choice.isNotEmpty ||
                            e.details.amount != null ||
                            e.details.food.isNotEmpty)
                          Text(
                            activityDetailsLabel(e, c.profile),
                            style: const TextStyle(color: muted, fontSize: 13),
                          ),
                        Text(
                          relativeAgo(e.end ?? e.start, c.now),
                          style: const TextStyle(color: muted, fontSize: 13),
                        ),
                        if (e.note.isNotEmpty)
                          Text(
                            e.note,
                            style: const TextStyle(color: muted, fontSize: 13),
                          ),
                        if (e.paused)
                          const Text(
                            'Paused',
                            style: TextStyle(color: lavender, fontSize: 12),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
