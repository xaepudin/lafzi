import 'package:flutter_test/flutter_test.dart';
import 'package:lafzi/search/trigram_extractor.dart';

void main() {
  test('short text has no trigrams except an exact trigram', () {
    expect(TrigramExtractor.extract('AB'), isEmpty);
    final exact = TrigramExtractor.extract('BIS');
    expect(exact.keys, ['BIS']);
    expect(exact['BIS']!.frequency, 1);
    expect(exact['BIS']!.positions, [1]);
  });

  test('extracts sliding trigrams with frequency and positions', () {
    final result = TrigramExtractor.extract('BISMI');
    expect(result.keys, ['BIS', 'ISM', 'SMI']);
    expect(result['BIS']!.frequency, 1);
    expect(TrigramExtractor.extract('AAAA')['AAA']!.frequency, 2);
    expect(TrigramExtractor.extract('AAAA')['AAA']!.positions, [0, 1]);
  });
}
