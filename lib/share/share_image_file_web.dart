import 'dart:typed_data';

import 'package:share_plus/share_plus.dart';

/// Keeps the JPEG in memory; the browser share sheet (or download fallback)
/// reads it from the [XFile] data.
Future<XFile> shareImageFile(Uint8List bytes, {required String name}) async {
  return XFile.fromData(bytes, mimeType: 'image/jpeg', name: name);
}
