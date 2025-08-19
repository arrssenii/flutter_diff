import 'package:flutter/material.dart';
import 'package:test_gcode/core/utils/ansi_parser.dart';
import 'package:test_gcode/core/utils/gcode_highlighter.dart';
import 'package:test_gcode/presentation/features/gcode_diff/view/widgets/diff_viewer.dart';

/// Виджет для отображения сравнения G-кода из API
/// Показывает две панели: оригинальный и измененный код с подсветкой различий
class ApiDiffPane extends StatefulWidget {
  final String oldCode;
  final String newCode;
  final String differences;

  const ApiDiffPane({
    super.key,
    required this.oldCode,
    required this.newCode,
    required this.differences,
  });

  @override
  State<ApiDiffPane> createState() => _ApiDiffPaneState();
}

class _ApiDiffPaneState extends State<ApiDiffPane> {
  final ScrollController _originalScrollController = ScrollController();
  final ScrollController _modifiedScrollController = ScrollController();
  final ScrollController _diffScrollController = ScrollController();

  static const double lineHeight = 20.0;
  bool _isSyncing = false;

  @override
  void initState() {
    super.initState();
    _originalScrollController
        .addListener(() => _syncScroll(_originalScrollController));
    _modifiedScrollController
        .addListener(() => _syncScroll(_modifiedScrollController));
  }

  @override
  void dispose() {
    _originalScrollController.dispose();
    _modifiedScrollController.dispose();
    _diffScrollController.dispose();
    super.dispose();
  }

  void _syncScroll(ScrollController source) {
    if (_isSyncing) return;
    if (!source.hasClients) return;

    final currentLine = (source.offset / lineHeight).round();

    // Синхронизируем другую панель
    final targetController = source == _originalScrollController
        ? _modifiedScrollController
        : _originalScrollController;
    if (targetController.hasClients) {
      final targetOffset = (currentLine * lineHeight)
          .clamp(0.0, targetController.position.maxScrollExtent);
      if ((targetController.offset - targetOffset).abs() > 1.0) {
        _isSyncing = true;
        targetController.jumpTo(targetOffset);
        _isSyncing = false;
      }
    }

    // Синхронизируем панель различий
    if (_diffScrollController.hasClients) {
      final diffOffset = (currentLine * lineHeight)
          .clamp(0.0, _diffScrollController.position.maxScrollExtent);
      if ((_diffScrollController.offset - diffOffset).abs() > 1.0) {
        _isSyncing = true;
        _diffScrollController.jumpTo(diffOffset);
        _isSyncing = false;
      }
    }
  }

  late final List<String> oldLines = widget.oldCode.split('\n');
  late final List<String> newLines = widget.newCode.split('\n');

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            children: [
              Text('Original Code',
                  style: Theme.of(context).textTheme.titleMedium),
              Expanded(
                child: ListView.builder(
                  controller: _originalScrollController,
                  itemCount: oldLines.length,
                  itemExtent: lineHeight,
                  itemBuilder: (context, index) =>
                      _buildCodeLine(oldLines[index], index, true),
                  cacheExtent: 1000,
                  addAutomaticKeepAlives: true,
                ),
              ),
            ],
          ),
        ),
        VerticalDivider(width: 1),
        Expanded(
          child: Column(
            children: [
              Text('Modified Code',
                  style: Theme.of(context).textTheme.titleMedium),
              Expanded(
                child: ListView.builder(
                  controller: _modifiedScrollController,
                  itemCount: newLines.length,
                  itemExtent: lineHeight,
                  itemBuilder: (context, index) =>
                      _buildCodeLine(newLines[index], index, false),
                  cacheExtent: 1000,
                  addAutomaticKeepAlives: true,
                ),
              ),
            ],
          ),
        ),
        VerticalDivider(width: 1),
        Expanded(
          child: Column(
            children: [
              Text('Differences',
                  style: Theme.of(context).textTheme.titleMedium),
              Expanded(
                child: DiffViewer(
                  diffLines: AnsiDiffParser.parseDiff(widget.differences),
                  scrollController: _diffScrollController,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCodeLine(String line, int index, bool isOld) {
    return Container(
      height: lineHeight,
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
            child: SelectableText.rich(
              TextSpan(
                children: GCodeHighlighter.highlight(line),
                style: TextStyle(fontFamily: 'monospace'),
              ),
              style: const TextStyle(height: 1.0),
            ),
          ),
        ],
      ),
    );
  }
}
