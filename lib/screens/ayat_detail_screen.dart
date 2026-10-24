import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import '../core/app_strings.dart';
import '../data/ayat_repository.dart';
import '../data/database_service.dart';
import '../models/ayat_quran.dart';
import '../share/share_service.dart';
import '../widgets/highlighted_arabic_text.dart';

class AyatDetailScreen extends StatefulWidget {
  const AyatDetailScreen({super.key, required this.initialAyatId});

  static const int ayatCount = 6236;

  final int initialAyatId;

  @override
  State<AyatDetailScreen> createState() => _AyatDetailScreenState();
}

class _AyatDetailScreenState extends State<AyatDetailScreen> {
  late final PageController _pageController;
  late final AyatRepository _repository;
  final Map<int, Future<AyatQuran?>> _futureCache = {};
  final Map<int, AyatQuran?> _cache = {};

  late int _currentId;
  AyatQuran? _currentAyat;

  @override
  void initState() {
    super.initState();
    _repository = AyatRepository(DatabaseService.instance.database);
    _currentId = widget.initialAyatId.clamp(1, AyatDetailScreen.ayatCount);
    _pageController = PageController(initialPage: _currentId - 1);
    _resolveCurrent();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<AyatQuran?> _futureFor(int ayatId) {
    return _futureCache.putIfAbsent(ayatId, () async {
      final ayat = await _repository.getAyat(ayatId, isVocal: true);
      _cache[ayatId] = ayat;
      return ayat;
    });
  }

  void _resolveCurrent() {
    final id = _currentId;
    _currentAyat = _cache[id];
    _futureFor(id).then((ayat) {
      if (!mounted || id != _currentId) {
        return;
      }
      setState(() => _currentAyat = ayat);
      _prefetch(id);
    });
    _prefetch(id);
  }

  void _prefetch(int id) {
    for (final neighbour in [id - 1, id + 1]) {
      if (neighbour >= 1 && neighbour <= AyatDetailScreen.ayatCount) {
        _futureFor(neighbour);
      }
    }
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentId = index + 1;
      _currentAyat = _cache[_currentId];
    });
    _resolveCurrent();
  }

  void _moveBy(int delta) {
    final next = _pageController.page?.round() ?? (_currentId - 1);
    final target = next + delta;
    if (target >= 0 && target < AyatDetailScreen.ayatCount) {
      _pageController.animateToPage(
        target,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
      );
    }
  }

  String _arabicOf(AyatQuran ayat) => ayat.displayArabic;

  String _suratAyatOf(AyatQuran ayat) =>
      AppStrings.suratAyat(ayat.surahName, ayat.surahNo, ayat.ayatNo);

  Future<void> _showShareSheet() async {
    final ayat = _currentAyat;
    if (ayat == null) {
      return;
    }
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  AppStrings.shareSheetTitle,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 4),
                Text(
                  AppStrings.shareSheetSubtitle,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 20),
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _shareImage(ayat);
                  },
                  style: OutlinedButton.styleFrom(
                    alignment: Alignment.centerLeft,
                    minimumSize: const Size.fromHeight(48),
                  ),
                  icon: const Icon(Icons.image_outlined),
                  label: const Text(AppStrings.shareImage),
                ),
                if (kIsWeb) ...[
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      _downloadImage(ayat);
                    },
                    style: OutlinedButton.styleFrom(
                      alignment: Alignment.centerLeft,
                      minimumSize: const Size.fromHeight(48),
                    ),
                    icon: const Icon(Icons.download_outlined),
                    label: const Text(AppStrings.downloadImage),
                  ),
                ],
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _shareText(ayat);
                  },
                  style: OutlinedButton.styleFrom(
                    alignment: Alignment.centerLeft,
                    minimumSize: const Size.fromHeight(48),
                  ),
                  icon: const Icon(Icons.text_fields),
                  label: const Text(AppStrings.shareText),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _shareText(AyatQuran ayat) async {
    try {
      await ShareService.instance.shareText(
        suratAyat: _suratAyatOf(ayat),
        arabic: _arabicOf(ayat),
        translation: ayat.ayatIndonesian,
      );
    } catch (_) {
      if (mounted) {
        _showShareError();
      }
    }
  }

  Future<void> _shareImage(AyatQuran ayat) {
    return _runImageAction(
      label: AppStrings.shareImage,
      action: () =>
          ShareService.instance.shareImage(context: context, ayat: ayat),
    );
  }

  Future<void> _downloadImage(AyatQuran ayat) {
    return _runImageAction(
      label: AppStrings.downloadImage,
      action: () =>
          ShareService.instance.saveImage(context: context, ayat: ayat),
      successMessage: AppStrings.imageDownloaded,
    );
  }

  Future<void> _runImageAction({
    required String label,
    required Future<void> Function() action,
    String? successMessage,
  }) async {
    if (!mounted) {
      return;
    }
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 3),
                ),
                const SizedBox(width: 16),
                Text(label),
              ],
            ),
          ),
        ),
      ),
    );

    var failed = false;
    try {
      await action();
    } catch (_) {
      failed = true;
    } finally {
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }
    }
    if (!mounted) {
      return;
    }
    if (failed) {
      _showShareError();
    } else if (successMessage != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(successMessage)));
    }
  }

  void _showShareError() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(AppStrings.gagalMembagi),
        content: const Text(AppStrings.tidakBisaMuatGambar),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final ayat = _currentAyat;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              ayat?.surahName ?? AppStrings.appName,
              style: TextStyle(
                color: scheme.onSurface,
                fontSize: 20,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (ayat != null)
              Text(
                AppStrings.ayat(ayat.ayatNo),
                style: TextStyle(
                  color: scheme.onSurfaceVariant,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              itemCount: AyatDetailScreen.ayatCount,
              onPageChanged: _onPageChanged,
              itemBuilder: (context, index) {
                final ayatId = index + 1;
                return _AyatPage(future: _futureFor(ayatId));
              },
            ),
          ),
          _buildActionBar(context),
        ],
      ),
    );
  }

  Widget _buildActionBar(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SafeArea(
      top: false,
      child: Container(
        color: scheme.surface,
        padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
        child: Row(
          children: [
            Expanded(
              flex: 4,
              child: TextButton(
                onPressed: () => _moveBy(-1),
                child: const Text(AppStrings.sebelum),
              ),
            ),
            Expanded(
              flex: 5,
              child: FilledButton.tonalIcon(
                onPressed: _currentAyat == null ? null : _showShareSheet,
                icon: const Icon(Icons.share, size: 20),
                label: const Text(AppStrings.bagikan),
              ),
            ),
            Expanded(
              flex: 4,
              child: TextButton(
                onPressed: () => _moveBy(1),
                child: const Text(AppStrings.berikut),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AyatPage extends StatelessWidget {
  const _AyatPage({required this.future});

  final Future<AyatQuran?> future;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return FutureBuilder<AyatQuran?>(
      future: future,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final ayat = snapshot.data;
        if (ayat == null) {
          return Center(
            child: Text(
              AppStrings.noResultTitle,
              style: theme.textTheme.bodyLarge,
            ),
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Card(
            elevation: 0,
            color: scheme.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
              side: BorderSide(color: scheme.outlineVariant),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    AppStrings.suratAyat(
                      ayat.surahName,
                      ayat.surahNo,
                      ayat.ayatNo,
                    ),
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: scheme.primary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  HighlightedArabicText(text: ayat.displayArabic, fontSize: 28),
                  const SizedBox(height: 16),
                  Divider(color: scheme.outlineVariant),
                  // The detail screen always shows the translation; the
                  // "Tampilkan terjemahan" setting only applies to results.
                  const SizedBox(height: 16),
                  Text(
                    ayat.ayatIndonesian,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: scheme.onSurfaceVariant,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
