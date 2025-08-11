part of 'gcode_diff_bloc.dart';

abstract class GCodeDiffEvent extends Equatable {
  const GCodeDiffEvent();

  @override
  List<Object> get props => [];
}

class LoadGCodeDiff extends GCodeDiffEvent {
  final String controllerId;

  const LoadGCodeDiff({required this.controllerId});

  @override
  List<Object> get props => [controllerId];
}

class NavigateToDiff extends GCodeDiffEvent {
  final int direction; // -1 for previous, 1 for next

  const NavigateToDiff({required this.direction});

  @override
  List<Object> get props => [direction];
}

class AcceptChanges extends GCodeDiffEvent {
  const AcceptChanges();
}

class SelectHistoricalVersion extends GCodeDiffEvent {
  final String versionId;

  const SelectHistoricalVersion({required this.versionId});

  @override
  List<Object> get props => [versionId];
}