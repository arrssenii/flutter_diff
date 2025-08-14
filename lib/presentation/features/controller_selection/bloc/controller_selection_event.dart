import 'package:equatable/equatable.dart';

abstract class ControllerSelectionEvent extends Equatable {
  const ControllerSelectionEvent();

  @override
  List<Object> get props => [];
}

class LoadControllers extends ControllerSelectionEvent {}

class SelectController extends ControllerSelectionEvent {
  final String controllerId;

  const SelectController(this.controllerId);

  @override
  List<Object> get props => [controllerId];
}