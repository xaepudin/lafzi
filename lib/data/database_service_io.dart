import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

import 'ayat_db.dart';
import 'ayat_db_sqflite.dart';
import 'database_metadata.dart';

/// Copies the bundled 15 MB Quran database into the app's database directory
/// on first launch (or after a database version bump) and opens it read-only.
class DatabaseService {
  DatabaseService._();

  static final DatabaseService instance = DatabaseService._();

  AyatDb? _database;
  Future<AyatDb>? _opening;

  AyatDb get database {
    final db = _database;
    if (db == null) {
      throw StateError('DatabaseService.initialize() has not completed');
    }
    return db;
  }

  Future<void> initialize() async {
    if (_database != null) {
      return;
    }
    final opening = _opening;
    if (opening != null) {
      await opening;
      return;
    }
    final future = _open();
    _opening = future;
    try {
      await future;
    } finally {
      _opening = null;
    }
  }

  /// Whether the bundled database still has to be copied into the writable
  /// database directory. True on first launch and after an asset version
  /// bump; does not open the database.
  Future<bool> needsInstall() async {
    final dbPath = p.join(
      await getDatabasesPath(),
      DatabaseMetadata.databaseName,
    );
    if (!await File(dbPath).exists()) {
      return true;
    }
    final preferences = await SharedPreferences.getInstance();
    return preferences.getInt(DatabaseMetadata.versionKey) !=
        DatabaseMetadata.assetDatabaseVersion;
  }

  Future<AyatDb> _open() async {
    final directory = await getDatabasesPath();
    final dbPath = p.join(directory, DatabaseMetadata.databaseName);
    await Directory(directory).create(recursive: true);

    if (await needsInstall()) {
      final preferences = await SharedPreferences.getInstance();
      await _removeDatabaseFiles(dbPath);

      final data = await rootBundle.load(DatabaseMetadata.assetPath);
      final bytes = data.buffer.asUint8List(
        data.offsetInBytes,
        data.lengthInBytes,
      );

      final tempFile = File('$dbPath.tmp');
      await tempFile.writeAsBytes(bytes, flush: true);
      if (await File(dbPath).exists()) {
        await File(dbPath).delete();
      }
      await tempFile.rename(dbPath);

      await preferences.setInt(
        DatabaseMetadata.versionKey,
        DatabaseMetadata.assetDatabaseVersion,
      );
    }

    final db = SqfliteAyatDb(await openDatabase(dbPath, readOnly: true));
    _database = db;
    return db;
  }

  Future<void> _removeDatabaseFiles(String dbPath) async {
    for (final suffix in const ['', '-wal', '-shm', '-journal']) {
      final file = File('$dbPath$suffix');
      if (await file.exists()) {
        await file.delete();
      }
    }
  }

  Future<void> close() async {
    await _database?.close();
    _database = null;
  }
}
