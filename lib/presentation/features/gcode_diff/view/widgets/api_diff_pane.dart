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

  @override
  void initState() {
    super.initState();
    _originalScrollController.addListener(() => _syncScroll(_originalScrollController));
    _modifiedScrollController.addListener(() => _syncScroll(_modifiedScrollController));
  }

  @override
  void dispose() {
    _originalScrollController.dispose();
    _modifiedScrollController.dispose();
    _diffScrollController.dispose();
    super.dispose();
  }

  void _syncScroll(ScrollController source) {
    if (!source.hasClients) return;

    // Рассчитываем номер текущей строки
    final lineHeight = 20.0;
    final currentLine = (source.offset / lineHeight).round();

    // Синхронизация между оригиналом и изменениями
    if (source == _originalScrollController || source == _modifiedScrollController) {
      final targetController = source == _originalScrollController
          ? _modifiedScrollController
          : _originalScrollController;

      if (targetController.hasClients) {
        final targetOffset = currentLine * lineHeight;
        if ((targetController.offset - targetOffset).abs() > 1) {
          targetController.jumpTo(targetOffset.clamp(0, targetController.position.maxScrollExtent));
        }
      }
    }

    // Синхронизация с панелью различий
    if (_diffScrollController.hasClients) {
      final diffOffset = currentLine * lineHeight;
      if ((_diffScrollController.offset - diffOffset).abs() > 1) {
        _diffScrollController.jumpTo(diffOffset.clamp(0, _diffScrollController.position.maxScrollExtent));
      }
    }
  }
  late final List<String> oldLines = widget.oldCode.split('\n');
  late final List<String> newLines = widget.newCode.split('\n');
  final _oldLineCache = <int, TextSpan>{};
  final _newLineCache = <int, TextSpan>{};

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            children: [
              Text('Original Code', style: Theme.of(context).textTheme.titleMedium),
              Expanded(
                child: ListView.builder(
                  controller: _originalScrollController,
                  itemCount: oldLines.length,
                  itemBuilder: (context, index) => _buildCodeLine(oldLines[index], index, true),
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
              Text('Modified Code', style: Theme.of(context).textTheme.titleMedium),
              Expanded(
                child: ListView.builder(
                  controller: _modifiedScrollController,
                  itemCount: newLines.length,
                  itemBuilder: (context, index) => _buildCodeLine(newLines[index], index, false),
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
              Text('Differences', style: Theme.of(context).textTheme.titleMedium),
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

  static const double lineHeight = 20.0;
  
  Widget _buildCodeLine(String line, int index, bool isOld) {
    final cache = isOld ? _oldLineCache : _newLineCache;
    
    if (!cache.containsKey(index)) {
      cache[index] = TextSpan(
        children: GCodeHighlighter.highlight(line),
        style: TextStyle(fontFamily: 'monospace'),
      );
    }
    
    return Container(
      height: lineHeight,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 40,
            child: Text(
              '${index + 1}',
              style: TextStyle(
                color: Colors.grey,
                fontFamily: 'monospace',
                height: 1.0,
              ),
            ),
          ),
          Expanded(
            child: SelectableText.rich(
              cache[index]!,
              style: TextStyle(height: 1.0),
            ),
          ),
        ],
      ),
    );
  }
}