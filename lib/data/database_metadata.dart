/// Shared constants describing the bundled Lafzi database.
///
/// Both the native and the web database services read these values so the
/// asset name and the install version can never drift apart.
abstract final class DatabaseMetadata {
  static const assetPath = 'assets/databases/lafzi.sqlite';
  static const databaseName = 'lafzi.sqlite';
  static const assetDatabaseVersion = 3;
  static const versionKey = 'lafzi_database_asset_version';

  /// SQLite compiled to WebAssembly, served from the web root.
  ///
  /// The stock `sqlite3.wasm` from `sqlite3.dart` is built without FTS3/FTS4,
  /// so this app ships a custom build (see `tool/build_sqlite3_wasm.sh`).
  static const wasmFile = 'sqlite3.wasm';
}
