import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;
import 'package:dio/dio.dart';
import '../../domain/entities/gcode_version.dart';

class GCodeService {
  static const int maxFileSize = 1024 * 1024 * 5; // 5MB
  static const int chunkSize = 1024 * 64; // 64KB

  Future<int> getFileSize(String assetPath) async {
    try {
      final byteData = await rootBundle.load(assetPath);
      return byteData.lengthInBytes;
    } catch (e) {
      throw Exception('Не удалось получить размер файла $assetPath: $e');
    }
  }

  Future<String> getReferenceGCode(String controllerId) async {
    return await _loadGCode('assets/gcode/reference.gcode');
  }

  Future<String> getModifiedGCode(String controllerId) async {
    return await _loadGCode('assets/gcode/modified.gcode');
  }

  Stream<String> getReferenceGCodeChunked(String controllerId) async* {
    yield* _loadGCodeChunked('assets/gcode/reference.gcode');
  }

  Stream<String> getModifiedGCodeChunked(String controllerId) async* {
    yield* _loadGCodeChunked('assets/gcode/modified.gcode');
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
        return await _loadGCode('assets/gcode/v1.gcode');
      case 'v2':
        return await _loadGCode('assets/gcode/v2.gcode');
      case 'current':
        return await getModifiedGCode('');
      default:
        return await getReferenceGCode('');
    }
  }

  Future<String> _loadGCode(String assetPath) async {
    try {
      final content = await rootBundle.loadString(assetPath);
      if (content.isEmpty) {
        throw Exception('Файл $assetPath пустой');
      }
      if (content.length > maxFileSize) {
        throw Exception('Файл $assetPath слишком большой (${content.length} > $maxFileSize)');
      }
      return content;
    } catch (e) {
      throw Exception('Не удалось загрузить файл $assetPath: $e');
    }
  }

  Stream<String> _loadGCodeChunked(String assetPath) async* {
    try {
      final byteData = await rootBundle.load(assetPath);
      final fileSize = byteData.lengthInBytes;
      
      if (fileSize > maxFileSize) {
        throw Exception('Файл $assetPath слишком большой ($fileSize > $maxFileSize)');
      }

      final content = utf8.decode(byteData.buffer.asUint8List());
      yield content;
    } catch (e) {
      throw Exception('Ошибка потокового чтения файла $assetPath: $e');
    }
  }

  Future<Map<String, dynamic>> getLastChangesFromAPI(int bsid) async {
    try {
      final dio = Dio();
      final response = await dio.get(
        'http://192.168.29.137:6010/api/v1/program/changes/last',
        queryParameters: {'bsid': bsid},
      );
      
      if (response.statusCode == 200) {
        final json = response.data as Map<String, dynamic>;
        if (json['status'] == 'ok') {
          return json['response']['data'] as Map<String, dynamic>;
        } else {
          throw Exception('API error: ${json['message']}');
        }
      } else {
        throw Exception('HTTP error ${response.statusCode}: ${response.statusMessage}');
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionError) {
        throw Exception('Нет подключения к серверу');
      }
      throw Exception('Ошибка при получении данных: ${e.message}');
    } catch (e) {
      throw Exception('Ошибка при получении данных: $e');
    }
  }
}