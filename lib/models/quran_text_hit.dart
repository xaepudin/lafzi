/// A row returned by the Arabic FTS search.
class QuranTextHit {
  QuranTextHit({
    required this.docId,
    required this.text,
    required this.pos,
    required this.fullLength,
    required this.shortLength,
    required this.score,
  });

  final int docId;
  final String text;
  final List<int> pos;
  final int fullLength;
  final int shortLength;
  final int score;
}
