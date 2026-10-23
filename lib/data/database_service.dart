/// Opens the bundled Lafzi database on the current platform.
///
/// Native platforms copy the asset into the app database directory and open it
/// with `sqflite`; the web build starts SQLite as WebAssembly and loads the
/// asset into an in-memory file system. Both implementations expose the same
/// small [AyatDb] interface.
library;

export 'database_service_stub.dart'
    if (dart.library.io) 'database_service_io.dart'
    if (dart.library.js_interop) 'database_service_web.dart';
