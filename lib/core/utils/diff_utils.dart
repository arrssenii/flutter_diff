import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:diff_match_patch/diff_match_patch.dart';
import 'package:test_gcode/core/utils/diff_types.dart';

class DiffResult {
  final List<DiffLine> diffLines;
  final List<String> originalLines;
  final List<String> modifiedLines;
  final List<int> originalDiffLines;
  final List<int> modifiedDiffLines;
  final List<int> diffIndices;

  DiffResult({
    required this.diffLines,
    required this.originalLines,
    required this.modifiedLines,
    required this.originalDiffLines,
    required this.modifiedDiffLines,
    required this.diffIndices,
  });
}

DiffResult computeDiffResult(String original, String modified) {
  final originalLines = original.split('\n');
  final modifiedLines = modified.split('\n');
  
  final diffs = computeDiffs(original, modified);
  final diffLines = parseDiffLines(diffs);
  
  final originalDiffLines = <int>[];
  final modifiedDiffLines = <int>[];
  final diffIndices = <int>[];
  
  // Group consecutive changes
  int groupStart = -1;
  for (int i = 0; i < diffLines.length; i++) {
    final line = diffLines[i];
    if (line.type != DiffType.equal) {
      if (groupStart == -1) groupStart = i;
      
      if (line.type == DiffType.removed || line.type == DiffType.modified) {
        originalDiffLines.add(line.leftNumber! - 1);
      }
      if (line.type == DiffType.added || line.type == DiffType.modified) {
        modifiedDiffLines.add(line.rightNumber! - 1);
      }
    } else if (groupStart != -1) {
      diffIndices.add(groupStart);
      groupStart = -1;
    }
  }
  
  // Add last group if exists
  if (groupStart != -1) {
    diffIndices.add(groupStart);
  }
  
  debugPrint('Found ${originalDiffLines.length} differences in G-code');

  return DiffResult(
    diffLines: diffLines,
    originalLines: originalLines,
    modifiedLines: modifiedLines,
    originalDiffLines: originalDiffLines,
    modifiedDiffLines: modifiedDiffLines,
    diffIndices: originalDiffLines, // Use actual diff lines for navigation
  );
}

List<Diff> computeDiffs(String original, String modified) {
  if (original == modified) {
    return [Diff(DIFF_EQUAL, original)];
  }
  
  final dmp = DiffMatchPatch();
  final normalizedOriginal = _normalizeGCode(original);
  final normalizedModified = _normalizeGCode(modified);
  
  final diffs = dmp.diff(normalizedOriginal, normalizedModified);
  dmp.diffCleanupSemantic(diffs);
  
  return diffs;
}

List<Diff> computeDiffsChunked(String chunk1, String chunk2, List<Diff>? previousDiffs) {
  final dmp = DiffMatchPatch();
  final normChunk1 = _normalizeGCode(chunk1);
  final normChunk2 = _normalizeGCode(chunk2);

  if (previousDiffs != null && previousDiffs.isNotEmpty) {
    final lastDiff = previousDiffs.last;
    if (lastDiff.operation == DIFF_EQUAL) {
      final newDiffs = dmp.diff(normChunk1, normChunk2);
      return [...previousDiffs, ...newDiffs];
    }
  }

  final diffs = dmp.diff(normChunk1, normChunk2);
  dmp.diffCleanupSemantic(diffs);
  return diffs;
}

String _normalizeGCode(String code) {
  final lines = code.split('\n');
  final normalizedLines = <String>[];
  
  for (var line in lines) {
    line = line.replaceAll(RegExp(r';.*|\(.*\)'), '');
    line = line.toUpperCase();
    line = line.replaceAll(RegExp(r'\s+'), ' ');
    line = line.trim();
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
      return num.toInt().toString();
    } else {
      return num.toStringAsFixed(3);
    }
  } catch (e) {
    return numStr;
  }
}

List<DiffLine> parseDiffLines(List<Diff> diffs) {
  final lines = <DiffLine>[];
  int leftLineNum = 1;
  int rightLineNum = 1;
  
  // Process each diff operation separately
  for (final diff in diffs) {
    final text = diff.text;
    final textLines = text.split('\n');
    
    for (int i = 0; i < textLines.length; i++) {
      final line = textLines[i];
      final isLastLine = i == textLines.length - 1;
      
      switch (diff.operation) {
        case DIFF_INSERT:
          lines.add(DiffLine(
            leftNumber: null,
            rightNumber: rightLineNum++,
            leftText: '',
            rightText: line,
            type: DiffType.added,
          ));
          break;
          
        case DIFF_DELETE:
          lines.add(DiffLine(
            leftNumber: leftLineNum++,
            rightNumber: null,
            leftText: line,
            rightText: '',
            type: DiffType.removed,
          ));
          break;
          
        case DIFF_EQUAL:
          lines.add(DiffLine(
            leftNumber: leftLineNum++,
            rightNumber: rightLineNum++,
            leftText: line,
            rightText: line,
            type: DiffType.equal,
          ));
          break;
      }
      
      // Only increment line numbers if not last line (avoids double counting)
      if (!isLastLine) {
        if (diff.operation != DIFF_INSERT) leftLineNum++;
        if (diff.operation != DIFF_DELETE) rightLineNum++;
      }
    }
  }
  
  return lines;
}
