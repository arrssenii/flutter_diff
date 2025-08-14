import 'package:flutter/material.dart';
import 'package:test_gcode/core/utils/diff_types.dart';

class GCodeHighlighter {
  static const TextStyle baseStyle = TextStyle(
    fontFamily: 'RobotoMono',
    fontSize: 12,
    height: 1.5,
    color: Colors.black,
  );

  static List<TextSpan> highlight(String code, {DiffType? diffType}) {
    final spans = _highlightGCode(code);
    
    if (diffType != null) {
      // Apply diff highlighting
      final color = diffType == DiffType.added
          ? Colors.green[700]!
          : diffType == DiffType.removed
              ? Colors.red[700]!
              : Colors.orange[700]!;
      
      return [
        TextSpan(
          children: spans,
          style: baseStyle.copyWith(
            backgroundColor: color.withOpacity(0.15),
            color: color,
            fontWeight: FontWeight.w500,
          ),
        ),
      ];
    }
    
    return spans;
  }

  static List<TextSpan> _highlightGCode(String code) {
    final spans = <TextSpan>[];
    int currentPos = 0;
    
    final gCommand = RegExp(r'\bG\d+\b');
    final mCommand = RegExp(r'\bM\d+\b');
    final tCommand = RegExp(r'\bT\d+\b');
    final fCommand = RegExp(r'\bF\d+\b');
    final parameter = RegExp(r'\b[XYZIJK]-?\d+\.?\d*\b');
    final cycleParam = RegExp(r'\b[QLR]\d+\b');
    final comment = RegExp(r';.*|\(.*\)');
    
    final matches = [
      ...gCommand.allMatches(code),
      ...mCommand.allMatches(code),
      ...tCommand.allMatches(code),
      ...fCommand.allMatches(code),
      ...parameter.allMatches(code),
      ...cycleParam.allMatches(code),
      ...comment.allMatches(code),
    ]..sort((a, b) => a.start.compareTo(b.start));

    for (final match in matches) {
      if (match.start > currentPos) {
        spans.add(TextSpan(text: code.substring(currentPos, match.start)));
      }
      
      final text = code.substring(match.start, match.end);
      if (gCommand.hasMatch(text)) {
        spans.add(TextSpan(
          text: text,
          style: baseStyle.copyWith(color: Colors.blue, fontWeight: FontWeight.bold),
        ));
      } else if (mCommand.hasMatch(text)) {
        spans.add(TextSpan(
          text: text,
          style: baseStyle.copyWith(color: Colors.purple, fontWeight: FontWeight.bold),
        ));
      } else if (tCommand.hasMatch(text)) {
        spans.add(TextSpan(
          text: text,
          style: baseStyle.copyWith(color: Colors.orange, fontWeight: FontWeight.bold),
        ));
      } else if (fCommand.hasMatch(text)) {
        spans.add(TextSpan(
          text: text,
          style: baseStyle.copyWith(color: Colors.teal, fontWeight: FontWeight.bold),
        ));
      } else if (parameter.hasMatch(text)) {
        spans.add(TextSpan(
          text: text,
          style: baseStyle.copyWith(color: Colors.redAccent),
        ));
      } else if (cycleParam.hasMatch(text)) {
        spans.add(TextSpan(
          text: text,
          style: baseStyle.copyWith(color: Colors.pink),
        ));
      } else if (comment.hasMatch(text)) {
        spans.add(TextSpan(
          text: text,
          style: baseStyle.copyWith(color: Colors.green),
        ));
      }
      
      currentPos = match.end;
    }
    
    if (currentPos < code.length) {
      spans.add(TextSpan(text: code.substring(currentPos)));
    }
    
    return spans;
  }
}