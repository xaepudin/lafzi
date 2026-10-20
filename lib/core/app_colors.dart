import 'package:flutter/material.dart';

/// Material 3 tokens copied from the Android app's light theme.
const lightScheme = ColorScheme(
  brightness: Brightness.light,
  primary: Color(0xFF005500),
  onPrimary: Color(0xFFFFFFFF),
  primaryContainer: Color(0xFFBFF0B8),
  onPrimaryContainer: Color(0xFF002106),
  secondary: Color(0xFF4F6352),
  onSecondary: Color(0xFFFFFFFF),
  secondaryContainer: Color(0xFFD2E8D3),
  onSecondaryContainer: Color(0xFF0D1F12),
  tertiary: Color(0xFF3D6373),
  onTertiary: Color(0xFFFFFFFF),
  tertiaryContainer: Color(0xFFC1E9FC),
  onTertiaryContainer: Color(0xFF001F29),
  error: Color(0xFFBA1A1A),
  onError: Color(0xFFFFFFFF),
  errorContainer: Color(0xFFFFDAD6),
  onErrorContainer: Color(0xFF410002),
  surface: Color(0xFFF7FBF3),
  onSurface: Color(0xFF191D17),
  surfaceDim: Color(0xFFDEE5D8),
  surfaceBright: Color(0xFFF7FBF3),
  surfaceContainerLowest: Color(0xFFF7FBF3),
  surfaceContainerLow: Color(0xFFF7FBF3),
  surfaceContainer: Color(0xFFDEE5D8),
  surfaceContainerHigh: Color(0xFFDEE5D8),
  surfaceContainerHighest: Color(0xFFDEE5D8),
  onSurfaceVariant: Color(0xFF42493E),
  outline: Color(0xFF72796E),
  outlineVariant: Color(0xFFC2C9BC),
  inverseSurface: Color(0xFF2E322B),
  onInverseSurface: Color(0xFFEFF2E7),
  inversePrimary: Color(0xFF84DB7F),
  shadow: Color(0xFF000000),
  scrim: Color(0xFF000000),
  surfaceTint: Color(0xFF005500),
);

/// Material 3 tokens copied from the Android app's dark theme.
const darkScheme = ColorScheme(
  brightness: Brightness.dark,
  primary: Color(0xFF84DB7F),
  onPrimary: Color(0xFF003900),
  primaryContainer: Color(0xFF00530A),
  onPrimaryContainer: Color(0xFFA0F59A),
  secondary: Color(0xFFB9CCB3),
  onSecondary: Color(0xFF243422),
  secondaryContainer: Color(0xFF3A4B37),
  onSecondaryContainer: Color(0xFFD5E8CF),
  tertiary: Color(0xFFA5CDDE),
  onTertiary: Color(0xFF0B3442),
  tertiaryContainer: Color(0xFF264A59),
  onTertiaryContainer: Color(0xFFC1E9FC),
  error: Color(0xFFFFB4AB),
  onError: Color(0xFF690005),
  errorContainer: Color(0xFF93000A),
  onErrorContainer: Color(0xFFFFDAD6),
  surface: Color(0xFF11140F),
  onSurface: Color(0xFFE1E4DB),
  surfaceDim: Color(0xFF11140F),
  surfaceBright: Color(0xFF373A34),
  surfaceContainerLowest: Color(0xFF0C0F0A),
  surfaceContainerLow: Color(0xFF191D17),
  surfaceContainer: Color(0xFF1D211B),
  surfaceContainerHigh: Color(0xFF282C25),
  surfaceContainerHighest: Color(0xFF33362F),
  onSurfaceVariant: Color(0xFFC2C9BC),
  outline: Color(0xFF8C9387),
  outlineVariant: Color(0xFF42493E),
  inverseSurface: Color(0xFFE1E4DB),
  onInverseSurface: Color(0xFF2E322B),
  inversePrimary: Color(0xFF005500),
  shadow: Color(0xFF000000),
  scrim: Color(0xFF000000),
  surfaceTint: Color(0xFF84DB7F),
);

/// Extra colors that are not part of [ColorScheme].
@immutable
class LafziColors extends ThemeExtension<LafziColors> {
  const LafziColors({
    required this.searchBackground,
    required this.highlight,
    required this.splashBackground,
  });

  final Color searchBackground;
  final Color highlight;
  final Color splashBackground;

  /// Matches the background baked into `app_icon.png`, so the splash icon
  /// blends into the splash background on every platform.
  static const splashGreen = Color(0xFF005500);

  static const light = LafziColors(
    searchBackground: Color(0xFFEBF2E6),
    highlight: Color(0x66FFE082),
    splashBackground: splashGreen,
  );

  static const dark = LafziColors(
    searchBackground: Color(0xFF1B211A),
    highlight: Color(0x667A6A00),
    splashBackground: splashGreen,
  );

  @override
  LafziColors copyWith({
    Color? searchBackground,
    Color? highlight,
    Color? splashBackground,
  }) {
    return LafziColors(
      searchBackground: searchBackground ?? this.searchBackground,
      highlight: highlight ?? this.highlight,
      splashBackground: splashBackground ?? this.splashBackground,
    );
  }

  @override
  LafziColors lerp(covariant ThemeExtension<LafziColors>? other, double t) {
    if (other is! LafziColors) {
      return this;
    }
    return LafziColors(
      searchBackground: Color.lerp(
        searchBackground,
        other.searchBackground,
        t,
      )!,
      highlight: Color.lerp(highlight, other.highlight, t)!,
      splashBackground: Color.lerp(
        splashBackground,
        other.splashBackground,
        t,
      )!,
    );
  }
}

extension LafziColorsContext on BuildContext {
  LafziColors get lafziColors => Theme.of(this).extension<LafziColors>()!;
}
