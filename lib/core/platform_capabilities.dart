import 'package:flutter/foundation.dart' show kIsWeb;

/// Features that are not available on every Flutter target.
///
/// Keep the rules here instead of scattering `kIsWeb` checks through the UI so
/// the onboarding guide and the help screen stay in sync with the buttons that
/// are actually shown.
abstract final class PlatformCapabilities {
  /// Voice search needs a platform speech recognizer.
  ///
  /// On the web `speech_to_text` relies on the Web Speech API, which only some
  /// browsers provide, often lacks Arabic, and requires HTTPS. Web builds
  /// therefore hide the microphone button, its onboarding step, and the voice
  /// section of the help screen.
  static bool get voiceSearch => !kIsWeb;
}
