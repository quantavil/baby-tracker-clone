import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import '../controller.dart';
import '../platform/image_export.dart';
import 'dial.dart';
import 'theme.dart';

Future<void> showShare(
  BuildContext context,
  TrackerController c,
  DateTime day,
) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  backgroundColor: ink,
  builder: (ctx) => SharePreview(controller: c, day: day),
);

class SharePreview extends StatefulWidget {
  const SharePreview({super.key, required this.controller, required this.day});
  final TrackerController controller;
  final DateTime day;
  @override
  State<SharePreview> createState() => _SharePreviewState();
}

class _SharePreviewState extends State<SharePreview> {
  final boundary = GlobalKey();
  bool exporting = false;
  @override
  Widget build(BuildContext context) {
    final c = widget.controller, day = widget.day;
    final birth = c.profile.birthday;
    var months = birth == null
        ? null
        : (day.year - birth.year) * 12 +
              day.month -
              birth.month -
              (day.day < birth.day ? 1 : 0);
    if (months != null && months < 0) months = 0;
    return SizedBox(
      height: MediaQuery.sizeOf(context).height * .95,
      child: Backdrop(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Preview',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                ),
                IconButton(
                  tooltip: 'Close',
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 16),
            RepaintBoundary(
              key: boundary,
              child: Backdrop(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('🐣 ', style: TextStyle(fontSize: 20)),
                          Flexible(
                            child: Text(
                              '${c.profile.name}${months != null ? ', $months ${months == 1 ? 'month' : 'months'}' : ''}',
                              style: Theme.of(context).textTheme.headlineMedium,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Day schedule · ${shortDate(day, c.now)}',
                        style: const TextStyle(color: muted, fontSize: 13),
                      ),
                      ScheduleDial(controller: c, day: day, controls: false),
                      const SizedBox(height: 12),
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _legendPill(
                            'Predicted nap',
                            border: const Color(0xFF5B4D77),
                            textColor: muted,
                          ),
                          _legendPill(
                            'Logged nap',
                            bg: lavender.withValues(alpha: .35),
                            border: lavender,
                            textColor: const Color(0xFFE6D8FF),
                          ),
                          _legendPill(
                            'Ongoing nap',
                            bg: const Color(0xFFDCB4BC).withValues(alpha: .35),
                            border: const Color(0xFFDCB4BC),
                            textColor: const Color(0xFFF0D4DC),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: surface.withValues(alpha: .6),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.asset(
                                'assets/common/app_icon.webp',
                                width: 28,
                                height: 28,
                              ),
                            ),
                            const SizedBox(width: 10),
                            const Expanded(
                              child: FittedBox(
                                alignment: Alignment.centerLeft,
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  'Baby Tracker',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Image.asset(
                              'assets/common/qr.webp',
                              width: 28,
                              height: 28,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    key: const ValueKey('save-image'),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF494056)),
                      backgroundColor: surface,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(0, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: exporting ? null : _save,
                    child: Text(exporting ? 'Saving…' : 'Save'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: accent,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(0, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: () async {
                      try {
                        await Clipboard.setData(
                          ClipboardData(
                            text:
                                '${c.profile.name} · ${shortDate(day, c.now)}\nDay sleep: ${durationLabel(c.totalForDay(day))}\nNight sleep: ${durationLabel(c.nightSleepForDay(day))}\n${c.entriesForDay(day).map((e) => '${clockLabel(e.start, c.profile)} ${e.kind.label} ${activityDetailsLabel(e, c.profile)} ${e.note}').join('\n')}',
                          ),
                        );
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Summary copied to clipboard')),
                          );
                        }
                      } catch (_) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Could not copy. Please try again.'),
                            ),
                          );
                        }
                      }
                    },
                    child: const Text('Share'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    setState(() => exporting = true);
    try {
      await WidgetsBinding.instance.endOfFrame;
      final render =
          boundary.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final image = await render.toImage(pixelRatio: 3);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      if (bytes == null) throw StateError('Unable to encode image');
      await saveImage(
        bytes.buffer.asUint8List(),
        'baby-tracker-${widget.day.toIso8601String().substring(0, 10)}.png',
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Could not save image. Please try again in the web preview.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => exporting = false);
    }
  }

  Widget _legendPill(
    String text, {
    Color? bg,
    Color? border,
    Color textColor = Colors.white,
  }) => Container(
    constraints: const BoxConstraints(maxWidth: 210),
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: bg ?? Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      border: border != null ? Border.all(color: border, width: 1.5) : null,
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          'assets/main_screen/schedule_info/schedule_circle/future_nap.png',
          width: 16,
          height: 16,
        ),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              color: textColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    ),
  );
}
