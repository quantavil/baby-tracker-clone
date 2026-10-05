import 'dart:async';
import 'package:flutter/material.dart';
import 'controller.dart';
import 'ui/theme.dart';
import 'ui/home.dart';
import 'ui/history.dart';
import 'ui/settings.dart';
import 'ui/stats.dart';
import 'ui/editor.dart';

class BabyTrackerApp extends StatelessWidget {
  const BabyTrackerApp({super.key, required this.controller, this.textScale});
  final TrackerController controller;
  final double? textScale;
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Baby Tracker',
    debugShowCheckedModeBanner: false,
    theme: trackerTheme(),
    builder: (context, child) {
      final media = MediaQuery.of(context);
      final width = media.size.width.clamp(0.0, 412.0);
      return ColoredBox(
        color: ink,
        child: Center(
          child: SizedBox(
            width: width,
            child: MediaQuery(
              data: media.copyWith(
                size: Size(width, media.size.height),
                textScaler: textScale == null
                    ? media.textScaler
                    : TextScaler.linear(textScale!),
              ),
              child: child!,
            ),
          ),
        ),
      );
    },
    home: TrackerShell(controller: controller),
  );
}

class TrackerShell extends StatefulWidget {
  const TrackerShell({super.key, required this.controller});
  final TrackerController controller;
  @override
  State<TrackerShell> createState() => _TrackerShellState();
}

class _TrackerShellState extends State<TrackerShell> {
  int tab = 0;
  late DateTime day;
  Timer? timer;
  @override
  void initState() {
    super.initState();
    day = widget.controller.now;
    timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted &&
          (tab == 0 ||
              widget.controller.active != null ||
              widget.controller.activeNursing != null)) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.controller,
    builder: (context, _) {
      final c = widget.controller;
      return Scaffold(
        body: Backdrop(
          child: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: !c.loaded
                    ? const Center(child: CircularProgressIndicator())
                    : c.error != null
                    ? Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.warning_amber, size: 48),
                            const SizedBox(height: 16),
                            Text(c.error!),
                            const SizedBox(height: 16),
                            FilledButton(
                              onPressed: c.load,
                              child: const Text('Retry loading'),
                            ),
                            TextButton(
                              onPressed: c.writing
                                  ? null
                                  : () => restoreBackup(context, c),
                              child: const Text('Restore backup'),
                            ),
                          ],
                        ),
                      )
                    : switch (tab) {
                        0 => HomePage(
                          controller: c,
                          day: day,
                          onDay: (d) => setState(() => day = d),
                        ),
                        1 => HistoryPage(
                          controller: c,
                          day: day,
                          onDay: (d) => setState(() => day = d),
                        ),
                        2 => StatsPage(controller: c),
                        _ => SettingsPage(controller: c),
                      },
              ),
            ),
          ),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        floatingActionButton: SizedBox(
          key: const ValueKey('debug_log_activity_button'),
          width: 56,
          height: 56,
          child: FloatingActionButton(
            key: const ValueKey('add-activity'),
            tooltip: 'Log activity',
            onPressed: c.loaded && c.error == null && !c.writing
                ? () => showActivityMenu(context, c)
                : null,
            backgroundColor: accent,
            shape: const CircleBorder(),
            child: Image.asset(
              'assets/main_screen/bottom_navigation_bar/fab_plus_icon.webp',
              width: 28,
              height: 28,
            ),
          ),
        ),
        bottomNavigationBar: SafeArea(
          top: false,
          child: Container(
            color: const Color(0xFF1C1929),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              children: [
                _tab(0, 'Home', 'home'),
                _tab(1, 'History', 'history'),
                const SizedBox(width: 62),
                _tab(2, 'Stats', 'stats'),
                _tab(3, 'Settings', 'settings'),
              ],
            ),
          ),
        ),
      );
    },
  );
  Widget _tab(int index, String label, String asset) => Expanded(
    child: InkWell(
      key: ValueKey('tab-$label'),
      onTap: () => setState(() => tab = index),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/main_screen/bottom_navigation_bar/$asset${tab == index ? '_selected' : ''}.webp',
              height: 23,
              width: 23,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                color: tab == index ? lavender : muted,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
