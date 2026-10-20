import 'package:flutter_test/flutter_test.dart';
import 'package:lafzi/search/query_normalizer.dart';

void main() {
  group('vocal normalization', () {
    test('matches the Android unit-test vectors', () {
      expect(QueryNormalizer.normalize('bismillah', isVocal: true), 'BISMILAH');
      expect(QueryNormalizer.normalize('zzzzzzz', isVocal: true), 'Z');
      expect(
        QueryNormalizer.normalize('Adzaabis saiir', isVocal: true),
        'XAZABISAYR',
      );
      expect(QueryNormalizer.normalize("Fir'aun", isVocal: true), 'FIRXAWN');
    });

    test('handles case, punctuation and repeated letters', () {
      expect(
        QueryNormalizer.normalize('  MUNAAFIQUN  ', isVocal: true),
        'MUNAFIKUN',
      );
      expect(
        QueryNormalizer.normalize('hello-world', isVocal: true),
        'HILAWARLD',
      );
    });
  });

  group('non-vocal normalization', () {
    test('matches the Android unit-test vectors', () {
      expect(QueryNormalizer.normalize('bismillah', isVocal: false), 'BSMLH');
      expect(QueryNormalizer.normalize('MuNafiquun', isVocal: false), 'MNFKN');
      expect(QueryNormalizer.normalize('wallahi', isVocal: false), 'WLH');
    });
  });
}
