/// A half-open-by-one highlight range: [start] and [end] are inclusive
/// UTF-16 indexes, matching the Android implementation.
class HighlightPosition {
  HighlightPosition({required this.start, required this.end});

  final int start;
  final int end;

  @override
  String toString() => 'HighlightPosition($start, $end)';
}
