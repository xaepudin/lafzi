import 'package:flutter_test/flutter_test.dart';
import 'package:lafzi/data/ayat_db.dart';
import 'package:lafzi/data/ayat_repository.dart';
import 'package:lafzi/search/search_engine.dart';

import 'test_database.dart';

void main() {
  late AyatDb db;
  late AyatRepository repository;
  late SearchEngine engine;

  setUpAll(() async {
    db = await openTestDatabase();
    repository = AyatRepository(db);
    engine = SearchEngine(repository);
  });

  tearDownAll(() async {
    await db.close();
  });

  test('Latin vocal search finds bismillah in Quran order', () async {
    final results = await engine.search('bismillah', isVocal: true);
    expect(results.length, 3);
    expect(results.map((a) => a.id), [1, 1514, 3189]);
    expect(results.first.ayatArabic, contains('بِسْمِ'));
    expect(results.first.highlightPositions, isNotEmpty);
  });

  test('non-vocal search is broader', () async {
    final vocal = await engine.search('bismillah', isVocal: true);
    final nonVocal = await engine.search('bismillah', isVocal: false);
    expect(nonVocal.length, greaterThan(vocal.length));
    expect(nonVocal.first.id, 1);
  });

  test('scores are ordered and relevance is capped', () async {
    final results = await engine.search('alhamdulillah', isVocal: true);
    expect(results, isNotEmpty);
    for (var i = 1; i < results.length; i++) {
      expect(results[i - 1].score, greaterThanOrEqualTo(results[i].score));
    }
    expect(results.first.relevance, lessThanOrEqualTo(100));
  });

  test('relevance matches the original web search percentages', () async {
    final results = await engine.search('allahu samad', isVocal: true);
    expect(results.map((a) => a.id), [6223, 2900, 289]);
    expect(results.map((a) => a.relevance), [100, 79, 47]);
  });

  test('unknown Latin input returns no results', () async {
    expect(await engine.search('zzzzzzz', isVocal: true), isEmpty);
  });

  test('Arabic FTS search finds bismillah and highlights it', () async {
    final results = await engine.search('بسم الله', isVocal: true);
    expect(results.map((a) => a.id), [1, 1514, 3189]);
    expect(results.first.highlightPositions.first.start, 0);
    expect(results.first.highlightPositions.first.end, 11);
  });

  test('Arabic input query is normalized and reversed', () {
    expect(AyatRepository.normalizeAndReverseArabic('بسم الله'), 'هللا* مسب*');
  });

  test('short Arabic tokens are ignored like the Android version', () {
    expect(AyatRepository.normalizeAndReverseArabic('و بسم'), 'مسب*');
  });

  test('Arabic voice text with RTL marks still finds results', () async {
    final results = await engine.search('\u200fبسم الله', isVocal: true);
    expect(results.map((a) => a.id), [1, 1514, 3189]);
  });
}
