import 'package:flutter/material.dart';
import 'package:test_gcode/core/utils/gcode_highlighter.dart';
import 'package:test_gcode/domain/entities/gcode_diff.dart';

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
  static const double lineHeight = 20.0;

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

    // После рендера можно подвинуться к текущему индексу, если он задан
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.currentDiffIndex != null) {
        _scrollToCurrentIndex(widget.currentDiffIndex!);
      }
    });
  }

  @override
  void didUpdateWidget(covariant DiffPane oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Если поменялся diff (новые строки) — можно скорректировать позиции
    if (oldWidget.diff != widget.diff) {
      // Убедимся, что офсеты не превышают максимумов
      _clampControllersToMax();
    }

    // Если изменился currentDiffIndex — прокручиваем обе панели к соответствующим строкам
    if (widget.currentDiffIndex != null &&
        widget.currentDiffIndex != oldWidget.currentDiffIndex) {
      _scrollToCurrentIndex(widget.currentDiffIndex!);
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
    if (!source.hasClients) return;

    // Рассчитываем индекс видимой строки у источника
    final currentLine = (source.offset / lineHeight).round();

    // Целевая позиция в пикселях для другой панели
    final targetOffset = (currentLine * lineHeight).clamp(
      0.0,
      target.hasClients ? target.position.maxScrollExtent : 0.0,
    );

    if (!target.hasClients) return;

    // Если разница небольшая, пропускаем (чтобы не дергать каждый пиксель)
    if ((target.offset - targetOffset).abs() > 1.0) {
      _isSyncing = true;
      // Быстрый jump (можно заменить на animateTo с duration для плавности)
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

  void _scrollToCurrentIndex(int diffIndex) {
    // Получаем номера строк в оригинальной и модифицированной панелях,
    // соответствующие текущему индексу изменения. Если нет — используем diffIndex как fallback.
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

    // Если один из номеров не найден, используем diffIndex как приблизительный индекс строки
    if (origLine < 0 && widget.diff.originalLines.isNotEmpty) {
      origLine = diffIndex.clamp(0, widget.diff.originalLines.length - 1);
    }
    if (modLine < 0 && widget.diff.modifiedLines.isNotEmpty) {
      modLine = diffIndex.clamp(0, widget.diff.modifiedLines.length - 1);
    }

    final origOffset = (origLine * lineHeight).clamp(
      0.0,
      _originalController.hasClients
          ? _originalController.position.maxScrollExtent
          : 0.0,
    );
    final modOffset = (modLine * lineHeight).clamp(
      0.0,
      _modifiedController.hasClients
          ? _modifiedController.position.maxScrollExtent
          : 0.0,
    );

    // Чтобы строки с одинаковым индексом были напротив — используем одинаковый индекс для обеих панелей.
    // Подход: берем минимальный индекс, который есть в обеих панелях (если хочется, можно брать max).
    final targetIndex = [
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

    final targetOrigOffset = (targetIndex * lineHeight).clamp(
      0.0,
      _originalController.hasClients
          ? _originalController.position.maxScrollExtent
          : 0.0,
    );
    final targetModOffset = (targetIndex * lineHeight).clamp(
      0.0,
      _modifiedController.hasClients
          ? _modifiedController.position.maxScrollExtent
          : 0.0,
    );

    // Прокручиваем обе панели (без зацикливания)
    if (_originalController.hasClients) {
      _isSyncing = true;
      _originalController.jumpTo(targetOrigOffset);
      _isSyncing = false;
    }
    if (_modifiedController.hasClients) {
      _isSyncing = true;
      _modifiedController.jumpTo(targetModOffset);
      _isSyncing = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final diff = widget.diff;

    return Row(
      children: [
        // Left pane - Original
        Expanded(
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                color: Colors.grey[100],
                child: const Text(
                  'ORIGINAL',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  controller: _originalController,
                  itemCount: diff.originalLines.length,
                  itemExtent: lineHeight,
                  itemBuilder: (context, index) {
                    final line = diff.originalLines[index];
                    final isDiff = diff.originalDiffLines.contains(index);
                    final isCurrent = widget.currentDiffIndex != null &&
                        widget.currentDiffIndex! >= 0 &&
                        widget.currentDiffIndex! <
                            diff.originalDiffLines.length &&
                        diff.originalDiffLines[widget.currentDiffIndex!] ==
                            index;

                    return Container(
                      decoration: BoxDecoration(
                        border: isCurrent
                            ? Border.all(color: Colors.blue, width: 2)
                            : null,
                        color: isCurrent
                            ? Colors.blue.withOpacity(0.15)
                            : (isDiff
                                ? Colors.red.withOpacity(0.08)
                                : Colors.transparent),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 40,
                            child: Text(
                              '${index + 1}',
                              style: TextStyle(
                                color: isDiff ? Colors.red : Colors.grey,
                              ),
                            ),
                          ),
                          Expanded(
                            child: SelectableText.rich(
                              TextSpan(
                                children: GCodeHighlighter.highlight(line),
                                style: TextStyle(
                                  color: isDiff ? Colors.red : null,
                                ),
                              ),
                              style: const TextStyle(fontFamily: 'monospace'),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),

        // Divider
        Container(
          width: 1,
          color: Colors.grey[300],
        ),

        // Right pane - Modified
        Expanded(
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                color: Colors.grey[100],
                child: const Text(
                  'MODIFIED',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  controller: _modifiedController,
                  itemCount: diff.modifiedLines.length,
                  itemExtent: lineHeight,
                  itemBuilder: (context, index) {
                    final line = diff.modifiedLines[index];
                    final isDiff = diff.modifiedDiffLines.contains(index);
                    final isCurrent = widget.currentDiffIndex != null &&
                        widget.currentDiffIndex! >= 0 &&
                        widget.currentDiffIndex! <
                            diff.modifiedDiffLines.length &&
                        diff.modifiedDiffLines[widget.currentDiffIndex!] ==
                            index;

                    return Container(
                      decoration: BoxDecoration(
                        border: isCurrent
                            ? Border.all(color: Colors.blue, width: 2)
                            : null,
                        color: isCurrent
                            ? Colors.blue.withOpacity(0.15)
                            : (isDiff
                                ? Colors.green.withOpacity(0.08)
                                : Colors.transparent),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 40,
                            child: Text(
                              '${index + 1}',
                              style: TextStyle(
                                color: isDiff ? Colors.green : Colors.grey,
                              ),
                            ),
                          ),
                          Expanded(
                            child: SelectableText.rich(
                              TextSpan(
                                children: GCodeHighlighter.highlight(line),
                                style: TextStyle(
                                  color: isDiff ? Colors.green : null,
                                ),
                              ),
                              style: const TextStyle(fontFamily: 'monospace'),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
