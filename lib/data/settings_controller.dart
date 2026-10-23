import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persisted user settings, matching the Android preferences keys.
class SettingsController extends ChangeNotifier {
  static const _isVocalKey = 'isvocal';
  static const _showTranslationKey = 'showtrans';
  static const _showSimilarityKey = 'showsimilarity';

  bool _isVocal = true;
  bool _showTranslation = true;
  bool _showSimilarity = false;
  bool _loaded = false;

  bool get isVocal => _isVocal;
  bool get showTranslation => _showTranslation;

  /// Whether result cards show the relevance percentage. Off by default,
  /// matching the original app's behaviour.
  bool get showSimilarity => _showSimilarity;
  bool get loaded => _loaded;

  Future<void> load() async {
    final preferences = await SharedPreferences.getInstance();
    _isVocal = preferences.getBool(_isVocalKey) ?? true;
    _showTranslation = preferences.getBool(_showTranslationKey) ?? true;
    _showSimilarity = preferences.getBool(_showSimilarityKey) ?? false;
    _loaded = true;
    notifyListeners();
  }

  Future<void> setVocal(bool value) async {
    if (_isVocal == value) {
      return;
    }
    _isVocal = value;
    notifyListeners();
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_isVocalKey, value);
  }

  Future<void> setShowTranslation(bool value) async {
    if (_showTranslation == value) {
      return;
    }
    _showTranslation = value;
    notifyListeners();
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_showTranslationKey, value);
  }

  Future<void> setShowSimilarity(bool value) async {
    if (_showSimilarity == value) {
      return;
    }
    _showSimilarity = value;
    notifyListeners();
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_showSimilarityKey, value);
  }
}
