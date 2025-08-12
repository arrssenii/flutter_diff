import 'package:flutter/material.dart';
import 'package:test_gcode/core/utils/gcode_highlighter.dart';

class ApiDiffPane extends StatelessWidget {
  final String oldCode;
  final String newCode;
  final String differences;

  const ApiDiffPane({
    Key? key,
    required this.oldCode,
    required this.newCode,
    required this.differences,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final oldLines = oldCode.split('\n');
    final newLines = newCode.split('\n');

    return Row(
      children: [
        // Left pane - Old version
        Expanded(
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                color: Colors.grey[100],
                child: const Text(
                  'OLD VERSION',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: oldLines.length,
                  itemBuilder: (context, index) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      height: 20,
                      child: Row(
                        children: [
                          SizedBox(
                            width: 40,
                            child: Text(
                              '${index + 1}',
                              style: const TextStyle(color: Colors.grey),
                            ),
                          ),
                          Expanded(
                            child: SelectableText.rich(
                              TextSpan(
                                children: GCodeHighlighter.highlight(oldLines[index]),
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
        Container(width: 1, color: Colors.grey[300]),

        // Right pane - New version
        Expanded(
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                color: Colors.grey[100],
                child: const Text(
                  'NEW VERSION',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: newLines.length,
                  itemBuilder: (context, index) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      height: 20,
                      child: Row(
                        children: [
                          SizedBox(
                            width: 40,
                            child: Text(
                              '${index + 1}',
                              style: const TextStyle(color: Colors.grey),
                            ),
                          ),
                          Expanded(
                            child: SelectableText.rich(
                              TextSpan(
                                children: GCodeHighlighter.highlight(newLines[index]),
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