import 'package:flutter/material.dart';

import 'app.dart';
import 'data/database_service.dart';
import 'data/settings_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final settings = SettingsController();
  await settings.load();

  // The splash only exists to cover the one-time database copy. Once the
  // database is installed, open the database before the first frame and go
  // straight to the home screen; the OS launch screen covers the short wait.
  var showSplash = true;
  try {
    if (!await DatabaseService.instance.needsInstall()) {
      await DatabaseService.instance.initialize();
      showSplash = false;
    }
  } catch (error, stackTrace) {
    debugPrint('Startup preparation failed: $error\n$stackTrace');
    // Let the splash retry and show its error/retry UI.
    showSplash = true;
  }

  runApp(LafziApp(settings: settings, showSplash: showSplash));
}
