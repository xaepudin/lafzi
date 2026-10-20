import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/services.dart';
import 'package:speech_to_text/speech_to_text.dart';

/// Returns one Arabic transcription for the home search field.
///
/// Android uses the same system `RecognizerIntent` flow as the original app,
/// because Samsung/Google on-device recognizers often do not expose Arabic in
/// the `SpeechRecognizer` locale list. iOS and macOS use `speech_to_text`.
class SpeechService {
  static const _androidChannel = MethodChannel(
    'org.lafzi.lafzi.flutter/speech',
  );

  final SpeechToText _speech = SpeechToText();

  bool _initialized = false;
  bool _permissionDenied = false;
  bool _unavailable = false;
  bool _listenStarted = false;
  Completer<String?>? _completer;
  String _lastWords = '';
  Timer? _fallbackTimer;

  static final RegExp _speechBidiControls = RegExp(
    r'[\u061C\u200B-\u200F\u202A-\u202E\u2060-\u2069\uFEFF]',
  );
  static final RegExp _speechWhitespace = RegExp(r'\s+');

  /// Removes invisible RTL/LTR marks and normalizes whitespace.
  static String cleanRecognizedText(String value) {
    return value
        .replaceAll(_speechBidiControls, '')
        .replaceAll(_speechWhitespace, ' ')
        .trim();
  }

  bool get isListening => !Platform.isAndroid && _speech.isListening;
  bool get permissionDenied => _permissionDenied;
  bool get unavailable => _unavailable;

  Future<String?> listen({void Function(String partial)? onPartial}) async {
    if (_completer != null) {
      return null;
    }

    _lastWords = '';
    _permissionDenied = false;
    _unavailable = false;
    _listenStarted = false;
    _completer = Completer<String?>();

    if (Platform.isAndroid) {
      return _listenAndroid();
    }
    return _listenPlugin(onPartial);
  }

  /// Launches the system speech activity (the same one the Java app used).
  Future<String?> _listenAndroid() async {
    try {
      final text = await _androidChannel.invokeMethod<String>('recognize', {
        'language': 'ar-AE',
        'prompt': 'Ucapkan lafadz yang ingin dicari',
      });
      final cleaned = cleanRecognizedText(text ?? '');
      return cleaned.isEmpty ? null : cleaned;
    } on PlatformException catch (error) {
      _permissionDenied = error.code == 'permission';
      _unavailable = error.code == 'unavailable';
      return null;
    } on MissingPluginException {
      // Should not happen in the packaged app; fall back to the plugin.
      return _listenPlugin(null);
    } finally {
      _completer = null;
    }
  }

  Future<String?> _listenPlugin(
    void Function(String partial)? onPartial,
  ) async {
    if (!_initialized) {
      try {
        _initialized = await _speech.initialize(
          onError: (_) => _complete(null),
          onStatus: _onStatus,
        );
      } catch (_) {
        _initialized = false;
      }
    }
    if (!_initialized) {
      _permissionDenied = !await _speech.hasPermission;
      _unavailable = !_permissionDenied;
      _completer = null;
      return null;
    }

    final locale = await _preferredLocale();
    // `listen` completes with void; it starts the recognizer asynchronously.
    // Status/result callbacks below drive completion.
    _listenStarted = true;
    try {
      await _speech.listen(
        onResult: (result) {
          _lastWords = cleanRecognizedText(result.recognizedWords);
          if (result.finalResult) {
            _complete(_lastWords.isEmpty ? null : _lastWords);
          } else {
            onPartial?.call(_lastWords);
          }
        },
        listenOptions: SpeechListenOptions(
          localeId: locale,
          partialResults: true,
          listenMode: ListenMode.search,
          cancelOnError: true,
          listenFor: const Duration(seconds: 30),
          pauseFor: const Duration(seconds: 3),
        ),
      );
    } catch (_) {
      _listenStarted = false;
      _permissionDenied = !await _speech.hasPermission;
      if (!_permissionDenied) {
        _unavailable = true;
      }
      _complete(null);
    }

    // Safety net for recognizers that stop without reporting a final result.
    _fallbackTimer?.cancel();
    _fallbackTimer = Timer(const Duration(seconds: 33), () {
      _complete(_lastWords.isEmpty ? null : _lastWords);
    });

    final value = await _completer!.future;
    _fallbackTimer?.cancel();
    _fallbackTimer = null;
    await stop();
    _completer = null;
    return value;
  }

  /// Picks an Arabic locale supported by the platform recognizer.
  Future<String?> _preferredLocale() async {
    try {
      final locales = await _speech.locales();
      final ids = locales.map((locale) => locale.localeId).toList();
      for (final candidate in const ['ar-AE', 'ar-SA', 'ar-001', 'ar']) {
        if (ids.contains(candidate)) {
          return candidate;
        }
      }
      final arabic = ids.where((id) => id.toLowerCase().startsWith('ar'));
      if (arabic.isNotEmpty) {
        return arabic.first;
      }
    } catch (_) {
      // Fall through to the platform default.
    }
    return null;
  }

  void _onStatus(String status) {
    if (!_listenStarted) {
      return;
    }
    if (status == SpeechToText.doneStatus ||
        status == SpeechToText.notListeningStatus) {
      _complete(_lastWords.isEmpty ? null : _lastWords);
    }
  }

  void _complete(String? value) {
    final completer = _completer;
    if (completer != null && !completer.isCompleted) {
      completer.complete(value);
    }
  }

  Future<void> stop() async {
    if (!Platform.isAndroid && _speech.isListening) {
      await _speech.stop();
    }
  }
}
