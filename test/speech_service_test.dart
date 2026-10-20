import 'package:flutter_test/flutter_test.dart';
import 'package:lafzi/search/speech_service.dart';

void main() {
  test('removes invisible bidi marks from recognized Arabic', () {
    expect(
      SpeechService.cleanRecognizedText('\u200f بسم الله الرحمن الرحيم '),
      'بسم الله الرحمن الرحيم',
    );
  });

  test('removes control characters that iOS prepends to transcripts', () {
    expect(SpeechService.cleanRecognizedText(' \u000Fبسم الله'), 'بسم الله');
    expect(
      SpeechService.cleanRecognizedText('\u000Eبسم الله\u000F'),
      'بسم الله',
    );
  });

  test('keeps normal Arabic and Latin text unchanged', () {
    expect(SpeechService.cleanRecognizedText('بسم الله'), 'بسم الله');
    expect(SpeechService.cleanRecognizedText('bismillah'), 'bismillah');
  });
}
