enum DiffType { added, removed, equal, modified }

class DiffLine {
  final int number;
  final String text;
  final DiffType type;
  final String? modifiedText;

  const DiffLine({
    required this.number,
    required this.text,
    required this.type,
    this.modifiedText,
  });
}