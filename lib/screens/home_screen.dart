import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/app_colors.dart';
import '../core/app_strings.dart';
import '../data/ayat_repository.dart';
import '../data/database_service.dart';
import '../data/onboarding_store.dart';
import '../data/settings_controller.dart';
import '../models/ayat_quran.dart';
import '../search/ayat_search_controller.dart';
import '../search/search_engine.dart';
import '../search/speech_service.dart';
import '../widgets/ayat_card.dart';
import '../widgets/example_list.dart';
import '../widgets/onboarding_overlay.dart';
import 'about_screen.dart';
import 'ayat_detail_screen.dart';
import 'help_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.settings});

  final SettingsController settings;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const int minQueryLength = 3;

  final TextEditingController _queryController = TextEditingController();
  final FocusNode _queryFocus = FocusNode();
  final OnboardingStore _onboardingStore = OnboardingStore();
  final GlobalKey _searchBarKey = GlobalKey();
  final GlobalKey _voiceKey = GlobalKey();
  final GlobalKey<ExampleListState> _examplesKey =
      GlobalKey<ExampleListState>();

  late final AyatSearchController _searchController;
  late bool _lastVocal;
  bool _onboardingVisible = false;
  bool _onboardingScheduled = false;
  bool _listening = false;

  SearchStatus get _status => _searchController.status;

  @override
  void initState() {
    super.initState();
    final repository = AyatRepository(DatabaseService.instance.database);
    _searchController = AyatSearchController(SearchEngine(repository));
    _searchController.addListener(_onSearchChanged);
    _queryController.addListener(_onQueryChanged);
    _lastVocal = widget.settings.isVocal;
    widget.settings.addListener(_onSettingsChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scheduleOnboarding();
    });
  }

  @override
  void dispose() {
    widget.settings.removeListener(_onSettingsChanged);
    _searchController
      ..removeListener(_onSearchChanged)
      ..dispose();
    _queryController
      ..removeListener(_onQueryChanged)
      ..dispose();
    _queryFocus.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  void _onQueryChanged() {
    if (!mounted) {
      return;
    }
    if (_queryController.text.isEmpty &&
        _searchController.status != SearchStatus.idle) {
      _searchController.reset();
      return;
    }
    setState(() {});
  }

  void _onSettingsChanged() {
    if (!mounted) {
      return;
    }
    final vocal = widget.settings.isVocal;
    if (vocal != _lastVocal) {
      _lastVocal = vocal;
      final query = _queryController.text.trim();
      if (query.length >= minQueryLength) {
        _searchController.search(query, isVocal: vocal);
      }
    }
    setState(() {});
  }

  Future<void> _scheduleOnboarding() async {
    if (_onboardingScheduled) {
      return;
    }
    _onboardingScheduled = true;
    await Future<void>.delayed(const Duration(milliseconds: 350));
    if (!mounted) {
      return;
    }
    await _maybeShowOnboarding(force: false);
  }

  Future<void> _maybeShowOnboarding({required bool force}) async {
    if (_onboardingVisible || !mounted) {
      return;
    }
    final atStart =
        _status == SearchStatus.idle && _queryController.text.trim().isEmpty;
    if (!force && !atStart) {
      return;
    }
    if (!force && await _onboardingStore.isDone()) {
      return;
    }
    if (!mounted) {
      return;
    }

    final anchors = <OnboardingAnchor, GlobalKey>{
      OnboardingAnchor.search: _searchBarKey,
      OnboardingAnchor.voice: _voiceKey,
    };
    if (atStart) {
      anchors[OnboardingAnchor.examples] = _examplesKey;
    }

    setState(() => _onboardingVisible = true);
    await Navigator.of(context).push(
      PageRouteBuilder<void>(
        opaque: false,
        transitionDuration: const Duration(milliseconds: 180),
        reverseTransitionDuration: const Duration(milliseconds: 140),
        pageBuilder: (context, animation, secondaryAnimation) {
          return OnboardingOverlay(
            anchors: anchors,
            onFinished: () {
              _onboardingStore.markDone();
            },
            onExampleRow: (row) {
              _examplesKey.currentState?.selectRow(row);
            },
          );
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
    if (mounted) {
      setState(() => _onboardingVisible = false);
      await _onboardingStore.markDone();
    }
  }

  void _submit(String raw) {
    final text = raw.trim();
    if (text.length < minQueryLength) {
      _showMessage(AppStrings.queryLessThan3);
      return;
    }
    _queryFocus.unfocus();
    setState(() {});
    _searchController.search(text, isVocal: widget.settings.isVocal);
  }

  void _searchFor(String query) {
    _queryController.value = TextEditingValue(
      text: query,
      selection: TextSelection.collapsed(offset: query.length),
    );
    _submit(query);
  }

  void _clearSearch() {
    _queryController.clear();
    _searchController.reset();
    _queryFocus.requestFocus();
  }

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _startVoiceSearch() async {
    if (_listening) {
      return;
    }
    setState(() => _listening = true);
    final service = SpeechService();
    try {
      final text = await service.listen(
        onPartial: (partial) {
          if (partial.isNotEmpty && mounted) {
            _queryController.value = TextEditingValue(
              text: partial,
              selection: TextSelection.collapsed(offset: partial.length),
            );
          }
        },
      );
      if (!mounted) {
        return;
      }
      if (text == null || text.trim().isEmpty) {
        final message = service.permissionDenied
            ? AppStrings.microphonePermissionDenied
            : service.unavailable
            ? defaultTargetPlatform == TargetPlatform.android
                  ? AppStrings.noSpeechAvailable
                  : AppStrings.speechUnavailable
            : AppStrings.speechNotDetected;
        _showMessage(message);
        return;
      }
      _searchFor(text.trim());
    } finally {
      if (mounted) {
        setState(() => _listening = false);
      }
    }
  }

  void _openAyat(AyatQuran ayat) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            AyatDetailScreen(initialAyatId: ayat.id, settings: widget.settings),
      ),
    );
  }

  Future<void> _copyAyat(AyatQuran ayat) async {
    await Clipboard.setData(
      ClipboardData(text: '${ayat.displayArabic}\n${ayat.ayatIndonesian}'),
    );
    _showMessage(AppStrings.copied);
  }

  Future<void> _openSettings() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SettingsScreen(settings: widget.settings),
      ),
    );
  }

  void _openHelp() {
    Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (_) => const HelpScreen()));
  }

  void _openAbout() {
    Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (_) => const AboutScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final hasText = _queryController.text.isNotEmpty;

    return PopScope(
      canPop: !hasText,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _clearSearch();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          titleSpacing: 8,
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                'assets/images/logo_lafzi_small.png',
                height: 28,
                filterQuality: FilterQuality.high,
                semanticLabel: AppStrings.toolbarLogo,
              ),
              const SizedBox(width: 10),
              Text(AppStrings.appName, style: theme.appBarTheme.titleTextStyle),
            ],
          ),
          actions: [
            IconButton(
              key: _voiceKey,
              onPressed: _startVoiceSearch,
              tooltip: AppStrings.searchByVoice,
              icon: Icon(
                Icons.mic_none,
                color: _listening ? scheme.primary : scheme.onSurfaceVariant,
              ),
            ),
            PopupMenuButton<String>(
              tooltip: 'Menu',
              icon: Icon(Icons.more_vert, color: scheme.onSurfaceVariant),
              onSelected: (value) {
                switch (value) {
                  case 'panduan':
                    _maybeShowOnboarding(force: true);
                    break;
                  case 'bantuan':
                    _openHelp();
                    break;
                  case 'pengaturan':
                    _openSettings();
                    break;
                  case 'about':
                    _openAbout();
                    break;
                }
              },
              itemBuilder: (context) => const [
                PopupMenuItem(
                  value: 'panduan',
                  child: Text(AppStrings.panduan),
                ),
                PopupMenuItem(
                  value: 'bantuan',
                  child: Text(AppStrings.bantuan),
                ),
                PopupMenuItem(
                  value: 'pengaturan',
                  child: Text(AppStrings.pengaturan),
                ),
                PopupMenuItem(value: 'about', child: Text(AppStrings.about)),
              ],
            ),
          ],
        ),
        body: Column(
          children: [
            if (_status == SearchStatus.success)
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 2),
                  child: Text(
                    AppStrings.resultCount(_searchController.results.length),
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: scheme.primary,
                    ),
                  ),
                ),
              ),
            Expanded(child: _buildContent()),
            SafeArea(
              top: false,
              minimum: const EdgeInsets.only(bottom: 4),
              child: _buildSearchBar(context, hasText),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    switch (_status) {
      case SearchStatus.idle:
        return _buildInitialHint();
      case SearchStatus.loading:
        return const Center(child: CircularProgressIndicator());
      case SearchStatus.empty:
      case SearchStatus.error:
        return _buildEmptyResult();
      case SearchStatus.success:
        return _buildResults();
    }
  }

  Widget _buildSearchBar(BuildContext context, bool hasText) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      // A little breathing room above the Android navigation bar.
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: KeyedSubtree(
        key: _searchBarKey,
        child: Material(
          elevation: 2,
          color: context.lafziColors.searchBackground,
          borderRadius: BorderRadius.circular(28),
          clipBehavior: Clip.antiAlias,
          child: SizedBox(
            height: 56,
            child: Row(
              children: [
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: _queryController,
                    focusNode: _queryFocus,
                    textInputAction: TextInputAction.search,
                    onSubmitted: _submit,
                    maxLines: 1,
                    style: TextStyle(color: scheme.onSurface, fontSize: 16),
                    decoration: InputDecoration(
                      hintText: AppStrings.searchHint,
                      hintStyle: TextStyle(
                        color: scheme.onSurfaceVariant,
                        fontSize: 16,
                      ),
                      border: InputBorder.none,
                      isCollapsed: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 18),
                    ),
                  ),
                ),
                AnimatedSize(
                  duration: const Duration(milliseconds: 160),
                  curve: Curves.easeOut,
                  child: hasText
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              onPressed: _clearSearch,
                              tooltip: AppStrings.clearSearch,
                              icon: Icon(
                                Icons.close,
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(right: 4),
                              child: IconButton.filled(
                                onPressed: () => _submit(_queryController.text),
                                tooltip: AppStrings.searchAction,
                                icon: const Icon(Icons.search),
                                style: IconButton.styleFrom(
                                  fixedSize: const Size(48, 48),
                                  maximumSize: const Size(48, 48),
                                ),
                              ),
                            ),
                          ],
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInitialHint() {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(32, 24, 32, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.search,
                      size: 56,
                      color: scheme.onSurfaceVariant.withValues(alpha: 0.6),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      AppStrings.emptyTitle,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: scheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      AppStrings.emptySubtitle,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ExampleListCard(
                        child: ExampleList(
                          key: _examplesKey,
                          queries: AppStrings.exampleQueries,
                          onSelected: _searchFor,
                          rotationEnabled:
                              !_onboardingVisible &&
                              _queryController.text.isEmpty,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyResult() {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search,
              size: 56,
              color: scheme.outline.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              AppStrings.noResultTitle,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              AppStrings.noResultSubtitle,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResults() {
    final results = _searchController.results;
    return ListView.builder(
      padding: const EdgeInsets.only(top: 4, bottom: 20),
      itemCount: results.length,
      itemBuilder: (context, index) {
        final ayat = results[index];
        return AyatCard(
          ayat: ayat,
          position: index + 1,
          showTranslation: widget.settings.showTranslation,
          onTap: () => _openAyat(ayat),
          onLongPress: () => _copyAyat(ayat),
        );
      },
    );
  }
}
