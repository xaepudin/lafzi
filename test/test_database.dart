import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class DatabaseLike {
  DatabaseLike(this.database);

  final Database database;

  Future<void> close() => database.close();
}

Future<DatabaseLike> openTestDatabase() async {
  sqfliteFfiInit();
  final path = p.join(
    Directory.current.path,
    'assets',
    'databases',
    'lafzi.sqlite',
  );
  final db = await databaseFactoryFfi.openDatabase(
    path,
    options: OpenDatabaseOptions(readOnly: true),
  );
  return DatabaseLike(db);
}
