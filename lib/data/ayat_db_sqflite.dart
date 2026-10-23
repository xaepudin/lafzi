import 'package:sqflite/sqflite.dart';

import 'ayat_db.dart';

/// [AyatDb] backed by the platform SQLite through `sqflite`.
final class SqfliteAyatDb implements AyatDb {
  SqfliteAyatDb(this._db);

  final Database _db;

  @override
  Future<List<Map<String, Object?>>> select(
    String sql, [
    List<Object?> args = const [],
  ]) {
    return _db.rawQuery(sql, args);
  }

  @override
  Future<void> close() => _db.close();
}
