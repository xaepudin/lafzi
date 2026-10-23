import 'package:flutter/material.dart';

import '../core/app_strings.dart';
import '../core/platform_capabilities.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final bodyStyle = theme.textTheme.bodyLarge?.copyWith(
      color: scheme.onSurfaceVariant,
      height: 1.5,
    );
    final headingStyle = bodyStyle?.copyWith(
      color: scheme.onSurface,
      fontWeight: FontWeight.bold,
    );

    final spans = <InlineSpan>[
      TextSpan(text: AppStrings.helpHeaderOrder, style: headingStyle),
      TextSpan(text: '\n${AppStrings.helpOrderBody}\n\n', style: bodyStyle),
      if (PlatformCapabilities.voiceSearch) ...[
        TextSpan(text: AppStrings.helpHeaderVoice, style: headingStyle),
        TextSpan(text: '\n${AppStrings.helpVoiceBody}\n\n', style: bodyStyle),
      ],
      TextSpan(text: AppStrings.helpHeaderMismatch, style: headingStyle),
      TextSpan(text: '\n${AppStrings.helpMismatchBody}\n', style: bodyStyle),
      for (final bullet in AppStrings.helpBullets)
        TextSpan(text: '\u2022 $bullet\n', style: bodyStyle),
      TextSpan(text: '\n${AppStrings.helpHeaderTooMany}', style: headingStyle),
      TextSpan(text: '\n${AppStrings.helpTooManyBody}\n\n', style: bodyStyle),
      TextSpan(text: AppStrings.helpHeaderShare, style: headingStyle),
      TextSpan(text: '\n${AppStrings.helpShareBody}', style: bodyStyle),
    ];

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(AppStrings.bantuan),
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
              child: Text.rich(TextSpan(children: spans)),
            ),
          ),
        ),
      ),
    );
  }
}
