import 'package:flutter/material.dart';

import 'app.dart';
import 'data/settings_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final settings = SettingsController();
  await settings.load();
  runApp(LafziApp(settings: settings));
}
