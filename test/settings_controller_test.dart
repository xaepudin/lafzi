import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lafzi/core/app_strings.dart';
import 'package:lafzi/data/settings_controller.dart';
import 'package:lafzi/screens/settings_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('similarity is disabled by default', () async {
    final settings = SettingsController();
    await settings.load();

    expect(settings.showSimilarity, isFalse);
    expect(settings.showTranslation, isTrue);
    expect(settings.isVocal, isTrue);
  });

  test('similarity preference is persisted', () async {
    final settings = SettingsController();
    await settings.load();
    await settings.setShowSimilarity(true);

    final reloaded = SettingsController();
    await reloaded.load();
    expect(reloaded.showSimilarity, isTrue);
  });

  test('stored similarity preference is restored', () async {
    SharedPreferences.setMockInitialValues({'showsimilarity': true});
    final settings = SettingsController();
    await settings.load();

    expect(settings.showSimilarity, isTrue);
  });

  testWidgets('settings screen has the similarity toggle, off by default', (
    tester,
  ) async {
    final settings = SettingsController();
    await settings.load();

    await tester.pumpWidget(
      MaterialApp(home: SettingsScreen(settings: settings)),
    );

    final tile = find.widgetWithText(
      SwitchListTile,
      AppStrings.showSimilarityTitle,
    );
    expect(tile, findsOneWidget);
    expect(tester.widget<SwitchListTile>(tile).value, isFalse);

    await tester.tap(tile);
    await tester.pumpAndSettle();

    expect(settings.showSimilarity, isTrue);
    expect(tester.widget<SwitchListTile>(tile).value, isTrue);
  });
}
