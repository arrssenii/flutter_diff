import 'package:flutter/material.dart';

class GCodeHighlighter extends StatelessWidget {
  final String text;
  final TextStyle baseStyle;
  final bool preserveWhitespace;
  
  const GCodeHighlighter({
    super.key, 
    required this.text,
    this.preserveWhitespace = true,
    this.baseStyle = const TextStyle(
      fontFamily: 'RobotoMono',
      fontSize: 12,
      height: 1.5,
      color: Colors.black,
    ),
  });

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        children: _highlightGCode(text),
        style: baseStyle.copyWith(
          leadingDistribution: TextLeadingDistribution.even,
        ),
      ),
      textAlign: TextAlign.left,
      softWrap: false,
    );
  }

  List<TextSpan> _highlightGCode(String code) {
    final spans = <TextSpan>[];
    int currentPos = 0;
    
    final gCommand = RegExp(r'\bG\d+\b');
    final mCommand = RegExp(r'\bM\d+\b');
    final parameter = RegExp(r'\b[XYZEFS]-?\d+\.?\d*\b');
    final comment = RegExp(r';.*|\(.*\)');
    
    final matches = [
      ...gCommand.allMatches(code),
      ...mCommand.allMatches(code),
      ...parameter.allMatches(code),
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
      } else if (parameter.hasMatch(text)) {
        spans.add(TextSpan(
          text: text,
          style: baseStyle.copyWith(color: Colors.redAccent),
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