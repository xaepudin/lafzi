/// Hands a rendered image to the browser's download mechanism.
///
/// Sharing through `navigator.share` opens the system share sheet (on macOS,
/// that is the AirDrop/Mail sheet); this is the explicit "save" path for users
/// who just want the JPEG file.
library;

export 'image_download_stub.dart'
    if (dart.library.io) 'image_download_io.dart'
    if (dart.library.js_interop) 'image_download_web.dart';
