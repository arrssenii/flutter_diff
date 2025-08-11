import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:pretty_diff_text/pretty_diff_text.dart';
import 'package:diff_match_patch/diff_match_patch.dart';
import 'package:test_gcode/app/features/gcode_diff/models/gcode_diff_model.dart';
import 'package:test_gcode/core/utils/gcode_highlighter.dart' show GCodeHighlighter;

class DiffPane extends StatelessWidget {
  final String oldText;
  final String newText;
  final bool normalizeGCode;
  final String leftTitle;
  final String rightTitle;
  final int? currentDiffIndex;

  const DiffPane({
    Key? key,
    required this.oldText,
    required this.newText,
    this.leftTitle = 'ORIGINAL',
    this.rightTitle = 'MODIFIED',
    this.normalizeGCode = true,
    this.currentDiffIndex,
  }) : super(key: key);

  String _normalize(String text) {
    if (!normalizeGCode) return text;
    
    final lines = text.split('\n');
    final normalized = <String>[];
    
    for (var line in lines) {
      line = line.replaceAll(RegExp(r';.*|\(.*\)'), '');
      line = line.toUpperCase();
      line = line.replaceAll(RegExp(r'\s+'), ' ').trim();
      if (line.isNotEmpty) normalized.add(line);
    }
    
    return normalized.join('\n');
  }

  @override
  Widget build(BuildContext context) {
    final normalizedOld = _normalize(oldText);
    final normalizedNew = _normalize(newText);
    
    // Создаем синхронизированные контроллеры прокрутки
    final leftScrollController = ScrollController();
    final rightScrollController = ScrollController();
    
    leftScrollController.addListener(() {
      rightScrollController.jumpTo(leftScrollController.offset);
    });
    
    return Column(
      children: [
        // Легенда цветов
        Container(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          color: Colors.grey[100],
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildLegendItem('Добавлено', Colors.green),
              _buildLegendItem('Удалено', Colors.red),
              _buildLegendItem('Не изменено', Colors.grey),
            ],
          ),
        ),
        // Заголовок панелей
        Container(
          padding: const EdgeInsets.all(8),
          color: Colors.grey[200],
          child: Row(
            children: [
              Expanded(
                child: Text(
                  leftTitle,
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: 13,
                    fontFamily: 'Roboto',
                  ),
                ),
              ),
              Container(width: 1, height: 24, color: Colors.grey[300]),
              Expanded(
                child: Text(
                  rightTitle,
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: 13,
                    fontFamily: 'Roboto',
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Row(
            children: [
              Expanded(
                child: ListView.builder(
                  controller: leftScrollController,
                  itemCount: normalizedOld.split('\n').length,
                  itemBuilder: (ctx, index) {
                    final line = normalizedOld.split('\n')[index];
                    final isDeleted = !normalizedNew.split('\n').contains(line);
                    
                    return SizedBox(
                      height: 24,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        color: isDeleted
                          ? const Color(0xFFFFE0E0)
                          : index % 2 == 0 ? Colors.white : Colors.grey[50],
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 40,
                              child: Text(
                                '${index + 1}',
                                style: const TextStyle(
                                  fontFamily: 'RobotoMono',
                                  fontSize: 12,
                                  height: 1.2,
                                ).copyWith(
                                  color: isDeleted ? Colors.red : Colors.grey,
                                ),
                              ),
                            ),
                            Expanded(
                              child: GCodeHighlighter(
                                text: line,
                                baseStyle: const TextStyle(
                                  fontFamily: 'RobotoMono',
                                  fontSize: 12,
                                  height: 1.2,
                                ).copyWith(
                                  decoration: isDeleted ? TextDecoration.lineThrough : null,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    );
                  },
                ),
              ),
              Container(width: 1, color: Colors.grey[300]),
              Expanded(
                child: ListView.builder(
                  controller: rightScrollController,
                  itemCount: normalizedNew.split('\n').length,
                  itemBuilder: (ctx, index) {
                    final oldLines = normalizedOld.split('\n');
                    final newLines = normalizedNew.split('\n');
                    final line = newLines[index];
                    final isAdded = !oldLines.contains(line);
                    // Для правой панели isDeleted не применяется
                    final isModified = oldLines.length > index &&
                        oldLines[index] != line &&
                        !isAdded;
                        
                    final isCurrentDiff = (isAdded || isModified) &&
                        currentDiffIndex == index;
                    
                    return SizedBox(
                      height: 24,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(
                          color: isCurrentDiff
                            ? Colors.blue.withOpacity(0.2)
                            : isAdded
                              ? const Color(0xFFE0FFE0) // Зеленый для добавленных
                              : isModified
                                ? const Color(0xFFFFFFE0) // Желтый для измененных
                                : index % 2 == 0 ? Colors.white : Colors.grey[50],
                          border: isCurrentDiff
                            ? Border.all(
                                color: Colors.blue,
                                width: 2,
                              )
                            : null,
                          borderRadius: isCurrentDiff
                            ? BorderRadius.circular(4)
                            : null,
                        ),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 40,
                              child: Text(
                                '${index + 1}',
                                style: TextStyle(
                                  fontFamily: 'RobotoMono',
                                  fontSize: 12,
                                  color: isAdded
                                    ? Colors.green
                                    : Colors.grey,
                                ),
                              ),
                            ),
                            Expanded(
                              child: GCodeHighlighter(
                                text: newLines[index],
                                baseStyle: const TextStyle(
                                  fontFamily: 'RobotoMono',
                                  fontSize: 12,
                                  height: 1.2,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
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

  Widget _buildHighlightedLine(DiffLine line, {required bool isLeftPane}) {
    String? lineNumber = isLeftPane ? line.leftNumber?.toString() : line.rightNumber?.toString();
    String displayText = isLeftPane ? line.leftText : line.rightText;

    print('Highlighting line: ${lineNumber ?? "empty"}'); // Debug output

    return _buildLineContent(
      line: line,
      isLeftPane: isLeftPane,
      bgColor: Colors.blue.withOpacity(0.3), // More visible highlight
      lineNumberColor: Colors.blue[900]!, // Darker number color
      lineNumber: lineNumber,
      displayText: displayText,
    );
  }

  Widget _buildLineContent({
    required DiffLine line,
    required bool isLeftPane,
    required Color bgColor,
    required Color lineNumberColor,
    required String? lineNumber,
    required String displayText,
  }) {
    return Container(
      height: 24, // Фиксированная высота
      constraints: const BoxConstraints(
        minHeight: 24,
        maxHeight: 24,
      ),
      color: bgColor,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 40,
            padding: const EdgeInsets.only(right: 8),
            constraints: const BoxConstraints(
              minWidth: 40,
              maxWidth: 40,
            ),
            child: Text(
              lineNumber ?? '',
              textAlign: TextAlign.right,
              style: TextStyle(
                color: lineNumberColor,
                fontSize: 12,
                fontFamily: 'RobotoMono',
                height: 1.2,
              ),
            ),
          ),
          Expanded(
            child: Text(
              displayText,
              style: const TextStyle(
                fontFamily: 'RobotoMono',
                fontSize: 12,
                height: 1.2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLine(DiffLine line, {required bool isLeftPane, required bool isCurrent}) {
    print('Building line: ${line.leftNumber ?? line.rightNumber}, isCurrent: $isCurrent'); // Debug
    
    if (isCurrent) {
      print('Current line detected!'); // Debug
      return _buildHighlightedLine(line, isLeftPane: isLeftPane);
    
      bool _isLineChanged(int index, List<String> lines, List<String> otherLines, List<Diff> diffs) {
        if (index >= lines.length) return false;
        
        final line = lines[index];
        if (line.isEmpty) return false;
        
        // Проверяем, есть ли эта строка в другой версии
        if (!otherLines.contains(line)) return true;
        
        // Проверяем изменения через diffs
        for (final diff in diffs) {
          if (diff.text.contains(line)) {
            return diff.operation != DIFF_EQUAL;
          }
        }
        
        return false;
      }
    }

    Color bgColor = Colors.transparent;
    Color lineNumberColor = Colors.grey[600]!;
    String? lineNumber;
    String displayText;

    if (isLeftPane) {
      lineNumber = line.leftNumber?.toString();
      displayText = line.leftText;
      switch (line.type) {
        case DiffType.removed:
          bgColor = const Color(0xFFFFE0E0);
          lineNumberColor = Colors.red[700]!;
          break;
        case DiffType.modified:
          bgColor = const Color(0xFFE0FFE0);
          lineNumberColor = Colors.red[700]!;
          break;
        default:
          if (line.leftNumber == null) {
            return SizedBox(
              height: 24,
              child: Container(
                color: line.type == DiffType.removed
                  ? const Color(0xFFFFE0E0).withOpacity(0.5)
                  : Colors.transparent,
              ),
            );
          }
      }
    } else {
      lineNumber = line.rightNumber?.toString();
      displayText = line.rightText;
      switch (line.type) {
        case DiffType.added:
          bgColor = const Color(0xFFE0FFE0);
          lineNumberColor = Colors.green[700]!;
          break;
        case DiffType.modified:
          bgColor = const Color(0xFFE0FFE0);
          lineNumberColor = Colors.green[700]!;
          break;
        default:
          if (line.rightNumber == null) {
            return SizedBox(
              height: 24,
              child: Container(
                color: line.type == DiffType.added
                  ? const Color(0xFFE0FFE0).withOpacity(0.5)
                  : Colors.transparent,
              ),
            );
          }
      }
    }

    if (displayText.isEmpty) {
      return SizedBox(
        height: 24,
        child: Container(
          color: isLeftPane
            ? line.type == DiffType.removed
              ? const Color(0xFFFFE0E0).withOpacity(0.5)
              : Colors.transparent
            : line.type == DiffType.added
              ? const Color(0xFFE0FFE0).withOpacity(0.5)
              : Colors.transparent,
        ),
      );
    }

    return _buildLineContent(
      line: line,
      isLeftPane: isLeftPane,
      bgColor: bgColor,
      lineNumberColor: lineNumberColor,
      lineNumber: lineNumber,
      displayText: displayText,
    );
  }
  
  Widget _buildLegendItem(String text, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          margin: const EdgeInsets.only(right: 4),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        Text(
          text,
          style: const TextStyle(
            fontSize: 12,
            fontFamily: 'Roboto',
          ),
        ),
      ],
    );
  }
}
