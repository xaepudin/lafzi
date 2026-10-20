import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../core/arabic_text_style.dart';
import '../models/highlight_position.dart';

/// Renders Arabic Quran text with the bundled MeQuran face and yellow
/// highlight spans matching the Android result cards.
class HighlightedArabicText extends StatelessWidget {
  const HighlightedArabicText({
    super.key,
    required this.text,
    this.highlights = const [],
    this.fontSize = 26,
    this.textAlign = TextAlign.right,
    this.maxLines,
  });

  final String text;
  final List<HighlightPosition> highlights;
  final double fontSize;
  final TextAlign textAlign;
  final int? maxLines;

  @override
  Widget build(BuildContext context) {
    final style = ArabicTextStyle.of(context, fontSize: fontSize);
    final highlightColor = context.lafziColors.highlight;

    final spans = <InlineSpan>[];
    if (highlights.isEmpty) {
      spans.add(TextSpan(text: text));
    } else {
      final ranges = _mergedRanges(highlights, text.length);
      var cursor = 0;
      for (final range in ranges) {
        if (range.start > cursor) {
          spans.add(TextSpan(text: text.substring(cursor, range.start)));
        }
        spans.add(
          TextSpan(
            text: text.substring(range.start, range.end),
            style: TextStyle(backgroundColor: highlightColor),
          ),
        );
        cursor = range.end;
      }
      if (cursor < text.length) {
        spans.add(TextSpan(text: text.substring(cursor)));
      }
    }

    return Text.rich(
      TextSpan(style: style, children: spans),
      textAlign: textAlign,
      textDirection: TextDirection.rtl,
      maxLines: maxLines,
      overflow: maxLines == null ? TextOverflow.clip : TextOverflow.ellipsis,
    );
  }

  static List<_Range> _mergedRanges(
    List<HighlightPosition> positions,
    int textLength,
  ) {
    if (textLength == 0) {
      return const [];
    }
    final normalized = <_Range>[];
    for (final hp in positions) {
      var start = hp.start;
      var end = hp.end;
      if (start > end) {
        final temp = start;
        start = end;
        end = temp;
      }
      if (start < 0) {
        start = 0;
      }
      if (end < 0) {
        end = 0;
      }
      if (start > textLength - 1) {
        start = textLength - 1;
      }
      if (end > textLength - 1) {
        end = textLength - 1;
      }
      normalized.add(_Range(start, end + 1));
    }
    normalized.sort((a, b) => a.start.compareTo(b.start));

    final merged = <_Range>[];
    for (final range in normalized) {
      if (merged.isEmpty || range.start > merged.last.end) {
        merged.add(range);
      } else if (range.end > merged.last.end) {
        merged[merged.length - 1] = _Range(merged.last.start, range.end);
      }
    }
    return merged;
  }
}

class _Range {
  const _Range(this.start, this.end);
  final int start;
  final int end;
}
