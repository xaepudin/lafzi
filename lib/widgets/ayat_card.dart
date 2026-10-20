import 'package:flutter/material.dart';

import '../core/app_strings.dart';
import '../models/ayat_quran.dart';
import 'highlighted_arabic_text.dart';

class AyatCard extends StatelessWidget {
  const AyatCard({
    super.key,
    required this.ayat,
    required this.position,
    required this.showTranslation,
    this.onTap,
    this.onLongPress,
  });

  final AyatQuran ayat;
  final int position;
  final bool showTranslation;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Card(
        elevation: 1,
        color: scheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      width: 26,
                      height: 26,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: scheme.primaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '$position',
                        style: TextStyle(
                          color: scheme.onPrimaryContainer,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        AppStrings.suratAyat(
                          ayat.surahName,
                          ayat.surahNo,
                          ayat.ayatNo,
                        ),
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                HighlightedArabicText(
                  text: ayat.displayArabic,
                  highlights: ayat.highlightPositions,
                ),
                if (showTranslation) ...[
                  const SizedBox(height: 10),
                  Text(
                    ayat.ayatIndonesian,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                      height: 1.45,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
