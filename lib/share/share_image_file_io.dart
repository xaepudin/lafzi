import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Writes the rendered JPEG into the app temporary directory.
Future<XFile> shareImageFile(Uint8List bytes, {required String name}) async {
  final cache = await getTemporaryDirectory();
  final directory = Directory(p.join(cache.path, 'shared_images'));
  if (!await directory.exists()) {
    await directory.create(recursive: true);
  }
  final file = File(p.join(directory.path, name));
  await file.writeAsBytes(bytes, flush: true);
  return XFile(file.path, mimeType: 'image/jpeg');
}
