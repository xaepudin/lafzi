import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../core/app_strings.dart';
import '../data/database_service.dart';
import '../data/settings_controller.dart';
import 'home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, required this.settings});

  final SettingsController settings;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Object? _error;

  @override
  void initState() {
    super.initState();
    _prepare();
  }

  Future<void> _prepare() async {
    setState(() => _error = null);
    try {
      await DatabaseService.instance.initialize();
    } catch (error) {
      if (mounted) {
        setState(() => _error = error);
      }
      return;
    }
    if (!mounted) {
      return;
    }
    Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 260),
        pageBuilder: (context, animation, secondaryAnimation) =>
            HomeScreen(settings: widget.settings),
        transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final colors = context.lafziColors;

    return Scaffold(
      backgroundColor: colors.splashBackground,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  'assets/images/logo_lafzi_big.png',
                  width: 260,
                  fit: BoxFit.contain,
                  semanticLabel: AppStrings.appName,
                ),
                const SizedBox(height: 40),
                if (_error == null)
                  SizedBox(
                    width: 32,
                    height: 32,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      color: scheme.primary,
                    ),
                  )
                else ...[
                  Text(
                    'Gagal menyiapkan database',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: scheme.error),
                  ),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: _prepare,
                    child: const Text('Coba lagi'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
