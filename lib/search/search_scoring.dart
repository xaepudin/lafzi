/// Port of the scoring helpers in the Android `SearchUtil` class.
abstract final class SearchScoring {
  /// Returns the longest run of positions whose neighbouring distance is at
  /// most [maxGap]. The input is sorted first, matching `Collections.sort`.
  static List<int> longestContiguousSubsequence(
    List<int> sequence,
    int maxGap,
  ) {
    if (sequence.isEmpty) {
      return const [];
    }
    final sorted = [...sequence]..sort();
    final size = sorted.length;
    var start = 0;
    var length = 0;
    var maxStart = 0;
    var maxLength = 0;

    for (var i = 0; i < size - 1; i++) {
      if (sorted[i + 1] - sorted[i] > maxGap) {
        length = 0;
        start = i + 1;
      } else {
        length++;
        if (length > maxLength) {
          maxLength = length;
          maxStart = start;
        }
      }
    }

    maxLength++;
    return sorted.sublist(maxStart, maxStart + maxLength);
  }

  static double reciprocalDiffAverage(List<int> lis) {
    final length = lis.length;
    if (length == 1) {
      return 1;
    }
    var total = 0.0;
    for (var i = 0; i < length - 1; i++) {
      total += 1.0 / (lis[i + 1] - lis[i]);
    }
    return total / (length - 1);
  }
}
