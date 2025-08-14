import 'package:equatable/equatable.dart';

abstract class ControllerSelectionState extends Equatable {
  const ControllerSelectionState();

  @override
  List<Object> get props => [];
}

class ControllerSelectionInitial extends ControllerSelectionState {}

class ControllerSelectionLoading extends ControllerSelectionState {}

class ControllerSelectionLoaded extends ControllerSelectionState {
  final List<String> controllers;

  const ControllerSelectionLoaded(this.controllers);

  @override
  List<Object> get props => [controllers];
}

class ControllerSelectionError extends ControllerSelectionState {
  final String message;

  const ControllerSelectionError(this.message);

  @override
  List<Object> get props => [message];
}