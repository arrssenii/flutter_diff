import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import '../../app/features/gcode_diff/models/gcode_version.dart';

class GCodeService {
  static const String basePath = 'assets/gcode/';

  Future<String> getReferenceGCode(String controllerId) async {
    return await _loadGCode('reference.gcode');
  }

  Future<String> getModifiedGCode(String controllerId) async {
    return await _loadGCode('modified.gcode');
  }

  Future<List<GCodeVersion>> getHistoricalVersions(String controllerId) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return [
      GCodeVersion(
        id: 'v1',
        name: 'Версия 1.0',
        timestamp: DateTime(2023, 5, 10),
      ),
      GCodeVersion(
        id: 'v2',
        name: 'Версия 1.1',
        timestamp: DateTime(2023, 6, 15),
      ),
      GCodeVersion(
        id: 'current',
        name: 'Текущая',
        timestamp: DateTime(2023, 7, 20),
      ),
    ];
  }

  Future<void> saveAsReference(String controllerId, String code) async {
    await Future.delayed(const Duration(seconds: 1));
    print('Сохранено как эталон для $controllerId');
  }

  Future<String> getVersionContent(String versionId) async {
    switch (versionId) {
      case 'v1':
        return await _loadGCode('v1.gcode');
      case 'v2':
        return await _loadGCode('v2.gcode');
      case 'current':
        return await getModifiedGCode('');
      default:
        return await getReferenceGCode('');
    }
  }

  Future<String> _loadGCode(String filename) async {
    try {
      final content = await rootBundle.loadString('$basePath$filename');
      if (content.isEmpty) {
        throw Exception('Файл $filename пустой');
      }
      return content;
    } catch (e) {
      throw Exception('Не удалось загрузить файл $filename: $e');
    }
  }
}