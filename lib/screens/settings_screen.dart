import 'package:flutter/material.dart';

import '../core/app_strings.dart';
import '../data/settings_controller.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key, required this.settings});

  final SettingsController settings;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(AppStrings.pengaturan),
      ),
      body: SafeArea(
        top: false,
        child: AnimatedBuilder(
          animation: settings,
          builder: (context, _) {
            return ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                SwitchListTile.adaptive(
                  value: settings.isVocal,
                  onChanged: settings.setVocal,
                  title: const Text(AppStrings.isVocalTitle),
                  subtitle: const Text(AppStrings.isVocalSummary),
                ),
                const Divider(indent: 16, endIndent: 16),
                SwitchListTile.adaptive(
                  value: settings.showTranslation,
                  onChanged: settings.setShowTranslation,
                  title: const Text(AppStrings.showTranslationTitle),
                  subtitle: const Text(AppStrings.showTranslationSummary),
                ),
                const Divider(indent: 16, endIndent: 16),
                SwitchListTile.adaptive(
                  value: settings.showSimilarity,
                  onChanged: settings.setShowSimilarity,
                  title: const Text(AppStrings.showSimilarityTitle),
                  subtitle: const Text(AppStrings.showSimilaritySummary),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
