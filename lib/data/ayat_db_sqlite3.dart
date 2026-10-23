import 'package:sqlite3/common.dart';

import 'ayat_db.dart';

/// [AyatDb] backed by `package:sqlite3`, used on the web.
///
/// `Row` implements `Map<String, dynamic>`, so converting to the plain map the
/// repository expects is cheap and keeps web rows shape-compatible with
/// `sqflite` rows.
final class Sqlite3AyatDb implements AyatDb {
  Sqlite3AyatDb(this._db);

  final CommonDatabase _db;

  @override
  Future<List<Map<String, Object?>>> select(
    String sql, [
    List<Object?> args = const [],
  ]) async {
    final rows = _db.select(sql, args);
    return [
      for (final row in rows) Map<String, Object?>.from(row),
    ];
  }

  @override
  Future<void> close() async {
    _db.close();
  }
}
