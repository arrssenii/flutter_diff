import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:async/async.dart';
import 'package:dio/dio.dart';
import 'package:test_gcode/domain/repositories/gcode_repository.dart';
import 'package:test_gcode/domain/entities/gcode_diff.dart' as domain;
import 'package:test_gcode/core/services/gcode_service.dart';
import 'package:test_gcode/core/utils/diff_utils.dart' as diff_utils;

typedef GCodeDiff = domain.GCodeDiff;

class GCodeRepositoryImpl implements GCodeRepository {
  final GCodeService _gcodeService;
  static const _timeoutDuration = Duration(seconds: 30);

  GCodeRepositoryImpl(this._gcodeService);

  @override
  Future<GCodeDiff> compareGCode({
    required String reference,
    required String modified,
  }) async {
    throw UnimplementedError('Use getLastChanges instead for API data');
  }

  @override
  Stream<GCodeDiff> compareGCodeChunked({
    required String reference,
    required String modified,
  }) async* {
    throw UnimplementedError('Use getLastChanges instead for API data');
  }

  @override
  Future<Map<String, dynamic>> getLastChanges(String bsid) async {
    try {
      if (kDebugMode) {
        debugPrint('Fetching last changes for bsid: $bsid');
      }
      final data = await _gcodeService.getLastChangesFromAPI(bsid)
        .timeout(_timeoutDuration);
      if (kDebugMode) {
        debugPrint('Received API data: ${data.keys}');
      }
      
      final differences = data['differences'] as String;
      final hasChanges = differences.contains('\u001B[31m') ||
          differences.contains('\u001B[32m') ||
          differences.contains('\u001B[33m');
      
      if (kDebugMode) {
        debugPrint('Processing diff data...');
        debugPrint('Old content length: ${data['old']?.length ?? 0}');
        debugPrint('New content length: ${data['new']?.length ?? 0}');
        debugPrint('Diff content length: ${data['differences']?.length ?? 0}');
        debugPrint('Has changes: $hasChanges');
      }
      return {
        'old': data['old'] as String,
        'new': data['new'] as String,
        'differences': differences,
        'hasChanges': hasChanges,
        'diffResult': domain.GCodeDiff(
          reference: data['old'] as String,
          modified: data['new'] as String,
          differences: differences.split('\n').map((line) => domain.DiffLine(
            lineNumber: 0, // Будет установлено при отображении
            referenceLine: line,
            modifiedLine: line,
            type: line.contains('\u001B[31m')
              ? domain.DiffType.removed
              : line.contains('\u001B[32m')
                ? domain.DiffType.added
                : line.contains('\u001B[33m')
                  ? domain.DiffType.modified
                  : domain.DiffType.unchanged,
          )).toList(),
          changes: [differences],
          diffIndices: [],
          originalLines: data['old'].toString().split('\n'),
          modifiedLines: data['new'].toString().split('\n'),
        ),
      };
    } on TimeoutException {
      throw Exception('Превышено время ожидания ответа от сервера');
    } on DioException catch (e) {
      rethrow; // Already has proper message from service
    } catch (e) {
      throw Exception('Ошибка при обработке данных: ${e.toString()}');
    }
  }

  @override
  Future<List<String>> getAvailableVersions() async {
    throw UnimplementedError('Versions should be fetched from API directly');
  }

  @override
  Future<void> saveAsReference(String controllerId, String code) async {
    throw UnimplementedError('Saving should be done via API directly');
  }
}