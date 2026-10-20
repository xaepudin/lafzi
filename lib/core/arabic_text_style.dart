import 'package:flutter/material.dart';

/// Shared styling for Quran text rendered with the bundled MeQuran face.
abstract final class ArabicTextStyle {
  static const fontFamily = 'MeQuran';

  static TextStyle of(BuildContext context, {double fontSize = 26}) {
    return TextStyle(
      fontFamily: fontFamily,
      fontSize: fontSize,
      height: 1.65,
      color: Theme.of(context).colorScheme.onSurface,
    );
  }
}
