import 'package:flutter/material.dart';
import 'package:test_gcode/core/utils/ansi_parser.dart';
import 'package:test_gcode/presentation/features/gcode_diff/view/widgets/diff_viewer.dart';

/// Виджет для отображения сравнения G-кода из API
/// Показывает две панели: оригинальный и измененный код с подсветкой различий
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
    return Row(
      children: [
        Expanded(
          child: Column(
            children: [
              Text('Original Code', style: Theme.of(context).textTheme.titleMedium),
              Expanded(
                child: SingleChildScrollView(
                  child: Text(oldCode),
                ),
              ),
            ],
          ),
        ),
        VerticalDivider(width: 1),
        Expanded(
          child: Column(
            children: [
              Text('Modified Code', style: Theme.of(context).textTheme.titleMedium),
              Expanded(
                child: SingleChildScrollView(
                  child: Text(newCode),
                ),
              ),
            ],
          ),
        ),
        VerticalDivider(width: 1),
        Expanded(
          child: Column(
            children: [
              Text('Differences', style: Theme.of(context).textTheme.titleMedium),
              Expanded(
                child: DiffViewer(
                  diffLines: AnsiDiffParser.parseDiff(differences),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}