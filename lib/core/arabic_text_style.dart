import 'package:flutter/material.dart';

/// Shared styling for Quran text rendered with the bundled MeQuran face.
abstract final class ArabicTextStyle {
  static const fontFamily = 'MeQuran';

  /// Whether [text] contains characters outside ASCII, which the default UI
  /// font cannot draw in the web build: it no longer downloads fallback fonts
  /// from the Google Fonts CDN (see the web build notes in the README), so such
  /// text has to use the bundled Quran face.
  static bool needsQuranFace(String text) =>
      text.codeUnits.any((unit) => unit > 0x7F);

  static TextStyle of(BuildContext context, {double fontSize = 26}) {
    return TextStyle(
      fontFamily: fontFamily,
      fontSize: fontSize,
      height: 1.65,
      color: Theme.of(context).colorScheme.onSurface,
    );
  }
}
