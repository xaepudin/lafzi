import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

/// Copies the bundled 15 MB Quran database into the app's database directory
/// on first launch (or after a database version bump) and opens it read-only.
class DatabaseService {
  DatabaseService._();

  static final DatabaseService instance = DatabaseService._();

  static const assetPath = 'assets/databases/lafzi.sqlite';
  static const databaseName = 'lafzi.sqlite';
  static const assetDatabaseVersion = 3;
  static const _versionKey = 'lafzi_database_asset_version';

  Database? _database;
  Future<Database>? _opening;

  Database get database {
    final db = _database;
    if (db == null) {
      throw StateError('DatabaseService.initialize() has not completed');
    }
    return db;
  }

  Future<void> initialize() async {
    final existing = _database;
    if (existing != null && existing.isOpen) {
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

  Future<Database> _open() async {
    final directory = await getDatabasesPath();
    final dbPath = p.join(directory, databaseName);
    await Directory(directory).create(recursive: true);

    final preferences = await SharedPreferences.getInstance();
    final installedVersion = preferences.getInt(_versionKey);
    final exists = await File(dbPath).exists();

    if (!exists || installedVersion != assetDatabaseVersion) {
      await _removeDatabaseFiles(dbPath);

      final data = await rootBundle.load(assetPath);
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

      await preferences.setInt(_versionKey, assetDatabaseVersion);
    }

    final db = await openDatabase(dbPath, readOnly: true);
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
