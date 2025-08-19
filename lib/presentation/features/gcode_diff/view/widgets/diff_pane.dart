import 'package:flutter/material.dart';
import 'package:test_gcode/core/utils/gcode_highlighter.dart';
import 'package:test_gcode/domain/entities/gcode_diff.dart';

/// Redesigned DiffPane with correct row height:
/// - two rounded cards with internal scroll (not full-screen)
/// - synced scrolling (rows with same index align)
/// - animated highlight for current diff
class DiffPane extends StatefulWidget {
  final GCodeDiff diff;
  final int? currentDiffIndex;

  const DiffPane({
    Key? key,
    required this.diff,
    this.currentDiffIndex,
  }) : super(key: key);

  @override
  State<DiffPane> createState() => _DiffPaneState();
}

class _DiffPaneState extends State<DiffPane> {
  // Итоговая высота одной строки (включая padding + margin + текст).
  // Увеличил, чтобы контент не усекался.
  static const double _lineHeight = 44.0;
  static const double _maxPaneHeight = 650.0;

  // Внутренние вертикальные отступы для item — полезно знать для расчёта,
  // но важна единая константа _lineHeight, используемая для синхронизации скролла.
  static const double _itemVerticalPadding = 8.0; // top + bottom padding = 16
  static const double _itemVerticalMargin = 6.0; // top + bottom margin = 12

  late final ScrollController _originalController;
  late final ScrollController _modifiedController;

  bool _isSyncing = false;

  @override
  void initState() {
    super.initState();
    _originalController = ScrollController();
    _modifiedController = ScrollController();

    _originalController
        .addListener(() => _onScroll(_originalController, _modifiedController));
    _modifiedController
        .addListener(() => _onScroll(_modifiedController, _originalController));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.currentDiffIndex != null) {
        _scrollToCurrentIndex(widget.currentDiffIndex!, animate: false);
      }
    });
  }

  @override
  void didUpdateWidget(covariant DiffPane oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.diff != widget.diff) {
      _clampControllersToMax();
    }

    if (widget.currentDiffIndex != null &&
        widget.currentDiffIndex != oldWidget.currentDiffIndex) {
      _scrollToCurrentIndex(widget.currentDiffIndex!, animate: true);
    }
  }

  @override
  void dispose() {
    _originalController.dispose();
    _modifiedController.dispose();
    super.dispose();
  }

  void _onScroll(ScrollController source, ScrollController target) {
    if (_isSyncing) return;
    if (!source.hasClients || !target.hasClients) return;

    final int sourceLine = (source.offset / _lineHeight).round();
    final double targetOffset = (sourceLine * _lineHeight).clamp(
      0.0,
      target.position.maxScrollExtent,
    );

    if ((target.offset - targetOffset).abs() > 1.0) {
      _isSyncing = true;
      target.jumpTo(targetOffset);
      _isSyncing = false;
    }
  }

  void _clampControllersToMax() {
    if (_originalController.hasClients) {
      final maxOrig = _originalController.position.maxScrollExtent;
      if (_originalController.offset > maxOrig) {
        _originalController.jumpTo(maxOrig);
      }
    }
    if (_modifiedController.hasClients) {
      final maxMod = _modifiedController.position.maxScrollExtent;
      if (_modifiedController.offset > maxMod) {
        _modifiedController.jumpTo(maxMod);
      }
    }
  }

  Future<void> _scrollToCurrentIndex(int diffIndex,
      {bool animate = true}) async {
    if (!mounted) return;

    int origLine = -1;
    int modLine = -1;

    if (widget.diff.originalDiffLines.isNotEmpty &&
        diffIndex >= 0 &&
        diffIndex < widget.diff.originalDiffLines.length) {
      origLine = widget.diff.originalDiffLines[diffIndex];
    }

    if (widget.diff.modifiedDiffLines.isNotEmpty &&
        diffIndex >= 0 &&
        diffIndex < widget.diff.modifiedDiffLines.length) {
      modLine = widget.diff.modifiedDiffLines[diffIndex];
    }

    if (origLine < 0 && widget.diff.originalLines.isNotEmpty) {
      origLine = diffIndex.clamp(0, widget.diff.originalLines.length - 1);
    }
    if (modLine < 0 && widget.diff.modifiedLines.isNotEmpty) {
      modLine = diffIndex.clamp(0, widget.diff.modifiedLines.length - 1);
    }

    final int targetIndex = [
      origLine.clamp(
          0,
          widget.diff.originalLines.isEmpty
              ? 0
              : widget.diff.originalLines.length - 1),
      modLine.clamp(
          0,
          widget.diff.modifiedLines.isEmpty
              ? 0
              : widget.diff.modifiedLines.length - 1),
    ].reduce((a, b) => a < b ? a : b);

    final double origOffset = (targetIndex * _lineHeight).clamp(
      0.0,
      _originalController.hasClients
          ? _originalController.position.maxScrollExtent
          : 0.0,
    );
    final double modOffset = (targetIndex * _lineHeight).clamp(
      0.0,
      _modifiedController.hasClients
          ? _modifiedController.position.maxScrollExtent
          : 0.0,
    );

    try {
      _isSyncing = true;
      if (_originalController.hasClients) {
        if (animate) {
          await _originalController.animateTo(origOffset,
              duration: const Duration(milliseconds: 240),
              curve: Curves.easeInOut);
        } else {
          _originalController.jumpTo(origOffset);
        }
      }
      if (_modifiedController.hasClients) {
        if (animate) {
          await _modifiedController.animateTo(modOffset,
              duration: const Duration(milliseconds: 240),
              curve: Curves.easeInOut);
        } else {
          _modifiedController.jumpTo(modOffset);
        }
      }
    } catch (_) {
      // ignore controller exceptions
    } finally {
      _isSyncing = false;
    }
  }

  bool _isIndexCurrentInOriginal(int index) {
    final idx = widget.currentDiffIndex;
    return idx != null &&
        idx >= 0 &&
        idx < widget.diff.originalDiffLines.length &&
        widget.diff.originalDiffLines[idx] == index;
  }

  bool _isIndexCurrentInModified(int index) {
    final idx = widget.currentDiffIndex;
    return idx != null &&
        idx >= 0 &&
        idx < widget.diff.modifiedDiffLines.length &&
        widget.diff.modifiedDiffLines[idx] == index;
  }

  @override
  Widget build(BuildContext context) {
    final diff = widget.diff;
    final changesCount = diff.changeCount ?? diff.diffIndices.length;

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 1100,
          maxHeight: _maxPaneHeight,
        ),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              // Original card
              Expanded(
                child: Card(
                  elevation: 6,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  clipBehavior: Clip.hardEdge,
                  child: Column(
                    children: [
                      // header
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.history, size: 18),
                            const SizedBox(width: 8),
                            const Text('Original',
                                style: TextStyle(fontWeight: FontWeight.w600)),
                            const Spacer(),
                            Text('$changesCount changes',
                                style: TextStyle(
                                    color: Colors.grey[600], fontSize: 12)),
                          ],
                        ),
                      ),

                      // code area (internal scroll)
                      Expanded(
                        child: Scrollbar(
                          controller: _originalController,
                          thumbVisibility: true,
                          child: ListView.builder(
                            controller: _originalController,
                            itemCount: diff.originalLines.length,
                            itemExtent: _lineHeight,
                            physics: const ClampingScrollPhysics(),
                            padding: const EdgeInsets.symmetric(
                                vertical: _itemVerticalPadding, horizontal: 8),
                            itemBuilder: (context, index) {
                              final line = diff.originalLines[index];
                              final isDiff =
                                  diff.originalDiffLines.contains(index);
                              final isCurrent =
                                  _isIndexCurrentInOriginal(index);

                              return AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                decoration: BoxDecoration(
                                  color: isCurrent
                                      ? Colors.blue.withOpacity(0.14)
                                      : (isDiff
                                          ? Colors.red.withOpacity(0.06)
                                          : Colors.transparent),
                                  borderRadius: isCurrent
                                      ? BorderRadius.circular(8)
                                      : BorderRadius.zero,
                                  border: isCurrent
                                      ? Border.all(color: Colors.blue, width: 2)
                                      : null,
                                ),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: _itemVerticalPadding),
                                margin: const EdgeInsets.symmetric(
                                    vertical: _itemVerticalMargin / 2),
                                child: Row(
                                  children: [
                                    SizedBox(
                                      width: 48,
                                      child: Text(
                                        '${index + 1}',
                                        style: TextStyle(
                                            color: isDiff
                                                ? Colors.red
                                                : Colors.grey[600],
                                            fontFamily: 'monospace'),
                                      ),
                                    ),
                                    Expanded(
                                      child: SelectableText.rich(
                                        TextSpan(
                                            children:
                                                GCodeHighlighter.highlight(
                                                    line)),
                                        style: const TextStyle(
                                            fontFamily: 'monospace',
                                            height: 1.15),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 12),

              // Modified card
              Expanded(
                child: Card(
                  elevation: 6,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  clipBehavior: Clip.hardEdge,
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.edit, size: 18),
                            const SizedBox(width: 8),
                            const Text('Modified',
                                style: TextStyle(fontWeight: FontWeight.w600)),
                            const Spacer(),
                            Text(
                              widget.currentDiffIndex == null
                                  ? ''
                                  : 'Change ${widget.currentDiffIndex! + 1}',
                              style: TextStyle(
                                  color: Colors.grey[600], fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Scrollbar(
                          controller: _modifiedController,
                          thumbVisibility: true,
                          child: ListView.builder(
                            controller: _modifiedController,
                            itemCount: diff.modifiedLines.length,
                            itemExtent: _lineHeight,
                            physics: const ClampingScrollPhysics(),
                            padding: const EdgeInsets.symmetric(
                                vertical: _itemVerticalPadding, horizontal: 8),
                            itemBuilder: (context, index) {
                              final line = diff.modifiedLines[index];
                              final isDiff =
                                  diff.modifiedDiffLines.contains(index);
                              final isCurrent =
                                  _isIndexCurrentInModified(index);

                              return AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                decoration: BoxDecoration(
                                  color: isCurrent
                                      ? Colors.blue.withOpacity(0.14)
                                      : (isDiff
                                          ? Colors.green.withOpacity(0.06)
                                          : Colors.transparent),
                                  borderRadius: isCurrent
                                      ? BorderRadius.circular(8)
                                      : BorderRadius.zero,
                                  border: isCurrent
                                      ? Border.all(color: Colors.blue, width: 2)
                                      : null,
                                ),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: _itemVerticalPadding),
                                margin: const EdgeInsets.symmetric(
                                    vertical: _itemVerticalMargin / 2),
                                child: Row(
                                  children: [
                                    SizedBox(
                                      width: 48,
                                      child: Text(
                                        '${index + 1}',
                                        style: TextStyle(
                                            color: isDiff
                                                ? Colors.green
                                                : Colors.grey[600],
                                            fontFamily: 'monospace'),
                                      ),
                                    ),
                                    Expanded(
                                      child: SelectableText.rich(
                                        TextSpan(
                                            children:
                                                GCodeHighlighter.highlight(
                                                    line)),
                                        style: const TextStyle(
                                            fontFamily: 'monospace',
                                            height: 1.15),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
