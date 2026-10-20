import '../models/ayat_quran.dart';
import '../models/found_document.dart';
import '../models/highlight_position.dart';

/// Port of `HighlightUtil` from the Android app.
abstract final class HighlightUtil {
  /// Locates the highlight ranges inside [ayat] and applies the small
  /// word-boundary score bonus used for final ordering.
  static List<HighlightPosition> applyToDocument(
    FoundDocument document,
    AyatQuran ayat,
  ) {
    final sequence = <int>{};
    for (final pos in document.lis) {
      sequence
        ..add(pos)
        ..add(pos + 1)
        ..add(pos + 2);
    }

    final realPositions = <int>[];
    for (final pos in sequence) {
      final index = pos - 1;
      if (index < 0 || index >= ayat.mappingPositions.length) {
        continue;
      }
      realPositions.add(ayat.mappingPositions[index]);
    }

    final highlights = longestHighlightLookforward(realPositions, 6);

    // Java's `char[]` indexes map to Dart's UTF-16 code units, so the same
    // boundary arithmetic applies to Arabic text.
    final textLength = ayat.ayatArabic.length;
    if (highlights.isNotEmpty && textLength > 0) {
      var endPosition = highlights.last.end;
      if (endPosition > textLength - 3) {
        endPosition = textLength - 3;
      }
      if (endPosition < 0) {
        endPosition = 0;
      }
      bool isSpace(int index) {
        if (index < 0 || index >= textLength) {
          return false;
        }
        return ayat.ayatArabic.codeUnitAt(index) == 0x20;
      }

      bool edgeAtLeast(int offset) => textLength - 1 <= endPosition + offset;

      if (isSpace(endPosition + 1) || edgeAtLeast(1)) {
        document.score += 0.001;
      } else if (edgeAtLeast(2) || isSpace(endPosition + 2)) {
        document.score += 0.001;
      } else if (edgeAtLeast(3) || isSpace(endPosition + 3)) {
        document.score += 0.001;
      }
    }

    return highlights;
  }

  /// Port of `longestHighlightLookforward`.
  static List<HighlightPosition> longestHighlightLookforward(
    List<int> highlightSequences,
    int minLength,
  ) {
    final length = highlightSequences.length;
    if (length == 0) {
      return const [];
    }
    if (length == 1) {
      return [
        HighlightPosition(
          start: highlightSequences[0],
          end: highlightSequences[0] + minLength,
        ),
      ];
    }

    final sorted = [...highlightSequences]..sort();
    final results = <HighlightPosition>[];
    var j = 1;

    for (var i = 0; i < length; i++) {
      while (sorted.length - 1 >= j &&
          sorted[j] - sorted[j - 1] <= minLength + 1 &&
          j < length) {
        j++;
      }

      results.add(HighlightPosition(start: sorted[i], end: sorted[j - 1]));
      i = j - 1;
      j++;
    }

    return results;
  }
}
