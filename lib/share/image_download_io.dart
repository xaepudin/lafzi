import 'dart:io';
import 'dart:typed_data';

import 'package:file_saver/file_saver.dart';

/// Saves the rendered image on mobile and desktop.
///
/// Android and iOS show the system save dialog so the user can choose where the
/// JPEG goes (Downloads, Files, …). macOS writes directly to `~/Downloads`,
/// which requires the downloads read-write sandbox entitlement.
Future<bool> downloadImage(Uint8List bytes, {required String name}) async {
  final baseName = name.replaceFirst(
    RegExp(r'\.jpe?g$', caseSensitive: false),
    '',
  );

  if (Platform.isMacOS) {
    final path = await FileSaver.instance.saveToDownloads(
      name: baseName,
      bytes: bytes,
      fileExtension: 'jpg',
      mimeType: MimeType.jpeg,
    );
    return path != null;
  }

  final path = await FileSaver.instance.saveAs(
    name: baseName,
    bytes: bytes,
    fileExtension: 'jpg',
    mimeType: MimeType.jpeg,
    dialogTitle: 'Simpan gambar',
  );
  // The save dialog returns null when the user cancels.
  return path != null;
}
