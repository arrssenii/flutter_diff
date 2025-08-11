import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:diff_match_patch/diff_match_patch.dart';
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:test_gcode/app/features/gcode_diff/models/gcode_diff_model.dart';
import 'package:test_gcode/core/utils/diff_types.dart';
import '../../../../core/utils/diff_utils.dart';
import '../../../../core/services/gcode_service.dart';

part 'gcode_diff_event.dart';
part 'gcode_diff_state.dart';

class GCodeDiffBloc extends Bloc<GCodeDiffEvent, GCodeDiffState> {
  final GCodeService gCodeService;
  GCodeDiffBloc({required this.gCodeService}) : super(GCodeDiffInitial()) {
    on<LoadGCodeDiff>(_onLoadGCodeDiff);
    on<NavigateToDiff>(_onNavigateToDiff);
    on<AcceptChanges>(_onAcceptChanges);
    on<SelectHistoricalVersion>(_onSelectHistoricalVersion);
  }

  void _onLoadGCodeDiff(LoadGCodeDiff event, Emitter<GCodeDiffState> emit) async {
    if (event.controllerId.isEmpty) {
      emit(GCodeDiffError(message: 'Не указан ID контроллера'));
      return;
    }
    
    emit(GCodeDiffLoading());
    try {
      final original = await gCodeService.getReferenceGCode(event.controllerId);
      final modified = await gCodeService.getModifiedGCode(event.controllerId);
      final diffs = computeDiffs(original, modified);
      final diffLines = parseDiffLines(diffs);
      
      // Найти индексы изменений
      final changes = diffLines
          .asMap()
          .entries
          .where((entry) => entry.value.type != DiffType.equal)
          .map((entry) => entry.key)
          .toList();

      emit(GCodeDiffLoaded(
        controllerId: event.controllerId,
        original: original,
        modified: modified,
        changes: changes,
        currentChangeIndex: changes.isNotEmpty ? 0 : -1,
      ));
    } catch (e) {
      emit(GCodeDiffError(
        message: e is Exception ? e.toString() : 'Ошибка загрузки данных: $e'
      ));
    }
  }

  void _onNavigateToDiff(NavigateToDiff event, Emitter<GCodeDiffState> emit) {
    if (state is GCodeDiffLoaded) {
      final currentState = state as GCodeDiffLoaded;
      int newIndex = currentState.currentChangeIndex + event.direction;
      
      if (newIndex < 0) newIndex = currentState.changes.length - 1;
      if (newIndex >= currentState.changes.length) newIndex = 0;
      
      emit(currentState.copyWith(currentChangeIndex: newIndex));
    }
  }

  void _onAcceptChanges(AcceptChanges event, Emitter<GCodeDiffState> emit) async {
    if (state is GCodeDiffLoaded) {
      final currentState = state as GCodeDiffLoaded;
      emit(GCodeDiffLoading());
      try {
        await gCodeService.saveAsReference(
          currentState.controllerId,
          currentState.modified,
        );
        add(LoadGCodeDiff(controllerId: currentState.controllerId));
      } catch (e) {
        emit(GCodeDiffError(message: 'Ошибка сохранения: $e'));
      }
    }
  }

  void _onSelectHistoricalVersion(
    SelectHistoricalVersion event,
    Emitter<GCodeDiffState> emit,
  ) async {
    if (state is GCodeDiffLoaded) {
      final currentState = state as GCodeDiffLoaded;
      emit(GCodeDiffLoading());
      try {
        final versionContent = await gCodeService.getVersionContent(event.versionId);
        // TODO: Реализовать определение изменений
        final changes = <int>[];
  
        emit(GCodeDiffLoaded(
          controllerId: currentState.controllerId,
          original: currentState.original,
          modified: versionContent,
          changes: changes,
          currentChangeIndex: changes.isNotEmpty ? 0 : -1,
          versions: currentState.versions,
          selectedVersionId: event.versionId,
        ));
      } catch (e) {
        emit(GCodeDiffError(message: 'Ошибка загрузки версии: $e'));
      }
    }
  }  

  @override
  Future<void> close() => super.close();
}