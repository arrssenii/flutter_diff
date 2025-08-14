// Парсер ANSI-разметки для сравнения G-кода
// Обрабатывает цветовую разметку diff-а (добавленные/удаленные/измененные строки)
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class AnsiDiffParser {
  /// Парсит текст с ANSI-разметкой в список строк с указанием типа изменения
  /// [diffText] - входной текст с ANSI цветовыми кодами
  /// Возвращает List<DiffLine> с разобранными строками
  static List<DiffLine> parseDiff(String diffText) {
    try {
      if (diffText.isEmpty) {
        if (kDebugMode) {
          debugPrint('Empty diff text received - returning empty line');
        }
        return [DiffLine(
          text: '',
          type: DiffType.unchanged,
          originalText: '',
        )];
      }

      if (kDebugMode) {
        debugPrint('Parsing ANSI diff, length: ${diffText.length}');
        if (diffText.isNotEmpty) {
          debugPrint('First 100 chars: ${diffText.length > 100 ? diffText.substring(0, 100) : diffText}');
        }
      }

      final lines = diffText.split('\n');
      final result = <DiffLine>[];
      final redRegex = RegExp(r'\u001B\[31m(.*?)\u001B\[0m');
      final greenRegex = RegExp(r'\u001B\[32m(.*?)\u001B\[0m');
      final yellowRegex = RegExp(r'\u001B\[33m(.*?)\u001B\[0m');

      for (final line in lines) {
        if (greenRegex.hasMatch(line)) {
          final match = greenRegex.firstMatch(line)!;
          result.add(DiffLine(
            text: match.group(1)!,
            type: DiffType.added,
            originalText: line.replaceAll(greenRegex, match.group(1)!),
          ));
        } else if (redRegex.hasMatch(line)) {
          final match = redRegex.firstMatch(line)!;
          result.add(DiffLine(
            text: match.group(1)!,
            type: DiffType.removed,
            originalText: line.replaceAll(redRegex, match.group(1)!),
          ));
        } else if (yellowRegex.hasMatch(line)) {
          final match = yellowRegex.firstMatch(line)!;
          result.add(DiffLine(
            text: match.group(1)!,
            type: DiffType.modified,
            originalText: line.replaceAll(yellowRegex, match.group(1)!),
          ));
        } else {
          result.add(DiffLine(
            text: line,
            type: DiffType.unchanged,
            originalText: line,
          ));
        }
      }

      if (kDebugMode) {
        debugPrint('Parsed ${result.length} diff lines');
        debugPrint('Added: ${result.where((l) => l.type == DiffType.added).length}');
        debugPrint('Removed: ${result.where((l) => l.type == DiffType.removed).length}');
        debugPrint('Modified: ${result.where((l) => l.type == DiffType.modified).length}');
      }

      return result;
    } catch (e) {
      debugPrint('Error parsing ANSI diff: $e');
      return [DiffLine(
        text: diffText,
        type: DiffType.unchanged,
        originalText: diffText,
      )];
    }
  }
}

/// Класс представляющий одну строку diff-а с указанием типа изменения
class DiffLine {
  final String text;
  final DiffType type;
  final String originalText;

  DiffLine({
    required this.text,
    required this.type,
    required this.originalText,
  });
}

/// Типы изменений в строках G-кода
enum DiffType {
  unchanged,
  added,
  removed,
  modified,
}
