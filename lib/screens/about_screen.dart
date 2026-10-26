import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/app_strings.dart';

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  late final Map<String, TapGestureRecognizer> _linkRecognizers;
  late final Future<PackageInfo> _packageInfo;

  @override
  void initState() {
    super.initState();
    _packageInfo = PackageInfo.fromPlatform();
    _linkRecognizers = <String, TapGestureRecognizer>{
      for (final link in AppStrings.aboutLinks)
        link: TapGestureRecognizer()
          ..onTap = () {
            launchUrl(Uri.parse(link), mode: LaunchMode.externalApplication);
          },
    };
  }

  @override
  void dispose() {
    for (final recognizer in _linkRecognizers.values) {
      recognizer.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return FutureBuilder<PackageInfo>(
      future: _packageInfo,
      builder: (context, snapshot) {
        final version = snapshot.data?.version ?? '';
        return Scaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: Text(
              version.isEmpty
                  ? AppStrings.about
                  : AppStrings.aboutTitle(version),
            ),
          ),
          body: SafeArea(
            top: false,
            child: SingleChildScrollView(
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
                  child: Text.rich(
                    TextSpan(
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: scheme.onSurfaceVariant,
                        height: 1.5,
                      ),
                      children: _buildSpans(theme),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  List<InlineSpan> _buildSpans(ThemeData theme) {
    final text = AppStrings.aboutText;
    final linkStyle = TextStyle(
      color: theme.colorScheme.primary,
      decoration: TextDecoration.underline,
    );
    final spans = <InlineSpan>[];
    var index = 0;
    while (index < text.length) {
      final next = _nextLinkAt(text, index);
      if (next == null) {
        spans.add(TextSpan(text: text.substring(index)));
        break;
      }
      final (link, start) = next;
      if (start > index) {
        spans.add(TextSpan(text: text.substring(index, start)));
      }
      spans.add(
        TextSpan(
          text: link,
          style: linkStyle,
          recognizer: _linkRecognizers[link],
        ),
      );
      index = start + link.length;
    }
    return spans;
  }

  /// Earliest occurrence of any about link at or after [from], if any.
  (String, int)? _nextLinkAt(String text, int from) {
    (String, int)? earliest;
    for (final link in AppStrings.aboutLinks) {
      final start = text.indexOf(link, from);
      if (start < 0) continue;
      if (earliest == null || start < earliest.$2) earliest = (link, start);
    }
    return earliest;
  }
}
