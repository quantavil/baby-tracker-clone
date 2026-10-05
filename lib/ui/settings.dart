import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../controller.dart';
import '../model.dart';
import 'theme.dart';
import 'editor.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key, required this.controller});
  final TrackerController controller;
  @override
  Widget build(BuildContext context) {
    final c = controller;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 26, 16, 24),
      children: [
        Text('Settings', style: Theme.of(context).textTheme.headlineLarge),
        const SizedBox(height: 24),
        const SectionTitle('BABY PROFILE'),
        _row(context, 'Name', 'name_settings', () => _name(context)),
        _row(
          context,
          'Birthday',
          'birthday_settings',
          () => _birthday(context),
        ),
        _row(
          context,
          'Sleep settings',
          'sleep_settings',
          () =>
              _open(context, 'Sleep settings', SleepPreferences(controller: c)),
        ),
        const SectionTitle('APP PREFERENCES'),
        _row(
          context,
          'Regional settings',
          'regional_settings',
          () => _open(
            context,
            'Regional settings',
            RegionalPreferences(controller: c),
          ),
        ),
        _row(
          context,
          'Notifications',
          'notifications_settings',
          () => _open(
            context,
            'Notifications',
            NotificationPreferences(controller: c),
          ),
        ),
        const SectionTitle('OTHER'),
        _row(
          context,
          'What the circle shows',
          'info',
          () => _open(
            context,
            'What the circle shows',
            const CircleExplanation(),
          ),
        ),
        _row(
          context,
          'Help and feedback',
          'help_and_feedback_settings',
          () => _open(context, 'How can we help you?', const LocalHelp()),
        ),
        _row(
          context,
          'Rate app',
          'rate_settings',
          () => _info(
            context,
            'Rate app',
            'This local reconstruction has no store listing yet.',
          ),
        ),
        _row(
          context,
          'Privacy',
          'privacy_settings',
          () => _info(
            context,
            'Privacy',
            'Your profile and tracking records are stored locally on this device. This reconstruction does not connect to the original app’s account or send feedback, analytics or purchases. Clearing app/browser storage removes local records.',
          ),
        ),
        const SectionTitle('DATA & BACKUP'),
        _row(
          context,
          'Export backup (JSON)',
          'account_details_settings',
          () => _exportData(context),
        ),
        _row(
          context,
          'Restore backup (JSON)',
          'settings_share',
          () => restoreBackup(context, controller),
        ),
        _row(
          context,
          'Reset tracking data',
          'privacy_settings',
          () => _clearData(context),
        ),
        const SectionTitle('ABOUT'),
        const Text(
          'All tracking and statistics are free. Records stay on this device. Cloud sync and Android widgets are not available in this web preview.',
          style: TextStyle(color: muted, fontSize: 12),
        ),
        if (c.entries.isEmpty)
          TextButton(
            onPressed: () => _demo(context),
            child: const Text('Add sample logs (demo data)'),
          ),
      ],
    );
  }

  Widget _row(
    BuildContext context,
    String title,
    String asset,
    VoidCallback tap,
  ) => Column(
    children: [
      ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Image.asset(
          'assets/tabs/settings/$asset.webp',
          width: 26,
          height: 26,
          color: const Color(0xFFE6D8FF),
        ),
        title: Text(
          title,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w400),
        ),
        minTileHeight: 50,
        trailing: const Icon(Icons.chevron_right, color: lavender),
        onTap: tap,
      ),
      const Divider(),
    ],
  );
  void _open(BuildContext context, String title, Widget child) =>
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (ctx) => Scaffold(
            backgroundColor: const Color(0xFF252131),
            body: SafeArea(
              child: Column(
                children: [
                  AppBar(
                    toolbarHeight: 84,
                    leading: Padding(
                      padding: const EdgeInsets.only(left: 16),
                      child: Center(
                        child: IconButton(
                          tooltip: 'Back',
                          onPressed: () => Navigator.pop(ctx),
                          style: IconButton.styleFrom(
                            backgroundColor: const Color(0xFF65578B),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          icon: const Icon(Icons.chevron_left),
                        ),
                      ),
                    ),
                    title: Text(
                      title,
                      style: Theme.of(ctx).textTheme.headlineMedium,
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 560),
                        child: child,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
  Future<void> _name(BuildContext context) async {
    final input = TextEditingController(text: controller.profile.name);
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Enter your baby’s name'),
        content: TextField(
          key: const ValueKey('baby-name'),
          controller: input,
          maxLength: 80,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Baby’s name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, input.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    // Route animations may still refer to the input during dismissal.
    if (name != null && context.mounted) {
      await perform(
        context,
        () => controller.updateProfile(controller.profile.copyWith(name: name)),
      );
    }
    await Future<void>.delayed(const Duration(milliseconds: 300));
    input.dispose();
  }

  Future<void> _birthday(BuildContext context) async {
    final d = await pickWheel(
      context,
      'Enter your baby’s birthday',
      controller.profile.birthday ?? controller.now,
      CupertinoDatePickerMode.date,
      controller.now,
    );
    if (d != null && context.mounted) {
      await perform(
        context,
        () => controller.updateProfile(
          controller.profile.copyWith(
            birthday: DateTime(d.year, d.month, d.day),
          ),
        ),
      );
    }
  }

  Future<void> _exportData(BuildContext context) async {
    final raw = controller.exportJson();
    try {
      await Clipboard.setData(ClipboardData(text: raw));
      if (context.mounted) {
        showDialog<void>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Backup exported'),
            content: const Text(
              'Your entire tracking database and profile have been copied to your clipboard as JSON. You can paste and save it safely in a notes or backup file.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not copy export to clipboard.')),
        );
      }
    }
  }

  Future<void> _clearData(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset tracking data?'),
        content: const Text(
          'This will permanently delete all logged sleep, feedings, diapers, and activities from this device. Your baby profile will be kept.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Reset',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      final success = await perform(context, controller.clearAll);
      if (success && context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Tracking data cleared.')));
      }
    }
  }

  void _info(BuildContext context, String title, String body) =>
      showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(title),
          content: Text(body),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Close'),
            ),
          ],
        ),
      );
  Future<void> _demo(BuildContext context) async {
    final today = controller.now;
    final day = DateTime(today.year, today.month, today.day - 1);
    await perform(context, () async {
      await controller.saveEntry(
        ActivityEntry(
          id: 'demo-wakeup',
          kind: ActivityKind.wakeUp,
          start: DateTime(day.year, day.month, day.day, 7, 20),
          note: 'Demo record',
        ),
      );
      await controller.saveEntry(
        ActivityEntry(
          id: 'demo-nap',
          kind: ActivityKind.nap,
          start: DateTime(day.year, day.month, day.day, 8, 20),
          end: DateTime(day.year, day.month, day.day, 9, 40),
          note: 'Demo record',
        ),
      );
    });
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sample logs are on yesterday’s date.')),
      );
    }
  }
}

class RegionalPreferences extends StatelessWidget {
  const RegionalPreferences({super.key, required this.controller});
  final TrackerController controller;
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: controller,
    builder: (context, _) => ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          minTileHeight: 80,
          title: const Text('Time format', style: TextStyle(fontSize: 17)),
          subtitle: Text(
            controller.profile.use24Hour ? '24-hour' : '12-hour (AM/PM)',
          ),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _choice(
            context,
            'Time format',
            ['24-hour', '12-hour (AM/PM)'],
            controller.profile.use24Hour ? 0 : 1,
            (i) => controller.updateProfile(
              controller.profile.copyWith(use24Hour: i == 0),
            ),
          ),
        ),
        const Divider(),
        ListTile(
          contentPadding: EdgeInsets.zero,
          minTileHeight: 80,
          title: const Text(
            'Measurement units',
            style: TextStyle(fontSize: 17),
          ),
          subtitle: Text(
            controller.profile.metric
                ? 'Metric (ml, g)'
                : 'Imperial (fl oz, oz)',
          ),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _choice(
            context,
            'Measurement units',
            ['Metric (ml, g)', 'Imperial (fl oz, oz)'],
            controller.profile.metric ? 0 : 1,
            (i) => controller.updateProfile(
              controller.profile.copyWith(metric: i == 0),
            ),
          ),
        ),
      ],
    ),
  );
  Future<void> _choice(
    BuildContext context,
    String title,
    List<String> choices,
    int selected,
    Future<void> Function(int) action,
  ) async {
    final value = await showDialog<int>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: const Color(0xFF2C253D),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 380),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 20),
                for (var i = 0; i < choices.length; i++) ...[
                  if (i > 0) const SizedBox(height: 10),
                  Material(
                    color: i == selected
                        ? accent.withValues(alpha: .35)
                        : surface.withValues(alpha: .8),
                    borderRadius: BorderRadius.circular(14),
                    clipBehavior: Clip.antiAlias,
                    child: ListTile(
                      title: Text(
                        choices[i],
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: i == selected
                              ? FontWeight.w600
                              : FontWeight.w400,
                          color: i == selected
                              ? Colors.white
                              : const Color(0xFFE6D8FF),
                        ),
                      ),
                      trailing: Icon(
                        i == selected
                            ? Icons.radio_button_checked
                            : Icons.radio_button_off,
                        color: i == selected ? lavender : muted,
                      ),
                      onTap: () => Navigator.pop(ctx, i),
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF494056)),
                    foregroundColor: const Color(0xFFE6D8FF),
                    minimumSize: const Size(0, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (value != null && context.mounted) {
      await perform(context, () => action(value));
    }
  }
}

class SleepPreferences extends StatelessWidget {
  const SleepPreferences({super.key, required this.controller});
  final TrackerController controller;
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: controller,
    builder: (context, _) {
      final c = controller;
      final p = c.profile;
      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Custom nap schedule'),
            subtitle: const Text(
              'Enable to choose your own number of naps (default is 2)',
            ),
            value: p.customNaps,
            onChanged: c.writing
                ? null
                : (v) => perform(
                    context,
                    () => c.updateProfile(p.copyWith(customNaps: v)),
                  ),
          ),
          if (p.customNaps)
            InputDecorator(
              decoration: const InputDecoration(labelText: 'Number of naps'),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<int>(
                  key: const ValueKey('nap-count'),
                  value: p.napCount,
                  isExpanded: true,
                  items: List.generate(
                    8,
                    (i) =>
                        DropdownMenuItem(value: i + 1, child: Text('${i + 1}')),
                  ),
                  onChanged: c.writing
                      ? null
                      : (v) {
                          if (v != null) {
                            perform(
                              context,
                              () => c.updateProfile(p.copyWith(napCount: v)),
                            );
                          }
                        },
                ),
              ),
            ),
          const Divider(height: 32),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Custom wake-up time'),
            subtitle: const Text('Enable to choose your own wake-up time'),
            value: p.customWakeUp,
            onChanged: c.writing
                ? null
                : (v) => perform(
                    context,
                    () => c.updateProfile(p.copyWith(customWakeUp: v)),
                  ),
          ),
          if (p.customWakeUp)
            ListTile(
              title: const Text('Wake-up time'),
              subtitle: Text(
                clockLabel(
                  DateTime(
                    2026,
                    1,
                    1,
                    p.wakeUpMinutes ~/ 60,
                    p.wakeUpMinutes % 60,
                  ),
                  p,
                ),
              ),
              onTap: () async {
                final today = c.now;
                final t = await pickWheel(
                  context,
                  'Wake-up time',
                  DateTime(
                    today.year,
                    today.month,
                    today.day,
                    p.wakeUpMinutes ~/ 60,
                    p.wakeUpMinutes % 60,
                  ),
                  CupertinoDatePickerMode.time,
                  today,
                  use24Hour: p.use24Hour,
                );
                if (t != null && context.mounted) {
                  await perform(
                    context,
                    () => c.updateProfile(
                      p.copyWith(wakeUpMinutes: t.hour * 60 + t.minute),
                    ),
                  );
                }
              },
            ),
        ],
      );
    },
  );
}

class NotificationPreferences extends StatelessWidget {
  const NotificationPreferences({super.key, required this.controller});
  final TrackerController controller;
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: controller,
    builder: (context, _) => ListView(
      padding: const EdgeInsets.all(16),
      children: [
        SwitchListTile(
          key: ValueKey(
            'debug_notification_toggle_${controller.profile.notifications}',
          ),
          contentPadding: EdgeInsets.zero,
          title: const Text('Notifications'),
          subtitle: const Text(
            'Receive notifications about upcoming naps and bedtime',
          ),
          value: controller.profile.notifications,
          onChanged: controller.writing
              ? null
              : (v) => perform(
                  context,
                  () => controller.updateProfile(
                    controller.profile.copyWith(notifications: v),
                  ),
                ),
        ),
        const SizedBox(height: 24),
        const Text(
          'The preference is saved. Actual notification scheduling is not connected yet.',
          style: TextStyle(color: muted, fontSize: 12),
        ),
      ],
    ),
  );
}

class CircleExplanation extends StatelessWidget {
  const CircleExplanation({super.key});
  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(20),
    children: [
      const SizedBox(height: 8),
      for (final row in [
        (
          'Predicted nap',
          'Nap window prediction from Luli',
          'automation_schedule_legend_item_nap_predicted',
        ),
        (
          'Logged nap',
          'Nap you’ve added',
          'automation_schedule_legend_item_nap_marked',
        ),
        (
          'Ongoing nap',
          'Nap that is not finished yet',
          'automation_schedule_legend_item_nap_active',
        ),
      ])
        ListTile(
          key: ValueKey(row.$3),
          leading: Container(
            width: 38,
            height: 12,
            decoration: BoxDecoration(
              color: row.$1 == 'Predicted nap'
                  ? const Color(0x33B49AD9)
                  : lavender,
              border: Border.all(color: lavender, width: 2),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          title: Text(row.$1),
          subtitle: Text(row.$2),
        ),
      const SizedBox(height: 20),
      const Text(
        'The circle shows recorded sleep from wake-up to bedtime, or the end of the day when bedtime is not logged. Without a wake-up log, it shows the full day.',
        style: TextStyle(color: muted, fontSize: 12),
      ),
    ],
  );
}

class LocalHelp extends StatelessWidget {
  const LocalHelp({super.key});
  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(20),
    children: [
      const Text(
        'Use + to record wake-up, naps, bedtime, night waking, nursing, bottles, solids or diapers. All eight tracking categories are free. Tap an activity in History to edit or delete it. Pause and stop controls are on Home for ongoing sleep timers; nursing has its own stop control.',
      ),
      const SizedBox(height: 24),
      const TextField(
        maxLines: 5,
        decoration: InputDecoration(hintText: 'Tell us more details…'),
      ),
      const SizedBox(height: 16),
      const FilledButton(onPressed: null, child: Text('Submit')),
      const SizedBox(height: 12),
      const Text(
        'Feedback submission is not connected in the local app.',
        style: TextStyle(color: muted, fontSize: 12),
      ),
    ],
  );
}

Future<void> restoreBackup(
  BuildContext context,
  TrackerController controller,
) async {
  final input = TextEditingController();
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Restore backup'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Paste your exported JSON backup below to restore your tracking records and profile:',
            style: TextStyle(fontSize: 13, color: muted),
          ),
          const SizedBox(height: 12),
          TextField(
            key: const ValueKey('restore-backup-json'),
            controller: input,
            maxLines: 6,
            style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
            decoration: const InputDecoration(
              hintText: 'Paste backup JSON here…',
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('Restore'),
        ),
      ],
    ),
  );
  if (ok == true && input.text.trim().isNotEmpty && context.mounted) {
    final success = await perform(
      context,
      () => controller.importJson(input.text.trim()),
    );
    if (success && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Backup restored successfully!')),
      );
    }
  }
  await Future<void>.delayed(const Duration(milliseconds: 300));
  input.dispose();
}
