import '../entities/gcode_diff.dart';

abstract class GCodeRepository {
  Future<GCodeDiff> compareGCode({
    required String reference,
    required String modified,
  });

  Future<Map<String, dynamic>> getLastChanges(int bsid);
  Future<List<String>> getAvailableVersions();
  Future<void> saveAsReference(String controllerId, String code);
}