import 'dart:async';
import 'dart:js_interop';

import 'package:flutter/foundation.dart';
import 'package:sqlite3/wasm.dart';
import 'package:web/web.dart' as web;

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

  final ValueNotifier<double?> _downloadProgress = ValueNotifier<double?>(null);

  /// Fraction of the bundled database downloaded, or null while the wasm
  /// module is loading or the total size is unknown.
  ValueListenable<double?> get downloadProgress => _downloadProgress;

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
    _downloadProgress.value = 0;
    final bytes = await _downloadDatabase();
    _downloadProgress.value = 1;

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

  /// Fetches the database as a byte array while reporting progress.
  ///
  /// `rootBundle.load` exposes no progress, so the asset is requested directly
  /// with XHR. The URL is the same one Flutter uses for the asset, which means
  /// the service worker can still serve it from its cache.
  Future<Uint8List> _downloadDatabase() {
    final completer = Completer<Uint8List>();
    final url = Uri.base
        .resolve('assets/${DatabaseMetadata.assetPath}')
        .toString();
    final xhr = web.XMLHttpRequest()
      ..open('GET', url)
      ..responseType = 'arraybuffer';

    xhr.onprogress = ((web.ProgressEvent event) {
      if (event.lengthComputable && event.total > 0) {
        _downloadProgress.value = (event.loaded / event.total).clamp(0.0, 1.0);
      }
    }).toJS;

    xhr.onerror = ((web.Event event) {
      if (!completer.isCompleted) {
        completer.completeError(
          StateError('Unable to download the Lafzi database'),
        );
      }
    }).toJS;

    xhr.onload = ((web.Event event) {
      if (completer.isCompleted) {
        return;
      }
      if (xhr.status != 200) {
        completer.completeError(
          StateError('Database download failed (HTTP ${xhr.status})'),
        );
        return;
      }
      final response = xhr.response;
      if (response == null || !response.isA<JSArrayBuffer>()) {
        completer.completeError(
          StateError('Database download returned an unexpected response'),
        );
        return;
      }
      completer.complete((response as JSArrayBuffer).toDart.asUint8List());
    }).toJS;

    xhr.send();
    return completer.future;
  }

  Future<void> close() async {
    await _database?.close();
    _database = null;
  }
}
