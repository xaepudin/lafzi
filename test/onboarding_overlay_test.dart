import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lafzi/core/app_strings.dart';
import 'package:lafzi/widgets/onboarding_overlay.dart';

Widget _host({required Set<OnboardingAnchor> visibleAnchors}) {
  final searchKey = GlobalKey();
  final voiceKey = GlobalKey();
  final examplesKey = GlobalKey();

  final anchors = <OnboardingAnchor, GlobalKey>{
    for (final anchor in visibleAnchors)
      anchor: switch (anchor) {
        OnboardingAnchor.search => searchKey,
        OnboardingAnchor.voice => voiceKey,
        OnboardingAnchor.examples => examplesKey,
      },
  };

  return MaterialApp(
    // The test font (Ahem) is wider than the real font; the card is capped at
    // 300 px, so scale text down slightly to avoid a test-only overflow.
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context)
          .copyWith(textScaler: const TextScaler.linear(0.9)),
      child: child!,
    ),
    home: Scaffold(
      body: Stack(
        children: [
          Positioned(
            left: 20,
            top: 80,
            child: SizedBox(key: searchKey, width: 320, height: 56),
          ),
          Positioned(
            left: 20,
            top: 160,
            child: SizedBox(key: voiceKey, width: 48, height: 48),
          ),
          Positioned(
            left: 20,
            top: 240,
            child: SizedBox(key: examplesKey, width: 320, height: 180),
          ),
          Positioned.fill(
            child: OnboardingOverlay(
              anchors: anchors,
              onFinished: () {},
              onExampleRow: (_) {},
            ),
          ),
        ],
      ),
    ),
  );
}

Future<void> _settleOverlay(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

void main() {
  testWidgets('onboarding skips the voice step when its anchor is absent', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        visibleAnchors: const {
          OnboardingAnchor.search,
          OnboardingAnchor.examples,
        },
      ),
    );
    await _settleOverlay(tester);

    expect(find.text(AppStrings.onboardingSearchTitle), findsOneWidget);
    expect(find.text(AppStrings.onboardingVoiceTitle), findsNothing);
    expect(find.text(AppStrings.onboardingStep(1, 2)), findsOneWidget);

    await tester.tap(find.text(AppStrings.onboardingNext));
    await _settleOverlay(tester);

    expect(find.text(AppStrings.onboardingExampleTitle), findsOneWidget);
    expect(find.text(AppStrings.onboardingStep(2, 2)), findsOneWidget);
    expect(find.text(AppStrings.onboardingDone), findsOneWidget);
  });

  testWidgets('onboarding keeps the voice step when the anchor exists', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        visibleAnchors: const {
          OnboardingAnchor.search,
          OnboardingAnchor.voice,
          OnboardingAnchor.examples,
        },
      ),
    );
    await _settleOverlay(tester);

    expect(find.text(AppStrings.onboardingStep(1, 3)), findsOneWidget);

    await tester.tap(find.text(AppStrings.onboardingNext));
    await _settleOverlay(tester);

    expect(find.text(AppStrings.onboardingVoiceTitle), findsOneWidget);
    expect(find.text(AppStrings.onboardingStep(2, 3)), findsOneWidget);
  });
}
