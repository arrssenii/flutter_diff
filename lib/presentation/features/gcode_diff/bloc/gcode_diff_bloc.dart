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

  /// Строит полноценный GCodeDiff из сырых текстов old/new.
  /// Заполняет:
  /// - originalLines, modifiedLines
  /// - originalDiffLines, modifiedDiffLines (индексы строк, где есть отличия)
  /// - differences (List<DiffLine>) — объекты с info по изменению
  /// - changes (List<String>) — человекочитаемые описания изменений
  /// - diffIndices (List<int>) — список индексов изменений [0..n-1]
  /// - changeCount
  GCodeDiff _buildGCodeDiffFromStrings(String oldText, String newText) {
    final oldLines = oldText.split('\n');
    final newLines = newText.split('\n');

    final originalDiffLines = <int>[];
    final modifiedDiffLines = <int>[];
    final differences = <DiffLine>[];
    final changes = <String>[];

    int changeCounter = 0;
    final maxLen =
        oldLines.length > newLines.length ? oldLines.length : newLines.length;

    for (int i = 0; i < maxLen; i++) {
      final oldLine = i < oldLines.length ? oldLines[i] : null;
      final newLine = i < newLines.length ? newLines[i] : null;

      if (oldLine == newLine) {
        // если строки идентичны — можно (опционально) не добавлять DiffLine,
        // но для полноты можем добавить unchanged-элементы или пропустить.
        continue;
      }

      // Если есть oldLine — считаем удалением/изменением
      if (oldLine != null) {
        originalDiffLines.add(i);
      }

      // Если есть newLine — считаем добавлением/изменением
      if (newLine != null) {
        modifiedDiffLines.add(i);
      }

      // Определяем тип изменения
      final DiffType type;
      if (oldLine == null && newLine != null) {
        type = DiffType.added;
      } else if (oldLine != null && newLine == null) {
        type = DiffType.removed;
      } else {
        type = DiffType.modified;
      }

      // Создаём единый DiffLine, содержащий и reference и modified (пустые строки там, где отсутствует)
      differences.add(DiffLine(
        lineNumber: i + 1,
        referenceLine: oldLine ?? '',
        modifiedLine: newLine ?? '',
        type: type,
      ));

      // Создаём человекочитаемое описание изменения
      changes.add(
          'Line ${i + 1}: ${oldLine ?? '<empty>'} -> ${newLine ?? '<empty>'}');

      changeCounter++;
    }

    final diffIndices = List<int>.generate(changeCounter, (index) => index);

    return GCodeDiff(
      reference: oldText,
      modified: newText,
      differences: differences,
      changes: changes,
      originalLines: oldLines,
      modifiedLines: newLines,
      originalDiffLines: originalDiffLines,
      modifiedDiffLines: modifiedDiffLines,
      diffIndices: diffIndices,
      changeCount: changeCounter,
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
        debugPrint('Old content length: ${changes['old']?.length ?? 0}');
        debugPrint('New content length: ${changes['new']?.length ?? 0}');
        debugPrint(
            'Diff content length: ${changes['differences']?.length ?? 0}');
      }

      // Проверяем наличие ключей
      if (changes['old'] == null || changes['new'] == null) {
        // Если нет старого/нового, но есть differences (API-режим) — отдадим Api-state
        if (changes['differences'] != null) {
          final diffData = {
            'old': changes['old'] as String? ?? '',
            'new': changes['new'] as String? ?? '',
            'differences': changes['differences'] as String,
            'hasChanges': changes['hasChanges'] as bool? ?? false,
          };
          emit(GCodeApiDiffLoaded(
            apiData: diffData,
            controllerId: event.bsid.toString(),
          ));
          return;
        } else {
          throw FormatException(
              'Invalid API response format: missing old/new/differences');
        }
      }

      final oldText = changes['old'] as String;
      final newText = changes['new'] as String;

      // Строим GCodeDiff локально на основе old/new
      final gcodeDiff = _buildGCodeDiffFromStrings(oldText, newText);

      if (kDebugMode) {
        debugPrint(
            'Built GCodeDiff: changes=${gcodeDiff.changeCount}, diffIndices=${gcodeDiff.diffIndices.length}');
      }

      // Эмитим состояние с полным diff
      emit(GCodeDiffLoaded(
        diff: gcodeDiff,
        controllerId: event.bsid.toString(),
        currentChangeIndex: 0,
        reference: gcodeDiff.reference,
        modified: gcodeDiff.modified,
        differences: gcodeDiff.changes.join('\n'),
      ));
    } on FormatException catch (e) {
      emit(GCodeDiffError('Некорректный формат данных: ${e.message}'));
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('Error in _onLoadLastChanges: $e\n$st');
      }
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
