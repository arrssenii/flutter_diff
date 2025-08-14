class GCodeNormalizer {
  /// Нормализует G-код:
  /// 1. Удаляет комментарии (все после ; или в скобках)
  /// 2. Приводит к верхнему регистру
  /// 3. Удаляет лишние пробелы
  /// 4. Удаляет пустые строки
  static String normalize(String gcode) {
    final lines = gcode.split('\n');
    final normalized = <String>[];
    
    for (var line in lines) {
      line = line.replaceAll(RegExp(r';.*|\(.*\)'), '');
      line = line.toUpperCase();
      line = line.replaceAll(RegExp(r'\s+'), ' ').trim();
      if (line.isNotEmpty) normalized.add(line);
    }
    
    return normalized.join('\n');
  }
}