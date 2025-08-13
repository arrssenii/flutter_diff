import 'package:equatable/equatable.dart';
import 'package:test_gcode/domain/entities/gcode_diff.dart';
import 'package:test_gcode/domain/entities/gcode_version.dart';

abstract class GCodeDiffEvent extends Equatable {
  const GCodeDiffEvent();

  @override
  List<Object> get props => [];
}

class LoadGCodeDiff extends GCodeDiffEvent {
  final String reference;
  final String modified;
  final String controllerId;

  const LoadGCodeDiff({
    required this.reference,
    required this.modified,
    required this.controllerId,
  });

  @override
  List<Object> get props => [reference, modified, controllerId];
}

class LoadLastChanges extends GCodeDiffEvent {
  final String bsid;

  const LoadLastChanges(this.bsid);

  @override
  List<Object> get props => [bsid];
}

class NavigateToDiffByDirection extends GCodeDiffEvent {
  final int direction; // 1 for next, -1 for previous

  const NavigateToDiffByDirection(this.direction);

  @override
  List<Object> get props => [direction];
}

class NavigateToDiff extends GCodeDiffEvent {
  final GCodeDiff diff;
  final String controllerId;
  final int diffIndex;

  const NavigateToDiff({
    required this.diff,
    required this.controllerId,
    required this.diffIndex,
  });

  @override
  List<Object> get props => [diff, controllerId, diffIndex];
}

class AcceptChanges extends GCodeDiffEvent {
  final String controllerId;

  const AcceptChanges(this.controllerId);

  @override
  List<Object> get props => [controllerId];
}

class SelectHistoricalVersion extends GCodeDiffEvent {
  final GCodeVersion version;

  const SelectHistoricalVersion(this.version);

  @override
  List<Object> get props => [version];
}

class ErrorOccurred extends GCodeDiffEvent {
  final String message;

  const ErrorOccurred(this.message);

  @override
  List<Object> get props => [message];
}