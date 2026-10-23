import 'package:flutter/services.dart';
import 'package:sqlite3/wasm.dart';

import 'ayat_db.dart';
import 'ayat_db_sqlite3.dart';
import 'database_metadata.dart';

/// Loads the bundled Lafzi database into SQLite compiled to WebAssembly.
///
/// The database is read-only, so it does not need to survive a page reload:
/// it is fetched once (cached by the browser and the Flutter service worker)
/// and copied into an in-memory virtual file system. That avoids the much
/// slower and less reliable path of writing 15 MB into IndexedDB on first
/// launch.
class DatabaseService {
  DatabaseService._();

  static final DatabaseService instance = DatabaseService._();

  static const _dbPath = '/lafzi.sqlite';

  AyatDb? _database;
  Future<AyatDb>? _opening;

  WasmSqlite3? _sqlite;
  InMemoryFileSystem? _fileSystem;

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

  /// The web build rebuilds the in-memory database on every load, so the
  /// splash is shown while the wasm module and the asset are fetched.
  Future<bool> needsInstall() async => _database == null;

  Future<AyatDb> _open() async {
    final sqlite = _sqlite ??= await WasmSqlite3.loadFromUrlString(
      DatabaseMetadata.wasmFile,
    );

    _fileSystem ??= await _mountDatabase(sqlite);

    final db = sqlite.open(_dbPath, mode: OpenMode.readOnly);
    final ayatDb = Sqlite3AyatDb(db);
    _database = ayatDb;
    return ayatDb;
  }

  Future<InMemoryFileSystem> _mountDatabase(WasmSqlite3 sqlite) async {
    final data = await rootBundle.load(DatabaseMetadata.assetPath);
    final bytes = data.buffer.asUint8List(
      data.offsetInBytes,
      data.lengthInBytes,
    );

    final fileSystem = InMemoryFileSystem();
    final file = fileSystem
        .xOpen(
          Sqlite3Filename(_dbPath),
          SqlFlag.SQLITE_OPEN_READWRITE | SqlFlag.SQLITE_OPEN_CREATE,
        )
        .file;
    try {
      file.xWrite(bytes, 0);
    } finally {
      file.xClose();
    }

    sqlite.registerVirtualFileSystem(fileSystem, makeDefault: true);
    return fileSystem;
  }

  Future<void> close() async {
    await _database?.close();
    _database = null;
  }
}
