import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_to_text.dart';

/// Why a speech session produced no text.
enum SpeechFailure {
  /// No failure recorded (for example the user stopped after speaking).
  none,

  /// Microphone or speech-recognition permission was refused.
  permission,

  /// The platform has no usable recognizer or language support.
  unavailable,

  /// The recognizer started but the microphone/engine failed.
  audio,

  /// The recognizer ran but heard nothing usable.
  noSpeech,
}

/// Returns one Arabic transcription for the home search field.
///
/// Android uses the same system `RecognizerIntent` flow as the original app,
/// because Samsung/Google on-device recognizers often do not expose Arabic in
/// the `SpeechRecognizer` locale list. iOS and macOS use `speech_to_text`.
class SpeechService {
  static const _androidChannel = MethodChannel(
    'org.lafzi.lafzi.flutter/speech',
  );

  // Platform calls must not leave the UI stuck forever: a permission dialog
  // dismissed while the app is in the background never answers its caller.
  static const Duration _initializeTimeout = Duration(seconds: 15);
  static const Duration _startTimeout = Duration(seconds: 10);
  static const Duration _stopTimeout = Duration(seconds: 3);
  static const Duration _sessionTimeout = Duration(seconds: 30);

  // The iOS/macOS plugin reports `done` *before* it reports the error that
  // caused it, so give the error a moment to arrive before deciding.
  static const Duration _finalResultGrace = Duration(milliseconds: 500);

  final SpeechToText _speech = SpeechToText();

  bool _initialized = false;
  bool _listenStarted = false;
  SpeechFailure _failure = SpeechFailure.none;
  String? _errorDetail;
  Completer<String?>? _completer;
  String _lastWords = '';
  Timer? _sessionTimer;
  Timer? _graceTimer;

  static final RegExp _speechBidiControls = RegExp(
    r'[\u061C\u200B-\u200F\u202A-\u202E\u2060-\u2069\uFEFF]',
  );
  // SFSpeechRecognizer prefixes some final transcripts with C0 control
  // characters: "بسم الله" can arrive as "\u000fبسم الله".
  static final RegExp _speechControlCharacters = RegExp(
    r'[\u0000-\u001F\u007F-\u009F]',
  );
  static final RegExp _speechWhitespace = RegExp(r'\s+');

  /// Removes invisible marks/control characters and normalizes whitespace.
  static String cleanRecognizedText(String value) {
    return value
        .replaceAll(_speechControlCharacters, '')
        .replaceAll(_speechBidiControls, '')
        .replaceAll(_speechWhitespace, ' ')
        .trim();
  }

  bool get isListening => !Platform.isAndroid && _speech.isListening;

  /// Failure category of the most recent [listen] call.
  SpeechFailure get failure => _failure;

  /// Raw platform error, kept for diagnostics and logs.
  String? get errorDetail => _errorDetail;

  bool get permissionDenied => _failure == SpeechFailure.permission;
  bool get unavailable => _failure == SpeechFailure.unavailable;

  Future<String?> listen({void Function(String partial)? onPartial}) async {
    if (_completer != null) {
      return null;
    }

    _lastWords = '';
    _failure = SpeechFailure.none;
    _errorDetail = null;
    _listenStarted = false;
    final completer = _completer = Completer<String?>();

    try {
      if (Platform.isAndroid) {
        return await _listenAndroid(completer);
      }
      return await _listenPlugin(completer, onPartial);
    } finally {
      _sessionTimer?.cancel();
      _sessionTimer = null;
      _graceTimer?.cancel();
      _graceTimer = null;
      _completer = null;
    }
  }

  /// Launches the system speech activity (the same one the Java app used).
  Future<String?> _listenAndroid(Completer<String?> completer) async {
    try {
      final text = await _androidChannel.invokeMethod<String>('recognize', {
        'language': 'ar-AE',
        'prompt': 'Ucapkan lafadz yang ingin dicari',
      });
      final cleaned = cleanRecognizedText(text ?? '');
      return cleaned.isEmpty ? null : cleaned;
    } on PlatformException catch (error) {
      _failure = switch (error.code) {
        'permission' => SpeechFailure.permission,
        'unavailable' => SpeechFailure.unavailable,
        _ => SpeechFailure.unavailable,
      };
      _errorDetail = '${error.code}: ${error.message}';
      return null;
    } on MissingPluginException {
      // Should not happen in the packaged app; fall back to the plugin.
      return _listenPlugin(completer, null);
    }
  }

  Future<String?> _listenPlugin(
    Completer<String?> completer,
    void Function(String partial)? onPartial,
  ) async {
    if (!_initialized) {
      try {
        _initialized = await _speech
            .initialize(onError: _onError, onStatus: _onStatus)
            .timeout(_initializeTimeout);
      } on TimeoutException {
        _errorDetail = 'initialize timed out';
        _initialized = false;
      } catch (error) {
        _errorDetail = '$error';
        _initialized = false;
      }
      debugPrint(
        'SpeechService.initialize ok=$_initialized '
        'detail=$_errorDetail',
      );
    }

    if (!_initialized) {
      _failure = await _hasPermission()
          ? SpeechFailure.unavailable
          : SpeechFailure.permission;
      _errorDetail ??= _speech.lastError?.errorMsg;
      return null;
    }

    final locale = await _preferredLocale();
    _listenStarted = true;

    _sessionTimer = Timer(_sessionTimeout, () {
      if (_lastWords.isEmpty && _failure == SpeechFailure.none) {
        _failure = SpeechFailure.noSpeech;
      }
      _completeSession();
      unawaited(_stopPlatform());
    });

    try {
      // `listen` completes with void; it starts the recognizer asynchronously.
      // Status/result callbacks below drive completion.
      await _speech
          .listen(
            onResult: (result) {
              _lastWords = cleanRecognizedText(result.recognizedWords);
              if (result.finalResult) {
                if (_lastWords.isEmpty) {
                  _fail(SpeechFailure.noSpeech);
                } else {
                  _completeSession();
                }
              } else {
                onPartial?.call(_lastWords);
              }
            },
            listenOptions: SpeechListenOptions(
              localeId: locale,
              // iOS defaults to the audio session's current rate. That rate is
              // 0 until the session activates on some simulator/route setups,
              // which makes the plugin's AVAudioEngine setup throw and the
              // session fail before it ever reports `listening`.
              sampleRate: Platform.isIOS ? 44100 : 0,
              partialResults: true,
              listenMode: ListenMode.search,
              cancelOnError: true,
              listenFor: const Duration(seconds: 30),
              pauseFor: const Duration(seconds: 3),
            ),
          )
          .timeout(_startTimeout);
    } on TimeoutException {
      _fail(SpeechFailure.audio, 'listen call timed out');
      await _stopPlatform();
    } catch (error) {
      final failure = _failureFor('$error');
      _fail(
        failure == SpeechFailure.none ? SpeechFailure.audio : failure,
        '$error',
      );
      await _stopPlatform();
    }

    final value = await completer.future;
    await _stopPlatform();
    return value;
  }

  /// Picks an Arabic locale supported by the platform recognizer.
  Future<String?> _preferredLocale() async {
    try {
      final locales = await _speech.locales();
      final ids = locales.map((locale) => locale.localeId).toList();
      for (final candidate in const [
        'ar-AE',
        'ar-SA',
        'ar-EG',
        'ar-001',
        'ar',
      ]) {
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

  Future<bool> _hasPermission() async {
    try {
      // The plugin can be left waiting behind a permission alert too.
      return await _speech.hasPermission.timeout(
        const Duration(seconds: 3),
        onTimeout: () => true,
      );
    } on MissingPluginException {
      _errorDetail ??= 'speech plugin is not registered';
      return true;
    } catch (_) {
      return true;
    }
  }

  void _onError(SpeechRecognitionError error) {
    debugPrint(
      'SpeechService.error ${error.errorMsg} permanent=${error.permanent}',
    );
    _errorDetail = error.errorMsg;
    final mapped = _failureFor(error.errorMsg);
    final failure = mapped == SpeechFailure.none && error.permanent
        ? SpeechFailure.unavailable
        : mapped;
    if (failure != SpeechFailure.none) {
      _failure = failure;
    }
    if (error.permanent) {
      _completeSession();
    }
  }

  void _onStatus(String status) {
    if (!_listenStarted) {
      return;
    }
    if (status == SpeechToText.doneStatus ||
        status == SpeechToText.notListeningStatus) {
      if (_lastWords.isNotEmpty) {
        _completeSession();
        return;
      }
      // Wait briefly for a pending final result or the matching error.
      _graceTimer ??= Timer(_finalResultGrace, () {
        if (_failure == SpeechFailure.none) {
          _failure = SpeechFailure.noSpeech;
        }
        _completeSession();
      });
    }
  }

  static SpeechFailure _failureFor(String message) {
    final normalized = message.toLowerCase();
    if (normalized.contains('permission') ||
        normalized.contains('not_authorized') ||
        normalized.contains('denied')) {
      return SpeechFailure.permission;
    }
    if (normalized.contains('no_match') ||
        normalized.contains('no speech') ||
        normalized.contains('no speech detected')) {
      return SpeechFailure.noSpeech;
    }
    if (normalized.contains('network') ||
        normalized.contains('server') ||
        normalized.contains('unavailable')) {
      return SpeechFailure.unavailable;
    }
    if (normalized.contains('audio') ||
        normalized.contains('listen_failed') ||
        normalized.contains('retry') ||
        normalized.contains('recognizer') ||
        normalized.contains('busy')) {
      return SpeechFailure.audio;
    }
    return SpeechFailure.none;
  }

  void _fail(SpeechFailure failure, [String? detail]) {
    if (_failure == SpeechFailure.none) {
      _failure = failure;
    }
    if (detail != null) {
      _errorDetail = detail;
    }
    _completeSession();
  }

  void _completeSession() {
    final completer = _completer;
    if (completer != null && !completer.isCompleted) {
      completer.complete(_lastWords.isEmpty ? null : _lastWords);
    }
  }

  Future<void> _stopPlatform() async {
    try {
      if (!Platform.isAndroid && _speech.isListening) {
        await _speech.stop().timeout(_stopTimeout);
      }
    } catch (error) {
      debugPrint('SpeechService.stop failed: $error');
    }
  }

  /// Ends the active session and keeps whatever text was recognized so far.
  Future<void> stop() async {
    if (Platform.isAndroid) {
      return;
    }
    await _stopPlatform();
  }
}
