library diff_types;

enum DiffType {
  equal,
  added,
  removed,
  modified,
}

class DiffLine {
  final String leftText;
  final String rightText;
  final int? leftNumber;
  final int? rightNumber;
  final DiffType type;

  DiffLine({
    required this.leftText,
    required this.rightText,
    this.leftNumber,
    this.rightNumber,
    required this.type,
  });

  @override
  String toString() {
    return 'DiffLine(left: $leftNumber, right: $rightNumber, type: $type)';
  }
}