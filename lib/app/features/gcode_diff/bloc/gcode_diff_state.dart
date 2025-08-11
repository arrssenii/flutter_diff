part of 'gcode_diff_bloc.dart';

abstract class GCodeDiffState extends Equatable {
  const GCodeDiffState();

  @override
  List<Object?> get props => [];
}

class GCodeDiffInitial extends GCodeDiffState {}

class GCodeDiffLoading extends GCodeDiffState {}

class GCodeDiffLoaded extends GCodeDiffState {
  final String controllerId;
  final String original;
  final String modified;
  final List<int> changes;
  final int currentChangeIndex;
  final List<GCodeVersion> versions;
  final String? selectedVersionId;

  const GCodeDiffLoaded({
    required this.controllerId,
    required this.original,
    required this.modified,
    required this.changes,
    this.currentChangeIndex = 0,
    this.versions = const [],
    this.selectedVersionId,
  });

  GCodeDiffLoaded copyWith({
    String? controllerId,
    String? original,
    String? modified,
    List<int>? changes,
    int? currentChangeIndex,
    List<GCodeVersion>? versions,
    String? selectedVersionId,
  }) {
    return GCodeDiffLoaded(
      controllerId: controllerId ?? this.controllerId,
      original: original ?? this.original,
      modified: modified ?? this.modified,
      changes: changes ?? this.changes,
      currentChangeIndex: currentChangeIndex ?? this.currentChangeIndex,
      versions: versions ?? this.versions,
      selectedVersionId: selectedVersionId ?? this.selectedVersionId,
    );
  }

  @override
  List<Object> get props => [
        controllerId,
        original,
        modified,
        changes,
        currentChangeIndex,
        versions,
        selectedVersionId ?? '',
      ];
}

class GCodeDiffError extends GCodeDiffState {
  final String message;
  final String? controllerId;

  const GCodeDiffError({
    required this.message,
    this.controllerId,
  });

  @override
  List<Object?> get props => [message, controllerId];

  String get fullMessage => controllerId != null
    ? '$message (Контроллер: $controllerId)'
    : message;
}

class GCodeVersion {
  final String id;
  final String name;
  final DateTime timestamp;

  const GCodeVersion({
    required this.id,
    required this.name,
    required this.timestamp,
  });
}