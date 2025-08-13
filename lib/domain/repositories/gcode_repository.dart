import '../entities/gcode_diff.dart';

abstract class GCodeRepository {
  Future<Map<String, dynamic>> getLastChanges(String bsid);
  Future<List<String>> getAvailableVersions();
  Future<void> saveAsReference(String controllerId, String code);
}