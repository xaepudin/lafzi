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
  late final TapGestureRecognizer _linkRecognizer;
  late final Future<PackageInfo> _packageInfo;

  @override
  void initState() {
    super.initState();
    _packageInfo = PackageInfo.fromPlatform();
    _linkRecognizer = TapGestureRecognizer()
      ..onTap = () {
        launchUrl(
          Uri.parse(AppStrings.aboutLink),
          mode: LaunchMode.externalApplication,
        );
      };
  }

  @override
  void dispose() {
    _linkRecognizer.dispose();
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
    final split = text.split(AppStrings.aboutLink);
    final spans = <InlineSpan>[];
    for (var i = 0; i < split.length; i++) {
      if (split[i].isNotEmpty) {
        spans.add(TextSpan(text: split[i]));
      }
      if (i < split.length - 1) {
        spans.add(
          TextSpan(
            text: AppStrings.aboutLink,
            style: TextStyle(
              color: theme.colorScheme.primary,
              decoration: TextDecoration.underline,
            ),
            recognizer: _linkRecognizer,
          ),
        );
      }
    }
    return spans;
  }
}
