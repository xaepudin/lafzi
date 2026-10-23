import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image/image.dart' as image_lib;
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';

import '../core/app_strings.dart';
import '../models/ayat_quran.dart';
import '../widgets/share_image_card.dart';
import 'share_image_file.dart';

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
    final file = await shareImageFile(
      Uint8List.fromList(jpeg),
      name: 'IMG_${DateTime.now().millisecondsSinceEpoch}.jpg',
    );

    await SharePlus.instance.share(
      ShareParams(title: AppStrings.shareUsing, files: [file]),
    );
  }
}
