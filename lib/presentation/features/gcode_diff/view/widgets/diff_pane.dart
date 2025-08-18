import 'package:flutter/material.dart';
import 'package:test_gcode/domain/entities/gcode_diff.dart';
import 'package:test_gcode/core/utils/gcode_highlighter.dart';

class DiffPane extends StatelessWidget {
  final GCodeDiff diff;
  final int? currentDiffIndex;

  const DiffPane({
    Key? key,
    required this.diff,
    this.currentDiffIndex,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
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
                  itemCount: diff.originalLines.length,
                  itemBuilder: (context, index) {
                    final line = diff.originalLines[index];
                    final isDiff = diff.originalDiffLines.contains(index);
                    final isCurrent = currentDiffIndex != null &&
                        currentDiffIndex! >= 0 &&
                        currentDiffIndex! < diff.originalDiffLines.length &&
                        diff.originalDiffLines[currentDiffIndex!] == index;

                    return Container(
                      decoration: BoxDecoration(
                        border: isCurrent
                            ? Border.all(
                                color: Colors.blue,
                                width:
                                    2) // Жирная синяя граница для текущего изменения
                            : null,
                        color: isCurrent
                            ? Colors.blue.withOpacity(
                                0.2) // Полупрозрачный синий фон для текущего изменения
                            : (isDiff
                                ? Colors.red.withOpacity(
                                    0.1) // Лёгкий красный фон для изменения
                                : Colors.transparent),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      height: 20,
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
                  itemCount: diff.modifiedLines.length,
                  itemBuilder: (context, index) {
                    final line = diff.modifiedLines[index];
                    final isDiff = diff.modifiedDiffLines.contains(index);
                    final isCurrent = currentDiffIndex != null &&
                        currentDiffIndex! >= 0 &&
                        currentDiffIndex! < diff.modifiedDiffLines.length &&
                        diff.modifiedDiffLines[currentDiffIndex!] == index;

                    return Container(
                      decoration: BoxDecoration(
                        border: isCurrent
                            ? Border.all(
                                color: Colors.blue,
                                width:
                                    2) // Жирная синяя граница для текущего изменения
                            : null,
                        color: isCurrent
                            ? Colors.blue.withOpacity(
                                0.2) // Полупрозрачный синий фон для текущего изменения
                            : (isDiff
                                ? Colors.green.withOpacity(
                                    0.1) // Лёгкий зелёный фон для изменения
                                : Colors.transparent),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      height: 20,
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
