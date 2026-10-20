import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image/image.dart' as image_lib;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';

import '../core/app_strings.dart';
import '../models/ayat_quran.dart';
import '../widgets/share_image_card.dart';

class ShareService {
  ShareService._();

  static final ShareService instance = ShareService._();

  Future<void> shareText({
    required String suratAyat,
    required String arabic,
    required String translation,
  }) async {
    await SharePlus.instance.share(
      ShareParams(
        title: AppStrings.shareUsing,
        text: '$suratAyat\n\n$arabic\n$translation',
      ),
    );
  }

  Future<void> shareImage({
    required BuildContext context,
    required AyatQuran ayat,
  }) async {
    final media = MediaQuery.of(context);
    final logicalWidth = media.size.width;

    final bytes = await ScreenshotController().captureFromWidget(
      ShareImageCard(ayat: ayat, width: logicalWidth),
      context: context,
      pixelRatio: media.devicePixelRatio,
      delay: const Duration(milliseconds: 80),
    );

    final decoded = image_lib.decodePng(bytes);
    if (decoded == null) {
      throw const FormatException('Unable to decode the rendered image');
    }
    final jpeg = image_lib.encodeJpg(decoded, quality: 90);
    final file = await _writeImage(Uint8List.fromList(jpeg));

    await SharePlus.instance.share(
      ShareParams(
        title: AppStrings.shareUsing,
        files: [XFile(file.path, mimeType: 'image/jpeg')],
      ),
    );
  }

  Future<File> _writeImage(Uint8List bytes) async {
    final cache = await getTemporaryDirectory();
    final directory = Directory(p.join(cache.path, 'shared_images'));
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
    final file = File(
      p.join(
        directory.path,
        'IMG_${DateTime.now().millisecondsSinceEpoch}.jpg',
      ),
    );
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }
}
