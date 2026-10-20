import 'package:flutter/foundation.dart';

import '../models/ayat_quran.dart';
import 'search_engine.dart';

enum SearchStatus { idle, loading, success, empty, error }

/// Holds the current result list and discards stale asynchronous searches.
class AyatSearchController extends ChangeNotifier {
  AyatSearchController(this._engine);

  final SearchEngine _engine;

  SearchStatus _status = SearchStatus.idle;
  List<AyatQuran> _results = const [];
  String _query = '';
  int _token = 0;

  SearchStatus get status => _status;
  List<AyatQuran> get results => _results;
  String get query => _query;

  Future<void> search(String rawQuery, {required bool isVocal}) async {
    final normalized = rawQuery.trim();
    final token = ++_token;
    _query = normalized;
    _status = SearchStatus.loading;
    _results = const [];
    notifyListeners();

    try {
      final results = await _engine.search(normalized, isVocal: isVocal);
      if (token != _token) {
        return;
      }
      _results = results;
      _status = results.isEmpty ? SearchStatus.empty : SearchStatus.success;
    } catch (_) {
      if (token != _token) {
        return;
      }
      _results = const [];
      _status = SearchStatus.error;
    }
    notifyListeners();
  }

  void reset() {
    _token++;
    _query = '';
    _results = const [];
    _status = SearchStatus.idle;
    notifyListeners();
  }
}
