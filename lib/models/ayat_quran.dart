import 'highlight_position.dart';

/// One row of the bundled `ayat_quran` table.
class AyatQuran {
  AyatQuran({
    required this.id,
    required this.surahNo,
    required this.surahName,
    required this.ayatNo,
    required this.ayatArabic,
    required this.ayatIndonesian,
    required this.ayatMuqathaat,
    required this.mappingPositions,
  });

  final int id;
  final int surahNo;
  final String surahName;
  final int ayatNo;
  final String ayatArabic;
  final String ayatIndonesian;
  final String ayatMuqathaat;

  /// Maps a 1-based character position in the phonetic query text to the
  /// matching character index in [ayatArabic].
  final List<int> mappingPositions;

  List<HighlightPosition> highlightPositions = const [];
  double relevance = 0;
  double score = 0;

  /// The Arabic text to display, preferring the standalone muqathaat form.
  String get displayArabic =>
      ayatMuqathaat.isEmpty ? ayatArabic : ayatMuqathaat;

  @override
  String toString() => 'AyatQuran($id, $surahName:$ayatNo)';
}
