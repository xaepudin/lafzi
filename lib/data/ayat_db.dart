/// The small read-only SQL surface the app needs.
///
/// Native builds use `sqflite`; the web build uses `package:sqlite3` over
/// WebAssembly. Keeping the repository on this interface means the SQL and the
/// result parsing are shared by every platform.
abstract interface class AyatDb {
  /// Runs a read-only query and returns the rows as plain maps.
  Future<List<Map<String, Object?>>> select(
    String sql, [
    List<Object?> args = const [],
  ]);

  Future<void> close();
}
