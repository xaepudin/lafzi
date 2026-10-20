import 'package:flutter_test/flutter_test.dart';

import 'test_database.dart';

void main() {
  test('bundled database contains the expected Quran and index rows', () async {
    final handle = await openTestDatabase();
    final db = handle.database;

    final ayat = await db.rawQuery('SELECT COUNT(*) AS c FROM ayat_quran');
    expect(ayat.first['c'], 6236);

    final vocal = await db.rawQuery('SELECT COUNT(*) AS c FROM vocal_index');
    expect(vocal.first['c'], 2191);

    final nonVocal = await db.rawQuery(
      'SELECT COUNT(*) AS c FROM nonvocal_index',
    );
    expect(nonVocal.first['c'], 3746);

    final fts = await db.rawQuery('SELECT COUNT(*) AS c FROM quran_text');
    expect(fts.first['c'], 6236);

    await handle.close();
  });
}
