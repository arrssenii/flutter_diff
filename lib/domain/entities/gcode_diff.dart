import 'package:equatable/equatable.dart';

class GCodeDiff extends Equatable {
  final String reference;
  final String modified;
  final List<DiffLine> differences;
  final List<String> changes;
  final List<String> originalLines;
  final List<String> modifiedLines;
  final List<int> originalDiffLines;
  final List<int> modifiedDiffLines;
  final List<int> diffIndices;
  final int? changeCount;

  const GCodeDiff({
    required this.reference,
    required this.modified,
    required this.differences,
    required this.changes,
    this.originalLines = const [],
    this.modifiedLines = const [],
    this.originalDiffLines = const [],
    this.modifiedDiffLines = const [],
    required this.diffIndices,
    this.changeCount,
  });

  @override
  List<Object> get props => [
        reference,
        modified,
        differences,
        changes,
        originalLines,
        modifiedLines,
        originalDiffLines,
        modifiedDiffLines,
      ];
}

class DiffLine extends Equatable {
  final int lineNumber;
  final String referenceLine;
  final String modifiedLine;
  final DiffType type;

  const DiffLine({
    required this.lineNumber,
    required this.referenceLine,
    required this.modifiedLine,
    required this.type,
  });

  @override
  List<Object> get props => [lineNumber, referenceLine, modifiedLine, type];
}

enum DiffType {
  unchanged,
  added,
  removed,
  modified,
}
