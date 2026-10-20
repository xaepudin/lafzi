import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/app_strings.dart';

enum OnboardingAnchor { search, voice, examples }

class OnboardingOverlay extends StatefulWidget {
  const OnboardingOverlay({
    super.key,
    required this.anchors,
    required this.onFinished,
    required this.onExampleRow,
  });

  final Map<OnboardingAnchor, GlobalKey> anchors;
  final VoidCallback onFinished;
  final ValueChanged<int> onExampleRow;

  @override
  State<OnboardingOverlay> createState() => _OnboardingOverlayState();
}

class _OnboardingOverlayState extends State<OnboardingOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;
  final GlobalKey _overlayKey = GlobalKey();

  final Map<OnboardingAnchor, Rect> _rects = {};
  late final List<_Step> _steps;
  int _index = 0;
  bool _measured = false;
  bool _visible = false;
  bool _finished = false;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _steps = [
      _Step(
        anchor: OnboardingAnchor.search,
        title: AppStrings.onboardingSearchTitle,
        message: AppStrings.onboardingSearchMessage,
        above: true,
        round: true,
      ),
      _Step(
        anchor: OnboardingAnchor.voice,
        title: AppStrings.onboardingVoiceTitle,
        message: AppStrings.onboardingVoiceMessage,
        above: false,
        round: true,
      ),
      _Step(
        anchor: OnboardingAnchor.examples,
        title: AppStrings.onboardingExampleTitle,
        message: AppStrings.onboardingExampleMessage,
        above: false,
        round: false,
        clickable: true,
      ),
    ];

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _measure();
      if (!mounted) {
        return;
      }
      setState(() {
        _measured = true;
        _visible = true;
      });
    });
  }

  void _measure() {
    final overlayBox = _overlayKey.currentContext?.findRenderObject();
    if (overlayBox is! RenderBox) {
      return;
    }
    final overlayOrigin = overlayBox.localToGlobal(Offset.zero);
    for (final entry in widget.anchors.entries) {
      final renderObject = entry.value.currentContext?.findRenderObject();
      if (renderObject is! RenderBox || !renderObject.hasSize) {
        continue;
      }
      final origin = renderObject.localToGlobal(Offset.zero);
      final rect = Rect.fromLTWH(
        origin.dx - overlayOrigin.dx,
        origin.dy - overlayOrigin.dy,
        renderObject.size.width,
        renderObject.size.height,
      ).inflate(6);
      _rects[entry.key] = rect;
    }
  }

  List<_Step> get _availableSteps =>
      _steps.where((step) => _rects.containsKey(step.anchor)).toList();

  Future<void> _finish() async {
    if (_finished) {
      return;
    }
    _finished = true;
    widget.onFinished();
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  void _next() {
    final steps = _availableSteps;
    if (_index >= steps.length - 1) {
      _finish();
      return;
    }
    setState(() {
      _index++;
      _measure();
    });
  }

  void _handleTap(TapUpDetails details) {
    final steps = _availableSteps;
    if (steps.isEmpty) {
      _finish();
      return;
    }
    final step = steps[math.min(_index, steps.length - 1)];
    final rect = _rects[step.anchor];
    if (step.clickable &&
        rect != null &&
        rect.contains(details.localPosition)) {
      final relative = details.localPosition.dy - rect.top;
      final rowHeight = rect.height / 3;
      final row = (relative / rowHeight).floor().clamp(0, 2);
      widget.onExampleRow(row);
      _finish();
      return;
    }
    _finish();
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final steps = _availableSteps;
    if (_measured && steps.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _finish());
    }
    final safeIndex = steps.isEmpty ? 0 : math.min(_index, steps.length - 1);
    final step = steps.isEmpty ? null : steps[safeIndex];
    final rect = step == null ? null : _rects[step.anchor];
    final radius = step == null
        ? 22.0
        : (step.round && rect != null ? rect.height / 2 : 22.0);
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          _finish();
        }
      },
      child: Material(
        color: Colors.transparent,
        child: KeyedSubtree(
          key: _overlayKey,
          child: AnimatedOpacity(
            opacity: _visible ? 1 : 0,
            duration: const Duration(milliseconds: 180),
            child: Stack(
              children: [
                Positioned.fill(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTapUp: _handleTap,
                    child: AnimatedBuilder(
                      animation: _pulse,
                      builder: (context, _) {
                        return CustomPaint(
                          painter: _SpotlightPainter(
                            highlight: rect,
                            radius: radius,
                            borderColor: theme.colorScheme.primary,
                            strokeAlpha: 0.35 + 0.65 * _pulse.value,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                if (step != null && rect != null)
                  Positioned.fill(
                    child: CustomSingleChildLayout(
                      delegate: _CardLayoutDelegate(
                        anchor: rect,
                        above: step.above,
                        margin: 16,
                        bottomInset: bottomInset,
                      ),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 160),
                        switchInCurve: Curves.easeOut,
                        switchOutCurve: Curves.easeIn,
                        transitionBuilder: (child, animation) => FadeTransition(
                          opacity: animation,
                          child: ScaleTransition(
                            scale: Tween<double>(
                              begin: 0.96,
                              end: 1,
                            ).animate(animation),
                            child: child,
                          ),
                        ),
                        child: _OnboardingCard(
                          key: ValueKey(safeIndex),
                          step: step,
                          stepNumber: safeIndex + 1,
                          stepCount: steps.length,
                          onSkip: _finish,
                          onNext: _next,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OnboardingCard extends StatelessWidget {
  const _OnboardingCard({
    super.key,
    required this.step,
    required this.stepNumber,
    required this.stepCount,
    required this.onSkip,
    required this.onNext,
  });

  final _Step step;
  final int stepNumber;
  final int stepCount;
  final VoidCallback onSkip;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isLast = stepNumber == stepCount;

    return Material(
      color: scheme.surface,
      elevation: 8,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(step.title, style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              step.message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              AppStrings.onboardingStep(stepNumber, stepCount),
              style: theme.textTheme.labelSmall?.copyWith(
                color: scheme.primary,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: onSkip,
                  child: const Text(AppStrings.onboardingSkip),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: onNext,
                  child: Text(
                    isLast
                        ? AppStrings.onboardingDone
                        : AppStrings.onboardingNext,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Step {
  const _Step({
    required this.anchor,
    required this.title,
    required this.message,
    required this.above,
    required this.round,
    this.clickable = false,
  });

  final OnboardingAnchor anchor;
  final String title;
  final String message;
  final bool above;
  final bool round;
  final bool clickable;
}

class _CardLayoutDelegate extends SingleChildLayoutDelegate {
  _CardLayoutDelegate({
    required this.anchor,
    required this.above,
    required this.margin,
    required this.bottomInset,
  });

  final Rect anchor;
  final bool above;
  final double margin;
  final double bottomInset;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) {
    final width = math.min(300.0, constraints.maxWidth - margin * 2);
    return BoxConstraints(
      maxWidth: width,
      maxHeight: math.max(0, constraints.maxHeight - margin * 2 - bottomInset),
    );
  }

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    var x = anchor.center.dx - childSize.width / 2;
    x = x.clamp(margin, size.width - childSize.width - margin);

    var y = above ? anchor.top - childSize.height - 16 : anchor.bottom + 16;
    y = y.clamp(margin, size.height - childSize.height - margin);
    return Offset(x, y);
  }

  @override
  bool shouldRelayout(_CardLayoutDelegate oldDelegate) {
    return anchor != oldDelegate.anchor ||
        above != oldDelegate.above ||
        margin != oldDelegate.margin ||
        bottomInset != oldDelegate.bottomInset;
  }
}

class _SpotlightPainter extends CustomPainter {
  _SpotlightPainter({
    required this.highlight,
    required this.radius,
    required this.borderColor,
    required this.strokeAlpha,
  });

  final Rect? highlight;
  final double radius;
  final Color borderColor;
  final double strokeAlpha;

  @override
  void paint(Canvas canvas, Size size) {
    final dim = Paint()..color = const Color(0xB3000000);
    final rect = highlight;
    if (rect == null) {
      canvas.drawRect(Offset.zero & size, dim);
      return;
    }

    canvas.saveLayer(Offset.zero & size, Paint());
    canvas.drawRect(Offset.zero & size, dim);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, Radius.circular(radius)),
      Paint()..blendMode = BlendMode.clear,
    );
    canvas.restore();

    final border = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..color = borderColor.withValues(alpha: strokeAlpha);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, Radius.circular(radius)),
      border,
    );
  }

  @override
  bool shouldRepaint(_SpotlightPainter oldDelegate) {
    return highlight != oldDelegate.highlight ||
        radius != oldDelegate.radius ||
        strokeAlpha != oldDelegate.strokeAlpha ||
        borderColor != oldDelegate.borderColor;
  }
}
