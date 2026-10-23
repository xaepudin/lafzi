/// Creates the image file handed to the system share sheet.
///
/// Native platforms write a temporary file; the web keeps the bytes in memory
/// because browsers have no writable temporary directory.
library;

export 'share_image_file_stub.dart'
    if (dart.library.io) 'share_image_file_io.dart'
    if (dart.library.js_interop) 'share_image_file_web.dart';
