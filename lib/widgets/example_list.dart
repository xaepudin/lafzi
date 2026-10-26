import 'dart:async';

import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../core/arabic_text_style.dart';

/// The rotating list of example queries shown on the empty home screen.
class ExampleList extends StatefulWidget {
  const ExampleList({
    super.key,
    required this.queries,
    required this.onSelected,
    required this.rotationEnabled,
  });

  static const int perPage = 3;

  final List<String> queries;
  final ValueChanged<String> onSelected;
  final bool rotationEnabled;

  @override
  State<ExampleList> createState() => ExampleListState();
}

class ExampleListState extends State<ExampleList> {
  static const _interval = Duration(seconds: 6);

  Timer? _timer;
  int _page = 0;
  bool _forward = true;

  int get _pageCount {
    if (widget.queries.isEmpty) {
      return 1;
    }
    return (widget.queries.length + ExampleList.perPage - 1) ~/
        ExampleList.perPage;
  }

  @override
  void initState() {
    super.initState();
    _syncTimer();
  }

  @override
  void didUpdateWidget(covariant ExampleList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.rotationEnabled != widget.rotationEnabled ||
        oldWidget.queries.length != widget.queries.length) {
      _syncTimer();
    }
  }

  void _syncTimer() {
    _timer?.cancel();
    _timer = null;
    if (!widget.rotationEnabled || _pageCount <= 1) {
      return;
    }
    _timer = Timer.periodic(_interval, (_) => _nextPage());
  }

  void _nextPage() {
    if (!mounted || _pageCount <= 1) {
      return;
    }
    setState(() {
      _forward = true;
      _page = (_page + 1) % _pageCount;
    });
  }

  /// Selects one of the currently visible rows; used by the coach-mark
  /// overlay when its spotlight is tapped.
  void selectRow(int row) {
    final start = _page * ExampleList.perPage;
    final index = start + row;
    if (index >= 0 && index < widget.queries.length) {
      widget.onSelected(widget.queries[index]);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final start = _page * ExampleList.perPage;
    final end = (start + ExampleList.perPage).clamp(0, widget.queries.length);
    final visible = widget.queries.sublist(start, end);
    final theme = Theme.of(context);

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 240),
        switchInCurve: Curves.easeOut,
        switchOutCurve: Curves.easeIn,
        transitionBuilder: (child, animation) {
          final offset = Tween<Offset>(
            begin: Offset(_forward ? 0.04 : -0.04, 0),
            end: Offset.zero,
          ).animate(animation);
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(position: offset, child: child),
          );
        },
        layoutBuilder: (current, previous) => Stack(
          alignment: Alignment.topCenter,
          children: [...previous, ?current],
        ),
        child: Column(
          key: ValueKey(_page),
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < visible.length; i++) ...[
              if (i > 0)
                Divider(
                  height: 1,
                  thickness: 1,
                  color: theme.colorScheme.outlineVariant,
                ),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => widget.onSelected(visible[i]),
                  child: Container(
                    constraints: const BoxConstraints(minHeight: 52),
                    padding: const EdgeInsetsDirectional.only(
                      start: 16,
                      top: 10,
                      end: 12,
                      bottom: 10,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            visible[i],
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: theme.colorScheme.onSurface,
                              fontFamily:
                                  ArabicTextStyle.needsQuranFace(visible[i])
                                      ? ArabicTextStyle.fontFamily
                                      : null,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.chevron_right,
                          size: 20,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Card shell around [ExampleList].
class ExampleListCard extends StatelessWidget {
  const ExampleListCard({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: context.lafziColors.searchBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: child,
    );
  }
}
