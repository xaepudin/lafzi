import 'dart:math' as math;

import '../data/ayat_repository.dart';
import '../models/ayat_quran.dart';
import '../models/found_document.dart';
import '../models/quran_text_hit.dart';
import 'highlight_util.dart';
import 'query_normalizer.dart';
import 'search_scoring.dart';
import 'trigram_extractor.dart';

/// Full search pipeline: Latin phonetic trigram search and Arabic FTS search.
class SearchEngine {
  SearchEngine(this._repository);

  final AyatRepository _repository;

  bool isLatin(String text) {
    for (final unit in text.codeUnits) {
      if (unit > 0x7F) {
        return false;
      }
    }
    return true;
  }

  Future<List<AyatQuran>> search(
    String rawQuery, {
    required bool isVocal,
  }) async {
    if (!isLatin(rawQuery)) {
      return _searchArabic(rawQuery);
    }
    return _searchLatin(rawQuery, isVocal: isVocal);
  }

  Future<List<AyatQuran>> _searchLatin(
    String rawQuery, {
    required bool isVocal,
  }) async {
    final queryFinal = QueryNormalizer.normalize(rawQuery, isVocal: isVocal);
    final maxScore = queryFinal.length - 2;
    if (maxScore <= 0) {
      return const [];
    }

    final matched = await _collectMatches(queryFinal, isVocal: isVocal);
    if (matched.isEmpty) {
      return const [];
    }

    Map<int, FoundDocument> filtered = const {};
    for (var threshold = 0.9; threshold >= 0.7 - 1e-9; threshold -= 0.1) {
      final minScore = threshold * maxScore;
      filtered = {
        for (final entry in matched.entries)
          if (entry.value.matchedTrigramsCount >= minScore)
            entry.key: entry.value,
      };
      if (filtered.isNotEmpty) {
        break;
      }
    }

    if (filtered.isEmpty) {
      return const [];
    }

    final ayatMap = await _repository.getAyatMap(
      filtered.keys,
      isVocal: isVocal,
    );

    final documents = <FoundDocument>[];
    for (final document in filtered.values) {
      final ayat = ayatMap[document.ayatQuranId];
      if (ayat == null) {
        continue;
      }
      document.ayatQuran = ayat;
      ayat.highlightPositions = HighlightUtil.applyToDocument(document, ayat);
      documents.add(document);
    }

    documents.sort((a, b) {
      final byScore = b.score.compareTo(a.score);
      if (byScore != 0) {
        return byScore;
      }
      return a.ayatQuranId.compareTo(b.ayatQuranId);
    });

    final results = <AyatQuran>[];
    for (final document in documents) {
      final ayat = document.ayatQuran;
      if (ayat == null) {
        continue;
      }
      ayat.relevance = math.min(
        (document.score / maxScore * 100).floorToDouble(),
        100,
      );
      ayat.score = document.score;
      results.add(ayat);
    }
    return results;
  }

  Future<Map<int, FoundDocument>> _collectMatches(
    String queryFinal, {
    required bool isVocal,
  }) async {
    final matched = <int, FoundDocument>{};
    final trigrams = TrigramExtractor.extract(queryFinal);

    for (final trigram in trigrams.entries) {
      final post = await _repository.getIndexPost(
        trigram.key,
        isVocal: isVocal,
      );
      if (post == null) {
        // The Android code assumed every generated trigram exists in the
        // index. Skipping an absent term is equivalent for real hits and
        // keeps uncommon Latin input from failing the whole search.
        continue;
      }

      for (final entry in post.entries) {
        final ayatId = int.tryParse(entry.key);
        if (ayatId == null) {
          continue;
        }
        final positions = entry.value;

        var document = matched[ayatId];
        if (document == null) {
          document = FoundDocument()
            ..ayatQuranId = ayatId
            ..matchedTrigramsCount = 1;
          matched[ayatId] = document;
        } else {
          final queryFrequency = trigram.value.frequency;
          final termFrequency = positions.length;
          document.matchedTrigramsCount += queryFrequency < termFrequency
              ? queryFrequency
              : termFrequency;
        }

        document.matchedTerms[trigram.key] = positions;
      }
    }

    for (final document in matched.values) {
      document.matchedTermsCountScore = document.matchedTrigramsCount;

      final flattened = <int>[];
      for (final sequence in document.matchedTerms.values) {
        flattened.addAll(sequence);
      }

      final lis = SearchScoring.longestContiguousSubsequence(flattened, 7);
      document.lis = lis;
      document.matchedTermsOrderScore = lis.length;
      document.matchedTermsContiguityScore =
          SearchScoring.reciprocalDiffAverage(lis);
      document.score =
          document.matchedTermsOrderScore *
          document.matchedTermsContiguityScore;
    }

    return matched;
  }

  Future<List<AyatQuran>> _searchArabic(String rawQuery) async {
    final List<QuranTextHit> hits;
    try {
      hits = await _repository.searchArabic(rawQuery);
    } catch (_) {
      return const [];
    }
    if (hits.isEmpty) {
      return const [];
    }

    final ayatMap = await _repository.getAyatMap(hits.map((hit) => hit.docId));
    final results = <AyatQuran>[];
    for (final hit in hits) {
      final ayat = ayatMap[hit.docId];
      if (ayat == null) {
        continue;
      }
      ayat.score = hit.score.toDouble();
      ayat.highlightPositions = HighlightUtil.longestHighlightLookforward(
        hit.pos,
        6,
      );
      results.add(ayat);
    }
    return results;
  }
}
