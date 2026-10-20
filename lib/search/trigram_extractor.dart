import '../models/frequency_position.dart';

/// Port of `TrigramUtil.extractTrigramFrequencyAndPosition`.
abstract final class TrigramExtractor {
  static Map<String, FrequencyPosition> extract(String text) {
    final results = <String, FrequencyPosition>{};
    if (text.length < 3) {
      return results;
    }
    if (text.length == 3) {
      results[text] = const FrequencyPosition(frequency: 1, positions: [1]);
      return results;
    }

    for (var i = 0; i < text.length - 2; i++) {
      final trigram = text.substring(i, i + 3);
      final existing = results[trigram];
      if (existing != null) {
        results[trigram] = FrequencyPosition(
          frequency: existing.frequency + 1,
          positions: [...existing.positions, i],
        );
      } else {
        results[trigram] = FrequencyPosition(frequency: 1, positions: [i]);
      }
    }
    return results;
  }
}
