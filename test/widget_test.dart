import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lafzi/core/app_colors.dart';
import 'package:lafzi/core/app_theme.dart';
import 'package:lafzi/models/ayat_quran.dart';
import 'package:lafzi/widgets/ayat_card.dart';
import 'package:lafzi/widgets/example_list.dart';

Widget _wrap(Widget child) {
  final theme = AppTheme.light();
  return MaterialApp(
    theme: theme,
    home: Scaffold(body: child),
  );
}

AyatQuran _sampleAyat({String? muqathaat}) {
  return AyatQuran(
    id: 1,
    surahNo: 1,
    surahName: 'Al-Fatihah',
    ayatNo: 1,
    ayatArabic: 'بِسْمِ ٱللَّهِ ٱلرَّحْمَـٰنِ ٱلرَّحِيمِ',
    ayatIndonesian:
        'Dengan menyebut nama Allah Yang Maha Pemurah lagi Maha Penyayang.',
    ayatMuqathaat: muqathaat ?? '',
    mappingPositions: const [],
  );
}

void main() {
  testWidgets('result card shows translation when enabled', (tester) async {
    await tester.pumpWidget(
      _wrap(
        AyatCard(
          ayat: _sampleAyat()..highlightPositions = const [],
          position: 1,
          showTranslation: true,
        ),
      ),
    );

    expect(find.text('Surat Al-Fatihah (1) Ayat 1'), findsOneWidget);
    expect(find.textContaining('Dengan menyebut nama Allah'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
  });

  testWidgets('result card hides translation when disabled', (tester) async {
    await tester.pumpWidget(
      _wrap(AyatCard(ayat: _sampleAyat(), position: 2, showTranslation: false)),
    );

    expect(find.textContaining('Dengan menyebut nama Allah'), findsNothing);
  });

  testWidgets('muqathaat text replaces the Arabic text', (tester) async {
    await tester.pumpWidget(
      _wrap(
        AyatCard(
          ayat: _sampleAyat(muqathaat: 'الٓمٓ'),
          position: 1,
          showTranslation: false,
        ),
      ),
    );

    expect(find.textContaining('الٓمٓ'), findsOneWidget);
  });

  testWidgets('example list rotates every six seconds', (tester) async {
    final tapped = <String>[];
    await tester.pumpWidget(
      _wrap(
        ExampleList(
          queries: const ['one', 'two', 'three', 'four', 'five', 'six'],
          onSelected: tapped.add,
          rotationEnabled: true,
        ),
      ),
    );

    expect(find.text('one'), findsOneWidget);
    expect(find.text('four'), findsNothing);

    await tester.pump(const Duration(seconds: 6));
    await tester.pumpAndSettle();
    expect(find.text('four'), findsOneWidget);
    expect(find.text('one'), findsNothing);

    await tester.tap(find.text('four'));
    expect(tapped, ['four']);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('theme exposes the Lafzi highlight palette', (tester) async {
    late LafziColors colors;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Builder(
          builder: (context) {
            colors = context.lafziColors;
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    expect(colors.highlight, const Color(0x66FFE082));
  });
}
