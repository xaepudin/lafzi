import 'package:flutter_test/flutter_test.dart';
import 'package:lafzi/data/ayat_db.dart';
import 'package:lafzi/data/ayat_db_sqlite3.dart';
import 'package:lafzi/data/ayat_repository.dart';
import 'package:lafzi/search/search_engine.dart';
import 'package:sqlite3/sqlite3.dart';

import 'test_database.dart';

/// The web build reaches SQLite through `package:sqlite3` instead of `sqflite`.
/// These tests run that adapter on the host (system SQLite has FTS4) and check
/// that it returns exactly what the native adapter returns.
void main() {
  late AyatDb sqfliteDb;
  late Sqlite3AyatDb sqlite3Db;

  setUpAll(() async {
    sqfliteDb = await openTestDatabase();
    sqlite3Db = Sqlite3AyatDb(
      sqlite3.open(testDatabasePath(), mode: OpenMode.readOnly),
    );
  });

  tearDownAll(() async {
    await sqfliteDb.close();
    await sqlite3Db.close();
  });

  test('ayat rows are identical through both adapters', () async {
    final native = await AyatRepository(sqfliteDb).getAyat(1);
    final web = await AyatRepository(sqlite3Db).getAyat(1);

    expect(web, isNotNull);
    expect(web!.id, native!.id);
    expect(web.surahNo, native.surahNo);
    expect(web.surahName, native.surahName);
    expect(web.ayatNo, native.ayatNo);
    expect(web.ayatArabic, native.ayatArabic);
    expect(web.ayatIndonesian, native.ayatIndonesian);
    expect(web.ayatMuqathaat, native.ayatMuqathaat);
    expect(web.mappingPositions, native.mappingPositions);
  });

  test(
    'Latin and Arabic searches are identical through both adapters',
    () async {
      final nativeEngine = SearchEngine(AyatRepository(sqfliteDb));
      final webEngine = SearchEngine(AyatRepository(sqlite3Db));

      for (final query in const [
        'bismillah',
        'alhamdulillah',
        'arrahmaan',
        'بسم الله',
        'الرحمن',
      ]) {
        for (final isVocal in const [true, false]) {
          final nativeResults = await nativeEngine.search(
            query,
            isVocal: isVocal,
          );
          final webResults = await webEngine.search(query, isVocal: isVocal);

          expect(
            webResults.map((ayat) => ayat.id),
            nativeResults.map((ayat) => ayat.id),
            reason: 'ids for "$query" (vocal: $isVocal)',
          );
          for (var i = 0; i < nativeResults.length; i++) {
            expect(
              webResults[i].score,
              nativeResults[i].score,
              reason: 'score for "$query" result $i',
            );
            expect(
              webResults[i].highlightPositions
                  .map((pos) => '${pos.start}:${pos.end}')
                  .toList(),
              nativeResults[i].highlightPositions
                  .map((pos) => '${pos.start}:${pos.end}')
                  .toList(),
              reason: 'highlights for "$query" result $i',
            );
          }
        }
      }
    },
  );
}
