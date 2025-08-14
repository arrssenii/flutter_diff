import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:test_gcode/core/utils/ansi_parser.dart';

class DiffViewer extends StatelessWidget {
  final List<DiffLine> diffLines;
  final ScrollController? scrollController;

  const DiffViewer({
    super.key,
    required this.diffLines,
    this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    if (kDebugMode) {
      debugPrint('Rendering ${diffLines.length} diff lines');
      debugPrint('Added: ${diffLines.where((l) => l.type == DiffType.added).length}');
      debugPrint('Removed: ${diffLines.where((l) => l.type == DiffType.removed).length}');
      debugPrint('Modified: ${diffLines.where((l) => l.type == DiffType.modified).length}');
    }
    return ListView.builder(
      controller: scrollController,
      itemCount: diffLines.length,
      itemBuilder: (context, index) {
        final line = diffLines[index];
        Color? backgroundColor;
        if (line.type == DiffType.added) {
          backgroundColor = Colors.green.withOpacity(0.2);
        } else if (line.type == DiffType.removed) {
          backgroundColor = Colors.red.withOpacity(0.2);
        } else if (line.type == DiffType.modified) {
          backgroundColor = Colors.yellow.withOpacity(0.2);
        }

        return Container(
          height: 20.0,
          color: backgroundColor,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 40,
                child: Text(
                  '${index + 1}',
                  style: const TextStyle(
                    color: Colors.grey,
                    height: 1.0,
                  ),
                ),
              ),
              Expanded(
                child: SelectableText(
                  line.text,
                  style: TextStyle(
                    color: line.type == DiffType.removed
                      ? Colors.red
                      : line.type == DiffType.modified
                        ? Colors.orange
                        : Colors.black,
                    height: 1.0,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}