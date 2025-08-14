import 'package:equatable/equatable.dart';
import 'package:test_gcode/domain/entities/gcode_diff.dart';

abstract class GCodeDiffState extends Equatable {
  const GCodeDiffState();

  @override
  List<Object> get props => [];
}

class GCodeDiffInitial extends GCodeDiffState {}

class GCodeDiffLoading extends GCodeDiffState {}

class GCodeDiffLoaded extends GCodeDiffState {
  final GCodeDiff diff;
  final String controllerId;
  final int currentChangeIndex;

  const GCodeDiffLoaded({
    required this.diff,
    required this.controllerId,
    this.currentChangeIndex = 0,
  });

  GCodeDiffLoaded copyWith({
    GCodeDiff? diff,
    String? controllerId,
    int? currentChangeIndex,
  }) {
    return GCodeDiffLoaded(
      diff: diff ?? this.diff,
      controllerId: controllerId ?? this.controllerId,
      currentChangeIndex: currentChangeIndex ?? this.currentChangeIndex,
    );
  }

  @override
  List<Object> get props => [diff, controllerId, currentChangeIndex];
}

class GCodeApiDiffLoaded extends GCodeDiffState {
  final Map<String, dynamic> apiData;
  final String controllerId;

  const GCodeApiDiffLoaded({
    required this.apiData,
    required this.controllerId,
  });

  @override
  List<Object> get props => [apiData, controllerId];
}

class GCodeDiffError extends GCodeDiffState {
  final String message;

  const GCodeDiffError(this.message);

  @override
  List<Object> get props => [message];
}