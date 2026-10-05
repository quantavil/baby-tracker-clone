import 'package:flutter/material.dart';
import 'app.dart';
import 'controller.dart';
import 'storage.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final controller = TrackerController(PreferenceStorage());
  await controller.load();
  runApp(BabyTrackerApp(controller: controller));
}
