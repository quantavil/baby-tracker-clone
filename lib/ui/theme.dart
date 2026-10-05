import 'package:flutter/material.dart';
import '../model.dart';
import '../controller.dart' show ActivityOverlapError;

const ink = Color(0xFF151326),
    surface = Color(0xFF302841),
    lavender = Color(0xFFBEA5F3),
    muted = Color(0xFF9583AF),
    accent = Color(0xFF8D6BC7);
ThemeData trackerTheme() => ThemeData(
  brightness: Brightness.dark,
  fontFamily: 'RobotoFlex',
  scaffoldBackgroundColor: ink,
  colorScheme: const ColorScheme.dark(
    primary: lavender,
    secondary: accent,
    surface: surface,
    onSurface: Color(0xFFE6D8FF),
  ),
  useMaterial3: true,
  appBarTheme: const AppBarTheme(
    backgroundColor: Colors.transparent,
    foregroundColor: Color(0xFFE6D8FF),
    centerTitle: true,
  ),
  textTheme: const TextTheme(
    headlineLarge: TextStyle(
      fontFamily: 'SourceSerif4',
      fontWeight: FontWeight.w700,
      fontSize: 30,
    ),
    headlineMedium: TextStyle(
      fontFamily: 'SourceSerif4',
      fontWeight: FontWeight.w600,
      fontSize: 24,
    ),
    titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
    bodyLarge: TextStyle(fontSize: 16),
    bodyMedium: TextStyle(fontSize: 14),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: surface,
    border: OutlineInputBorder(
      borderSide: BorderSide.none,
      borderRadius: BorderRadius.circular(14),
    ),
    hintStyle: const TextStyle(color: muted),
    contentPadding: const EdgeInsets.all(16),
  ),
  filledButtonTheme: FilledButtonThemeData(
    style: FilledButton.styleFrom(
      backgroundColor: accent,
      foregroundColor: Colors.white,
      minimumSize: const Size(0, 50),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ),
  ),
  switchTheme: SwitchThemeData(
    thumbColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) {
        return Colors.white;
      }
      return const Color(0xFFC5B6DF);
    }),
    trackColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) {
        return accent;
      }
      return const Color(0xFF3B3252);
    }),
    trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
  ),
  dividerTheme: const DividerThemeData(color: Color(0xFF494056), space: 1),
);

class Backdrop extends StatelessWidget {
  const Backdrop({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Material(
    color: ink,
    child: Ink(
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/main_screen/background_day.webp'),
          fit: BoxFit.cover,
        ),
      ),
      child: child,
    ),
  );
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key});
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 36, bottom: 12),
    child: Text(
      text,
      style: const TextStyle(
        color: lavender,
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}

class ActivityIcon extends StatelessWidget {
  const ActivityIcon(this.kind, {super.key, this.size = 36});
  final ActivityKind kind;
  final double size;
  @override
  Widget build(BuildContext context) => Image.asset(
    'assets/tracking/icons/${kind.asset}.webp',
    width: size,
    height: size,
  );
}

String shortDate(DateTime d, DateTime now) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  final today = d.year == now.year && d.month == now.month && d.day == now.day;
  const weekdays = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];
  return '${today ? 'Today' : weekdays[d.weekday - 1]}, ${months[d.month - 1]} ${d.day}';
}

String clockLabel(DateTime t, BabyProfile p) => p.use24Hour
    ? '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}'
    : '${t.hour % 12 == 0 ? 12 : t.hour % 12}:${t.minute.toString().padLeft(2, '0')} ${t.hour < 12 ? 'AM' : 'PM'}';
String dialTimeLabel(DateTime t, BabyProfile p) => p.use24Hour
    ? '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}'
    : '${t.hour % 12 == 0 ? 12 : t.hour % 12}:${t.minute.toString().padLeft(2, '0')}';
String relativeAgo(DateTime time, DateTime now) {
  final diff = now.difference(time);
  if (diff.isNegative || diff.inMinutes < 1) return 'Just now';
  final h = diff.inHours;
  final m = diff.inMinutes % 60;
  if (h > 0 && m > 0) return '$h h $m min ago';
  if (h > 0) return '$h h ago';
  return '$m min ago';
}

String durationLabel(Duration d) => '${d.inHours} h ${d.inMinutes % 60} min';
String scheduleDurationLabel(Duration duration) {
  final minutes = duration.inMinutes.abs();
  if (minutes < 60) return '$minutes min';
  final remaining = minutes % 60;
  return '${minutes ~/ 60} h${remaining == 0 ? '' : ' $remaining min'}';
}

String timerLabel(Duration d) =>
    '${d.inHours.toString().padLeft(2, '0')}:${(d.inMinutes % 60).toString().padLeft(2, '0')}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';
Future<bool> perform(
  BuildContext context,
  Future<void> Function() action, {
  Future<void> Function()? onOverlap,
}) async {
  try {
    await action();
    return true;
  } catch (e) {
    if (e is ActivityOverlapError && onOverlap != null && context.mounted) {
      await onOverlap();
      return false;
    }
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e is ArgumentError
                ? '${e.message}'
                : 'Could not save. Please try again.',
          ),
        ),
      );
    }
    return false;
  }
}

String activityDetailsLabel(ActivityEntry e, BabyProfile p) {
  final amount = e.details.amount;
  return [
    e.details.choice,
    e.details.food,
    if (amount != null)
      '${(amount / (p.metric
              ? 1
              : e.kind == ActivityKind.bottleFeeding
              ? kMlPerFlOz
              : kGramsPerOz)).toStringAsFixed(p.metric ? 1 : 2)} ${e.kind == ActivityKind.bottleFeeding ? (p.metric ? 'ml' : 'fl oz') : (p.metric ? 'g' : 'oz')}',
  ].where((s) => s.isNotEmpty).join(' · ');
}
