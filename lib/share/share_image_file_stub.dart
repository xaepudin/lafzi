import 'dart:typed_data';

import 'package:share_plus/share_plus.dart';

/// Fallback used when neither `dart:io` nor `dart:js_interop` is available.
Future<XFile> shareImageFile(Uint8List bytes, {required String name}) async {
  throw UnsupportedError('Sharing images is not supported on this platform');
}
