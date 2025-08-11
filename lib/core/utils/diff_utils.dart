import 'dart:math';
import 'package:diff_match_patch/diff_match_patch.dart';
import 'package:test_gcode/core/utils/diff_types.dart';

List<Diff> computeDiffs(String original, String modified) {
  if (original == modified) {
    return [Diff(DIFF_EQUAL, original)];
  }
  
  final dmp = DiffMatchPatch();
  
  // Нормализация GCode перед сравнением
  final normalizedOriginal = _normalizeGCode(original);
  final normalizedModified = _normalizeGCode(modified);
  
  final diffs = dmp.diff(normalizedOriginal, normalizedModified);
  dmp.diffCleanupSemantic(diffs);
  
  return diffs;
}

String _normalizeGCode(String code) {
  final lines = code.split('\n');
  final normalizedLines = <String>[];
  
  for (var line in lines) {
    // Удаляем комментарии
    line = line.replaceAll(RegExp(r';.*|\(.*\)'), '');
    // Приводим к верхнему регистру
    line = line.toUpperCase();
    // Заменяем множественные пробелы на один
    line = line.replaceAll(RegExp(r'\s+'), ' ');
    // Удаляем пробелы в начале/конце
    line = line.trim();
    // Округляем числа до 3 знаков
    line = line.replaceAllMapped(
      RegExp(r'([XYZEFS])(-?\d+\.?\d*)'),
      (m) => '${m.group(1)}${_roundNumber(m.group(2)!)}'
    );
    
    if (line.isNotEmpty) {
      normalizedLines.add(line);
    }
  }
  
  return normalizedLines.join('\n');
}

String _roundNumber(String numStr) {
  try {
    final num = double.parse(numStr);
    if (num % 1 == 0) {
      return num.toInt().toString(); // Целое число
    } else {
      return num.toStringAsFixed(3); // Дробное число
    }
  } catch (e) {
    return numStr; // Если не число
  }
}

List<DiffLine> parseDiffLines(List<Diff> diffs) {
  final lines = <DiffLine>[];
  int leftLineNum = 1;
  int rightLineNum = 1;
  StringBuffer leftBuffer = StringBuffer();
  StringBuffer rightBuffer = StringBuffer();

  for (final diff in diffs) {
    final text = diff.text;
    switch (diff.operation) {
      case DIFF_INSERT:
        rightBuffer.write(text);
        break;
      case DIFF_DELETE:
        leftBuffer.write(text);
        break;
      case DIFF_EQUAL:
        leftBuffer.write(text);
        rightBuffer.write(text);
        break;
    }
  }

  final leftLines = leftBuffer.toString().split('\n');
  final rightLines = rightBuffer.toString().split('\n');
  final maxLines = max(leftLines.length, rightLines.length);

  for (int i = 0; i < maxLines; i++) {
    final leftText = i < leftLines.length ? leftLines[i].trim() : '';
    final rightText = i < rightLines.length ? rightLines[i].trim() : '';

    if (leftText.isEmpty && rightText.isNotEmpty) {
      // Добавленная строка
      lines.add(DiffLine(
        leftNumber: null,
        rightNumber: rightLineNum++,
        leftText: '',
        rightText: rightText,
        type: DiffType.added,
      ));
    } else if (rightText.isEmpty && leftText.isNotEmpty) {
      // Удаленная строка
      lines.add(DiffLine(
        leftNumber: leftLineNum++,
        rightNumber: null,
        leftText: leftText,
        rightText: '',
        type: DiffType.removed,
      ));
    } else if (leftText == rightText) {
      // Неизмененная строка
      lines.add(DiffLine(
        leftNumber: leftLineNum++,
        rightNumber: rightLineNum++,
        leftText: leftText,
        rightText: rightText,
        type: DiffType.equal,
      ));
    } else {
      // Измененная строка
      lines.add(DiffLine(
        leftNumber: leftLineNum++,
        rightNumber: rightLineNum++,
        leftText: leftText,
        rightText: rightText,
        type: DiffType.modified,
      ));
    }
  }

  return lines;
}

// Удалено, так как новая реализация parseDiffLines
// сразу определяет измененные строки
