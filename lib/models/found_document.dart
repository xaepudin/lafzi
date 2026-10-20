import 'ayat_quran.dart';
import 'highlight_position.dart';

/// Intermediate scoring record produced by the Latin search engine.
class FoundDocument {
  int ayatQuranId = 0;
  int matchedTrigramsCount = 0;
  int matchedTermsOrderScore = 0;
  int matchedTermsCountScore = 0;
  double matchedTermsContiguityScore = 0;
  double score = 0;
  Map<String, List<int>> matchedTerms = <String, List<int>>{};
  List<int> lis = const [];
  List<HighlightPosition> highlightPositions = const [];
  AyatQuran? ayatQuran;
}
