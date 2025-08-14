import 'package:flutter_bloc/flutter_bloc.dart';
import 'controller_selection_event.dart';
import 'controller_selection_state.dart';

class ControllerSelectionBloc extends Bloc<ControllerSelectionEvent, ControllerSelectionState> {
  ControllerSelectionBloc() : super(ControllerSelectionInitial()) {
    on<LoadControllers>(_onLoadControllers);
    on<SelectController>(_onSelectController);
  }

  Future<void> _onLoadControllers(
    LoadControllers event,
    Emitter<ControllerSelectionState> emit,
  ) async {
    try {
      emit(ControllerSelectionLoading());
      // TODO: Заменить на реальные данные
      final controllers = ['CNC-1', 'CNC-2', 'CNC-3'];
      emit(ControllerSelectionLoaded(controllers));
    } catch (e) {
      emit(ControllerSelectionError(e.toString()));
    }
  }

  Future<void> _onSelectController(
    SelectController event,
    Emitter<ControllerSelectionState> emit,
  ) async {
    // TODO: Реализовать логику выбора контроллера
  }
}