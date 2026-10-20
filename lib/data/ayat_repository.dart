import 'dart:convert';
import 'dart:typed_data';

import 'package:sqflite/sqflite.dart';

import '../models/ayat_quran.dart';
import '../models/quran_text_hit.dart';
import '../search/search_scoring.dart';

/// SQLite access for the bundled Lafzi database.
///
/// The query semantics mirror the Android DAOs; reads are batched where the
/// original issued one query per row so large result sets stay responsive.
class AyatRepository {
  AyatRepository(this._db);

  final Database _db;

  static const _columns = <String>[
    '_id',
    'surah_no',
    'surah_name',
    'ayat_no',
    'ayat_arabic',
    'ayat_indonesian',
    'ayat_muqathaat',
  ];

  Future<AyatQuran?> getAyat(int id, {bool isVocal = true}) async {
    final rows = await _db.query(
      'ayat_quran',
      columns: [..._columns, _mappingColumn(isVocal)],
      where: '_id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) {
      return null;
    }
    return _readAyat(rows.first, isVocal: isVocal);
  }

  /// Loads a set of ayat in chunks, returning a map keyed by row id.
  Future<Map<int, AyatQuran>> getAyatMap(
    Iterable<int> ids, {
    bool isVocal = true,
  }) async {
    final result = <int, AyatQuran>{};
    final unique = ids.toSet().toList(growable: false);
    const chunkSize = 400;

    for (var start = 0; start < unique.length; start += chunkSize) {
      final end = (start + chunkSize < unique.length)
          ? start + chunkSize
          : unique.length;
      final chunk = unique.sublist(start, end);
      final placeholders = List.filled(chunk.length, '?').join(',');
      final rows = await _db.query(
        'ayat_quran',
        columns: [..._columns, _mappingColumn(isVocal)],
        where: '_id IN ($placeholders)',
        whereArgs: chunk,
      );
      for (final row in rows) {
        final ayat = _readAyat(row, isVocal: isVocal);
        result[ayat.id] = ayat;
      }
    }
    return result;
  }

  Future<Map<String, List<int>>?> getIndexPost(
    String term, {
    required bool isVocal,
  }) async {
    final table = isVocal ? 'vocal_index' : 'nonvocal_index';
    final rows = await _db.query(
      table,
      columns: const ['term', 'post'],
      where: 'term = ?',
      whereArgs: [term],
      limit: 1,
    );
    if (rows.isEmpty) {
      return null;
    }
    final post = rows.first['post'] as String?;
    if (post == null || post.isEmpty) {
      return null;
    }
    final decoded = jsonDecode(post);
    if (decoded is! Map) {
      return null;
    }

    final result = <String, List<int>>{};
    decoded.forEach((key, value) {
      if (value is List) {
        result[key.toString()] = [
          for (final item in value)
            if (item is num) item.toInt(),
        ];
      }
    });
    return result;
  }

  /// Port of `QuranTextDao.searchArabic`.
  Future<List<QuranTextHit>> searchArabic(String input) async {
    final reversedQuery = normalizeAndReverseArabic(input);
    if (reversedQuery.isEmpty) {
      return const [];
    }

    final rows = await _db.rawQuery(
      '''
SELECT
  docid,
  offsets(quran_text) pos,
  text_reverse text,
  ayat_quran.arabic_text_length full_length,
  ayat_quran.short_arabic_text_length short_length,
  matchinfo(quran_text, 's') subsequence
FROM quran_text
JOIN ayat_quran ON ayat_quran._id = quran_text.docid
WHERE text_reverse MATCH ?
''',
      [reversedQuery],
    );

    final results = <QuranTextHit>[];
    for (final row in rows) {
      final docId = _asInt(row['docid']);
      final text = _reverse(_asString(row['text']));
      final fullLength = _asInt(row['full_length']);
      final shortLength = _asInt(row['short_length']);
      final offsets = _asString(row['pos']);
      final matchInfo = row['subsequence'];
      final score = _firstSignedByte(matchInfo);
      final pos = _splitOffsets(offsets, fullLength, shortLength);

      results.add(
        QuranTextHit(
          docId: docId,
          text: text,
          pos: pos,
          fullLength: fullLength,
          shortLength: shortLength,
          score: score,
        ),
      );
    }

    results.sort((a, b) {
      final byScore = b.score.compareTo(a.score);
      if (byScore != 0) {
        return byScore;
      }
      return a.docId.compareTo(b.docId);
    });
    return results;
  }

  static String _mappingColumn(bool isVocal) =>
      isVocal ? 'vocal_mapping_position' : 'nonvocal_mapping_position';

  AyatQuran _readAyat(Map<String, Object?> row, {required bool isVocal}) {
    final mapping = row[_mappingColumn(isVocal)] as String?;
    return AyatQuran(
      id: _asInt(row['_id']),
      surahNo: _asInt(row['surah_no']),
      surahName: _asString(row['surah_name']),
      ayatNo: _asInt(row['ayat_no']),
      ayatArabic: _asString(row['ayat_arabic']),
      ayatIndonesian: _asString(row['ayat_indonesian']),
      ayatMuqathaat: _asString(row['ayat_muqathaat']),
      mappingPositions: _parseMapping(mapping),
    );
  }

  static List<int> _parseMapping(String? mapping) {
    if (mapping == null || mapping.isEmpty) {
      return const [];
    }
    final parts = mapping.split(',');
    final result = <int>[];
    for (final part in parts) {
      final value = int.tryParse(part);
      if (value != null) {
        result.add(value);
      }
    }
    return result;
  }

  /// Builds the FTS prefix query used for Arabic input, then reverses it.
  ///
  /// Tokens shorter than three characters are ignored, matching the Android
  /// implementation.
  static final RegExp _arabicBidiControls = RegExp(
    r'[\u061C\u200B-\u200F\u202A-\u202E\u2060-\u2069\uFEFF]',
  );
  static final RegExp _arabicWhitespace = RegExp(r'\s+');

  static String normalizeAndReverseArabic(String input) {
    final cleaned = input
        .replaceAll(_arabicBidiControls, '')
        .replaceAll(_arabicWhitespace, ' ')
        .trim();
    final tokens = cleaned.split(' ');
    final buffer = StringBuffer();
    for (var i = 0; i < tokens.length; i++) {
      if (tokens[i].length > 2) {
        buffer.write('*${tokens[i]}');
        if (i != tokens.length - 1) {
          buffer.write(' ');
        }
      }
    }
    return _reverse(buffer.toString());
  }

  static String _reverse(String value) {
    return value.split('').reversed.join();
  }

  /// Port of `QuranText.splitOffsets`.
  static List<int> _splitOffsets(
    String offset,
    int fullLength,
    int shortLength,
  ) {
    final results = <int>[];
    if (offset.isEmpty) {
      return results;
    }
    final splitted = offset.split(' ');
    var biggestMinus = 0;

    for (var i = 0; i < splitted.length; i += 4) {
      final index = i + 2;
      if (index + 1 >= splitted.length) {
        break;
      }
      final originalPos = int.tryParse(splitted[index]);
      final size = int.tryParse(splitted[index + 1]);
      if (originalPos == null || size == null) {
        continue;
      }

      final adjusted =
          shortLength - originalPos - size * (fullLength / shortLength);
      var pos = adjusted.toInt();
      if (pos < biggestMinus) {
        biggestMinus = pos;
      }
      for (var j = 0; j < size; j++) {
        results.add(pos + j);
      }
    }

    if (biggestMinus < 0) {
      for (var i = 0; i < results.length; i++) {
        results[i] = results[i] - biggestMinus;
      }
    }

    return SearchScoring.longestContiguousSubsequence(results, 7);
  }

  static int _firstSignedByte(Object? blob) {
    Uint8List? bytes;
    if (blob is Uint8List) {
      bytes = blob;
    } else if (blob is List<int>) {
      bytes = Uint8List.fromList(blob);
    }
    if (bytes == null || bytes.isEmpty) {
      return 0;
    }
    final value = bytes[0];
    return value > 127 ? value - 256 : value;
  }

  static int _asInt(Object? value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static String _asString(Object? value) => value?.toString() ?? '';
}
