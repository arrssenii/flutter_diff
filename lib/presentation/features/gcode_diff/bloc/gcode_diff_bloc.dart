import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:test_gcode/domain/entities/gcode_diff.dart';
import 'package:test_gcode/domain/entities/gcode_version.dart';
import 'package:test_gcode/domain/usecases/get_gcode_versions_usecase.dart';
import 'package:test_gcode/domain/usecases/save_reference_usecase.dart';
import 'package:test_gcode/domain/repositories/gcode_repository.dart';

import 'gcode_diff_event.dart';
import 'gcode_diff_state.dart';

class GCodeDiffBloc extends Bloc<GCodeDiffEvent, GCodeDiffState> {
  final GetGCodeVersionsUseCase getVersions;
  final SaveReferenceUseCase saveReference;
  final GCodeRepository gcodeRepository;

  GCodeDiffBloc({
    required this.getVersions,
    required this.saveReference,
    required this.gcodeRepository,
  }) : super(GCodeDiffInitial()) {
    on<LoadLastChanges>(_onLoadLastChanges);
    on<NavigateToDiff>(_onNavigateToDiff);
    on<NavigateToDiffByDirection>(_onNavigateToDiffByDirection);
    on<AcceptChanges>(_onAcceptChanges);
    on<SelectHistoricalVersion>(_onSelectHistoricalVersion);
    on<ErrorOccurred>((event, emit) => emit(GCodeDiffError(event.message)));
  }

  GCodeDiff _buildGCodeDiffFromStrings(String oldText, String newText) {
    final oldLines = oldText.split('\n');
    final newLines = newText.split('\n');

    final originalDiffLines = <int>[];
    final modifiedDiffLines = <int>[];
    final diffIndices = <int>[];
    final changes = <DiffLine>[]; // Список для объектов DiffLine

    int changeCounter = 0;
    final maxLen =
        oldLines.length > newLines.length ? oldLines.length : newLines.length;

    for (int i = 0; i < maxLen; i++) {
      final oldLine = i < oldLines.length ? oldLines[i] : null;
      final newLine = i < newLines.length ? newLines[i] : null;

      if (oldLine != newLine) {
        originalDiffLines.add(i < oldLines.length ? i : -1);
        modifiedDiffLines.add(i < newLines.length ? i : -1);
        diffIndices.add(changeCounter);

        // Добавляем DiffLine объект в список changes
        if (oldLine != null) {
          changes.add(DiffLine(
            lineNumber: i + 1, // Номер строки
            referenceLine: oldLine, // Строка из старого кода
            modifiedLine: '', // Пустая строка для измененной
            type: DiffType.removed, // Тип изменения: удалено
          ));
        }
        if (newLine != null) {
          changes.add(DiffLine(
            lineNumber: i + 1, // Номер строки
            referenceLine: '', // Пустая строка для старого кода
            modifiedLine: newLine, // Строка из нового кода
            type: DiffType.added, // Тип изменения: добавлено
          ));
        }
        changeCounter++;
      }
    }

    return GCodeDiff(
      originalLines: oldLines,
      modifiedLines: newLines,
      originalDiffLines: originalDiffLines.where((i) => i >= 0).toList(),
      modifiedDiffLines: modifiedDiffLines.where((i) => i >= 0).toList(),
      diffIndices: diffIndices,
      differences: changes, // Передаем список DiffLine
      reference: oldText, // Передаем reference
      modified: newText, // Передаем modified
      changes: changes
          .map((change) =>
              '${change.lineNumber}: ${change.referenceLine} => ${change.modifiedLine}')
          .toList(), // Преобразуем в List<String>
    );
  }

  Future<void> _onLoadLastChanges(
    LoadLastChanges event,
    Emitter<GCodeDiffState> emit,
  ) async {
    try {
      emit(GCodeDiffLoading());
      final changes = await gcodeRepository.getLastChanges(event.bsid);

      if (kDebugMode) {
        debugPrint('API Response keys: ${changes.keys}');
      }

      if (changes['old'] == null || changes['new'] == null) {
        emit(GCodeApiDiffLoaded(
          apiData: {
            'old': changes['old'] ?? '',
            'new': changes['new'] ?? '',
            'differences': changes['differences'] ?? '',
            'hasChanges': changes['hasChanges'] ?? false,
          },
          controllerId: event.bsid.toString(),
        ));
        return;
      }

      final oldText = changes['old'] as String;
      final newText = changes['new'] as String;
      final differences = changes['differences'] as String;

      final gcodeDiff = _buildGCodeDiffFromStrings(oldText, newText);

      emit(GCodeDiffLoaded(
        diff: gcodeDiff,
        controllerId: event.bsid.toString(),
        currentChangeIndex: 0,
        reference: oldText, // Передача reference
        modified: newText, // Передача modified
        differences: differences, // Передача differences
      ));
    } on FormatException catch (e) {
      emit(GCodeDiffError('Некорректный формат данных: ${e.message}'));
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
      if (event.diffIndex >= 0 &&
          event.diffIndex < event.diff.diffIndices.length) {
        emit(currentState.copyWith(currentChangeIndex: event.diffIndex));
      }
    }
  }

  Future<void> _onNavigateToDiffByDirection(
    NavigateToDiffByDirection event,
    Emitter<GCodeDiffState> emit,
  ) async {
    if (state is GCodeDiffLoaded) {
      final currentState = state as GCodeDiffLoaded;
      final currentIndex = currentState.currentChangeIndex;
      final total = currentState.diff.diffIndices.length;

      final newIndex = (currentIndex + event.direction).clamp(0, total - 1);

      if (newIndex != currentIndex) {
        emit(currentState.copyWith(currentChangeIndex: newIndex));
        if (kDebugMode) debugPrint('Navigated to diff index $newIndex');
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
