import 'package:flutter_test/flutter_test.dart';
import 'package:lafzi/models/highlight_position.dart';
import 'package:lafzi/search/highlight_util.dart';
import 'package:lafzi/search/search_scoring.dart';

void main() {
  group('longestContiguousSubsequence', () {
    test('keeps the first run when runs have equal length', () {
      expect(SearchScoring.longestContiguousSubsequence([1, 2, 30, 31], 7), [
        1,
        2,
      ]);
    });

    test('sorts the input before scanning', () {
      expect(SearchScoring.longestContiguousSubsequence([5, 1, 2, 3], 7), [
        1,
        2,
        3,
        5,
      ]);
    });

    test('handles a single item and empty input', () {
      expect(SearchScoring.longestContiguousSubsequence([4], 7), [4]);
      expect(SearchScoring.longestContiguousSubsequence([], 7), isEmpty);
    });
  });

  group('reciprocalDiffAverage', () {
    test('averages reciprocal gaps', () {
      expect(
        SearchScoring.reciprocalDiffAverage([1, 2, 4]),
        closeTo(0.75, 1e-9),
      );
    });

    test('single position scores one', () {
      expect(SearchScoring.reciprocalDiffAverage([3]), 1);
    });
  });

  group('longestHighlightLookforward', () {
    List<HighlightPosition> run(List<int> seq) =>
        HighlightUtil.longestHighlightLookforward(seq, 6);

    test('expands a single position by the minimum length', () {
      final result = run([5]);
      expect(result.single.start, 5);
      expect(result.single.end, 11);
    });

    test('splits runs separated by more than the minimum gap', () {
      final result = run([1, 2, 3, 20, 21]);
      expect(result.length, 2);
      expect(result[0].start, 1);
      expect(result[0].end, 3);
      expect(result[1].start, 20);
      expect(result[1].end, 21);
    });

    test('returns no highlight for empty input', () {
      expect(run([]), isEmpty);
    });
  });
}
