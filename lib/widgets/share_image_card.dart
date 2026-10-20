import 'package:flutter/material.dart';

import '../core/app_strings.dart';
import '../models/ayat_quran.dart';

/// The branded card rendered off-screen when the user shares an ayat as an
/// image. Colors are fixed because the shared image always uses a light
/// background, matching the Android renderer.
class ShareImageCard extends StatelessWidget {
  const ShareImageCard({super.key, required this.ayat, required this.width});

  final AyatQuran ayat;
  final double width;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      color: const Color(0xFFFFFFFF),
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            ayat.surahName,
            style: const TextStyle(
              color: Color(0xFF005500),
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            ayat.displayArabic,
            textAlign: TextAlign.right,
            textDirection: TextDirection.rtl,
            style: const TextStyle(
              fontFamily: 'MeQuran',
              fontSize: 26,
              height: 1.65,
              color: Color(0xFF191D17),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            ayat.ayatIndonesian,
            style: const TextStyle(
              color: Color(0xFF42493E),
              fontSize: 14,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/images/logo_lafzi_big.png',
                width: 80,
                height: 80,
                fit: BoxFit.contain,
              ),
              const SizedBox(width: 10),
              const Flexible(
                child: Text(
                  AppStrings.shareImageFooter,
                  style: TextStyle(
                    color: Color(0xFF005500),
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
