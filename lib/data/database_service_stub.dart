import 'ayat_db.dart';

/// Fallback used when neither `dart:io` nor `dart:js_interop` is available.
///
/// This should never be selected by a Flutter target; it only keeps the
/// conditional export exhaustive for the analyzer.
class DatabaseService {
  DatabaseService._();

  static final DatabaseService instance = DatabaseService._();

  AyatDb get database => throw UnsupportedError(
    'The database is not available on this platform',
  );

  Future<void> initialize() async {
    throw UnsupportedError('The database is not available on this platform');
  }

  Future<bool> needsInstall() async => true;

  Future<void> close() async {}
}
