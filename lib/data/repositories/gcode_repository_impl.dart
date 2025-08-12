import 'dart:async';
import 'package:async/async.dart';
import 'package:test_gcode/domain/repositories/gcode_repository.dart';
import 'package:test_gcode/domain/entities/gcode_diff.dart' as domain;
import 'package:test_gcode/core/services/gcode_service.dart';
import 'package:test_gcode/core/utils/diff_utils.dart' as diff_utils;

typedef GCodeDiff = domain.GCodeDiff;

class GCodeRepositoryImpl implements GCodeRepository {
  final GCodeService _gcodeService;
  static const maxFileSizeBytes = 100 * 1024 * 1024; // 100MB
  static const _timeoutDuration = Duration(seconds: 30);

  GCodeRepositoryImpl(this._gcodeService);

  @override
  Future<GCodeDiff> compareGCode({
    required String reference,
    required String modified,
  }) async {
    try {
      final refSize = await _gcodeService.getFileSize(reference);
      final modSize = await _gcodeService.getFileSize(modified);
      
      if (refSize > maxFileSizeBytes || modSize > maxFileSizeBytes) {
        throw Exception('Файл слишком большой. Максимальный размер: ${maxFileSizeBytes ~/ (1024 * 1024)}MB');
      }
      
      final refContent = await _gcodeService.getReferenceGCode(reference)
        .timeout(_timeoutDuration);
      final modContent = await _gcodeService.getModifiedGCode(modified)
        .timeout(_timeoutDuration);
        
      final diffResult = diff_utils.computeDiffResult(refContent, modContent);
      
      return domain.GCodeDiff(
        reference: refContent,
        modified: modContent,
        differences: diffResult.diffLines.map((d) => domain.DiffLine(
          lineNumber: d.leftNumber ?? d.rightNumber ?? 0,
          referenceLine: d.leftText ?? '',
          modifiedLine: d.rightText ?? '',
          type: domain.DiffType.values[d.type.index],
        )).toList(),
        changes: diffResult.diffLines.map((d) => d.toString()).toList(),
        originalLines: diffResult.originalLines,
        modifiedLines: diffResult.modifiedLines,
        originalDiffLines: diffResult.originalDiffLines,
        modifiedDiffLines: diffResult.modifiedDiffLines,
        diffIndices: diffResult.diffIndices,
      );
    } on TimeoutException {
      throw Exception('Превышено время обработки файла');
    } on OutOfMemoryError {
      throw Exception('Недостаточно памяти для обработки файла');
    } catch (e) {
      throw Exception('Ошибка сравнения G-code: ${e.toString()}');
    }
  }

  @override
  Stream<GCodeDiff> compareGCodeChunked({
    required String reference,
    required String modified,
  }) async* {
    try {
      final refSize = await _gcodeService.getFileSize(reference);
      final modSize = await _gcodeService.getFileSize(modified);
      
      if (refSize > maxFileSizeBytes || modSize > maxFileSizeBytes) {
        throw Exception('Файл слишком большой. Максимальный размер: ${maxFileSizeBytes ~/ (1024 * 1024)}MB');
      }
      
      final refStream = _gcodeService.getReferenceGCodeChunked(reference)
        .timeout(_timeoutDuration);
      final modStream = _gcodeService.getModifiedGCodeChunked(modified)
        .timeout(_timeoutDuration);
      
      await for (final chunks in StreamZip([refStream, modStream])) {
        try {
          final refChunk = chunks[0] as String;
          final modChunk = chunks[1] as String;
          final diffs = diff_utils.computeDiffs(refChunk, modChunk);
          final diffLines = diff_utils.parseDiffLines(diffs);
          
          yield domain.GCodeDiff(
            reference: refChunk,
            modified: modChunk,
            differences: diffLines.map((d) => domain.DiffLine(
              lineNumber: d.leftNumber ?? d.rightNumber ?? 0,
              referenceLine: d.leftText ?? '',
              modifiedLine: d.rightText ?? '',
              type: domain.DiffType.values[d.type.index],
            )).toList(),
            changes: diffLines.map((d) => d.toString()).toList(),
            originalLines: refChunk.split('\n'),
            modifiedLines: modChunk.split('\n'),
            originalDiffLines: [],
            modifiedDiffLines: [],
            diffIndices: List.generate(diffLines.length, (i) => i),
          );
        } on OutOfMemoryError {
          throw Exception('Недостаточно памяти для обработки чанка');
        }
      }
    } on TimeoutException {
      throw Exception('Превышено время обработки файла');
    } catch (e) {
      throw Exception('Ошибка потокового сравнения G-code: ${e.toString()}');
    }
  }

  @override
  Future<Map<String, dynamic>> getLastChanges(int bsid) async {
    try {
      final data = await _gcodeService.getLastChangesFromAPI(bsid)
        .timeout(_timeoutDuration);
      
      return {
        'old': data['old'] as String,
        'new': data['new'] as String,
        'differences': data['differences'] as String,
        'timestamp': DateTime.parse(data['timestamp'] as String),
      };
    } on TimeoutException {
      throw Exception('Превышено время ожидания ответа от сервера');
    } catch (e) {
      throw Exception('Ошибка при получении изменений: ${e.toString()}');
    }
  }

  @override
  Future<List<String>> getAvailableVersions() async {
    final versions = await _gcodeService.getHistoricalVersions('');
    return versions.map((v) => v.name ?? '').toList();
  }

  @override
  Future<void> saveAsReference(String controllerId, String code) async {
    await _gcodeService.saveAsReference(controllerId, code);
  }
}