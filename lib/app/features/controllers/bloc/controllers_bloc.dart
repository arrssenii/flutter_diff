import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../models/controllers_model.dart';

// События
abstract class ControllersEvent extends Equatable {
  const ControllersEvent();
}

class LoadControllers extends ControllersEvent {
  @override
  List<Object> get props => [];
}

// Состояния
abstract class ControllersState extends Equatable {
  const ControllersState();
}

class ControllersInitial extends ControllersState {
  @override
  List<Object> get props => [];
}

class ControllersLoading extends ControllersState {
  @override
  List<Object> get props => [];
}

class ControllersLoaded extends ControllersState {
  final List<ControllerModel> controllers;

  const ControllersLoaded({required this.controllers});

  @override
  List<Object> get props => [controllers];
}

class ControllersError extends ControllersState {
  final String message;

  const ControllersError({required this.message});

  @override
  List<Object> get props => [message];
}

// Блок
class ControllersBloc extends Bloc<ControllersEvent, ControllersState> {
  ControllersBloc() : super(ControllersInitial()) {
    on<LoadControllers>(_onLoadControllers);
  }

  Future<void> _onLoadControllers(
    LoadControllers event,
    Emitter<ControllersState> emit,
  ) async {
    emit(ControllersLoading());
    try {
      // Имитация загрузки с сервера
      await Future.delayed(const Duration(seconds: 1));
      emit(ControllersLoaded(controllers: [
        ControllerModel(id: 'cnc-01', name: 'Станок 1', hasChanges: true),
        ControllerModel(id: 'cnc-02', name: 'Станок 2', hasChanges: false),
        ControllerModel(id: 'cnc-03', name: 'Станок 3', hasChanges: true),
      ]));
    } catch (e) {
      emit(ControllersError(message: 'Ошибка загрузки: $e'));
    }
  }
}