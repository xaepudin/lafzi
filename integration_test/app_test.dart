import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:lafzi/main.dart' as app;
import 'package:lafzi/widgets/ayat_card.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('searches Latin and Arabic and opens an ayat', (tester) async {
    SharedPreferences.setMockInitialValues({
      'onboarding_done_v1': true,
      'isvocal': true,
      'showtrans': true,
    });
    await app.main();
    await tester.pumpAndSettle(
      const Duration(milliseconds: 100),
      EnginePhase.sendSemanticsUpdate,
      const Duration(seconds: 90),
    );

    // Dismiss the first-run coach marks if this is a clean install.
    final skip = find.text('Lewati');
    if (skip.evaluate().isNotEmpty) {
      await tester.tap(skip);
      await tester.pumpAndSettle();
    }

    expect(find.byType(TextField), findsOneWidget);

    // Latin phonetic search.
    await tester.enterText(find.byType(TextField), 'bismillah');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();
    expect(find.text('Ditemukan 3 hasil'), findsOneWidget);

    // Arabic FTS search against the bundled database.
    await tester.enterText(find.byType(TextField), '\u200fبسم الله');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();
    expect(find.text('Ditemukan 3 hasil'), findsOneWidget);
    expect(find.textContaining('Surat Al-Fatihah (1) Ayat 1'), findsWidgets);

    // Open the detail pager and verify the reading screen is usable.
    await tester.tap(find.byType(AyatCard).first);
    await tester.pumpAndSettle();
    expect(find.text('Bagikan'), findsOneWidget);
    expect(find.text('Berikut'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();
    expect(find.text('Ditemukan 3 hasil'), findsOneWidget);
  });
}
