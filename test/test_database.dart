import 'dart:io';

import 'package:lafzi/data/ayat_db.dart';
import 'package:lafzi/data/ayat_db_sqflite.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

String testDatabasePath() =>
    p.join(Directory.current.path, 'assets', 'databases', 'lafzi.sqlite');

Future<AyatDb> openTestDatabase() async {
  sqfliteFfiInit();
  final db = await databaseFactoryFfi.openDatabase(
    testDatabasePath(),
    options: OpenDatabaseOptions(readOnly: true),
  );
  return SqfliteAyatDb(db);
}
