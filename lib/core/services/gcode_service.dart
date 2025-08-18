import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';

class GCodeService {
  String? _cleanCncData(dynamic input) {
    if (input == null) return null;

    String text = input is String ? input : input.toString();
    text = text.replaceAll(RegExp(r'%[^%]*%'), '');
    text = text.replaceAll(RegExp(r'[\x00-\x1F\x7F]'), '');

    try {
      utf8.decode(utf8.encode(text));
    } catch (e) {
      throw FormatException('Invalid UTF-8 encoding');
    }

    return text.trim();
  }

  Future<Map<String, dynamic>> getLastChangesFromAPI(String bsid) async {
    try {
      final dio = Dio(BaseOptions(
        baseUrl: 'http://192.168.29.137:5000',
        headers: {
          'Content-Type': 'application/json',
          'Authorization':
              'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJleHAiOjE3NTU2MDE2NzAsImxvZ2luIjoiYWRtaW4iLCJ1c2VyX2lkIjoxfQ.BHLrtvN1yOirXTfwN4vGXmSPFxBed95Yx7v1v-vpyQQ',
        },
        contentType: 'application/json',
        followRedirects: false,
        validateStatus: (status) => status! < 500,
      ));

      final numericBsid = 65;
      final response = await dio.get(
        '/api/v1/program/changes/last',
        queryParameters: {'bsid': numericBsid},
      );

      if (response.statusCode == 200) {
        final json = response.data as Map<String, dynamic>;
        if (json['status'] == 'ok') {
          final data = json['response']['data'] as Map<String, dynamic>;

          if (kDebugMode) {}
          final cleanedData = {
            'old': data['old']?.toString() ?? '',
            'new': data['new']?.toString() ?? '',
            'differences': data['differences']?.toString() ?? '',
          };

          if (cleanedData.values.any((v) => v == null)) {
            throw Exception('Invalid API response format');
          }

          if (kDebugMode) {}
          return cleanedData;
        }
        throw Exception('API error: ${json['message']}');
      }
      throw Exception('HTTP error ${response.statusCode}');
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw Exception(
            'Ошибка авторизации. Токен недействителен или отсутствует.');
      } else if (e.type == DioExceptionType.connectionError) {
        throw Exception(
            'Ошибка соединения с сервером. Проверьте подключение к сети.');
      } else if (e.type == DioExceptionType.connectionTimeout) {
        throw Exception('Таймаут соединения. Сервер не отвечает.');
      } else if (e.response?.statusCode == 403 ||
          e.message?.contains('CORS') == true) {
        throw Exception(
            'Ошибка CORS. Сервер не разрешает запросы с этого домена.');
      }
      throw Exception('Ошибка сети: ${e.message}');
    }
  }
}
