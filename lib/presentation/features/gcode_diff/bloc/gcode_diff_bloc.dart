import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:test_gcode/domain/entities/gcode_diff.dart';
import 'package:test_gcode/domain/entities/gcode_version.dart';
import 'package:test_gcode/domain/usecases/compare_gcode_usecase.dart';
import 'package:test_gcode/domain/usecases/get_gcode_versions_usecase.dart';
import 'package:test_gcode/domain/usecases/save_reference_usecase.dart';
import 'package:test_gcode/domain/repositories/gcode_repository.dart';

import 'gcode_diff_event.dart';
import 'gcode_diff_state.dart';

class GCodeDiffBloc extends Bloc<GCodeDiffEvent, GCodeDiffState> {
  final CompareGCodeUseCase compareGCode;
  final GetGCodeVersionsUseCase getVersions;
  final SaveReferenceUseCase saveReference;
  final GCodeRepository gcodeRepository;

  GCodeDiffBloc({
    required this.compareGCode,
    required this.getVersions,
    required this.saveReference,
    required this.gcodeRepository,
  }) : super(GCodeDiffInitial()) {
    on<LoadGCodeDiff>(_onLoadGCodeDiff);
    on<LoadLastChanges>(_onLoadLastChanges);
    on<NavigateToDiff>(_onNavigateToDiff);
    on<NavigateToDiffByDirection>(_onNavigateToDiffByDirection);
    on<AcceptChanges>(_onAcceptChanges);
    on<SelectHistoricalVersion>(_onSelectHistoricalVersion);
  }

  Future<void> _onLoadGCodeDiff(
    LoadGCodeDiff event,
    Emitter<GCodeDiffState> emit,
  ) async {
    try {
      emit(GCodeDiffLoading());
      final diff = await compareGCode(
        reference: event.reference,
        modified: event.modified,
      );
      emit(GCodeDiffLoaded(
        diff: diff,
        controllerId: event.controllerId,
      ));
    } catch (e) {
      emit(GCodeDiffError(e.toString()));
    }
  }

  Future<void> _onLoadLastChanges(
    LoadLastChanges event,
    Emitter<GCodeDiffState> emit,
  ) async {
    try {
      emit(GCodeDiffLoading());
      final changes = await gcodeRepository.getLastChanges(event.bsid);
      emit(GCodeApiDiffLoaded(
        apiData: changes,
        controllerId: event.bsid.toString(),
      ));
    } catch (e) {
      emit(GCodeDiffError(e.toString()));
    }
  }

  Future<void> _onNavigateToDiff(
    NavigateToDiff event,
    Emitter<GCodeDiffState> emit,
  ) async {
    if (state is GCodeDiffLoaded) {
      final currentState = state as GCodeDiffLoaded;
      emit(GCodeDiffLoaded(
        diff: event.diff,
        controllerId: event.controllerId,
        currentChangeIndex: event.diffIndex,
      ));
    }
  }

  Future<void> _onNavigateToDiffByDirection(
    NavigateToDiffByDirection event,
    Emitter<GCodeDiffState> emit,
  ) async {
    if (state is GCodeDiffLoaded) {
      final currentState = state as GCodeDiffLoaded;
      final newIndex = currentState.currentChangeIndex + event.direction;
      
      final diffIndices = currentState.diff.diffIndices;
      if (diffIndices.isEmpty) return;
      
      debugPrint('Navigating from ${currentState.currentChangeIndex} to $newIndex');
      if (newIndex >= 0 && newIndex < diffIndices.length) {
        debugPrint('Valid navigation to difference $newIndex of ${diffIndices.length}');
        emit(currentState.copyWith(
          currentChangeIndex: newIndex
        ));
      }
    }
  }

  Future<void> _onAcceptChanges(
    AcceptChanges event,
    Emitter<GCodeDiffState> emit,
  ) async {
    if (state is GCodeDiffLoaded) {
      emit(GCodeDiffLoading());
      // TODO: Implement accept changes logic
      emit(state);
    }
  }

  Future<void> _onSelectHistoricalVersion(
    SelectHistoricalVersion event,
    Emitter<GCodeDiffState> emit,
  ) async {
    if (state is GCodeDiffLoaded) {
      emit(GCodeDiffLoading());
      // TODO: Implement version selection logic
      emit(state);
    }
  }
}