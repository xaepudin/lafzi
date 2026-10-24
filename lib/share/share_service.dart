import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image/image.dart' as image_lib;
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';

import '../core/app_strings.dart';
import '../models/ayat_quran.dart';
import '../widgets/share_image_card.dart';
import 'image_download.dart';
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
    final jpeg = await _renderJpeg(context: context, ayat: ayat);
    final file = await shareImageFile(jpeg, name: _imageName());

    await SharePlus.instance.share(
      ShareParams(title: AppStrings.shareUsing, files: [file]),
    );
  }

  /// Downloads the rendered image instead of opening the share sheet.
  ///
  /// Only exposed by the web build, where the system share sheet may not offer
  /// a save option.
  Future<void> saveImage({
    required BuildContext context,
    required AyatQuran ayat,
  }) async {
    final jpeg = await _renderJpeg(context: context, ayat: ayat);
    await downloadImage(jpeg, name: _imageName());
  }

  Future<Uint8List> _renderJpeg({
    required BuildContext context,
    required AyatQuran ayat,
  }) async {
    final media = MediaQuery.of(context);
    final bytes = await ScreenshotController().captureFromWidget(
      ShareImageCard(ayat: ayat, width: media.size.width),
      context: context,
      pixelRatio: media.devicePixelRatio,
      delay: const Duration(milliseconds: 80),
    );

    final decoded = image_lib.decodePng(bytes);
    if (decoded == null) {
      throw const FormatException('Unable to decode the rendered image');
    }
    return Uint8List.fromList(image_lib.encodeJpg(decoded, quality: 90));
  }

  String _imageName() => 'IMG_${DateTime.now().millisecondsSinceEpoch}.jpg';
}
