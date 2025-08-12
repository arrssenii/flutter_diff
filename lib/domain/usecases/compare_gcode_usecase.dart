import 'package:test_gcode/domain/entities/gcode_diff.dart';
import 'package:test_gcode/domain/repositories/gcode_repository.dart';

class CompareGCodeUseCase {
  final GCodeRepository repository;

  CompareGCodeUseCase(this.repository);

  Future<GCodeDiff> call({
    required String reference,
    required String modified,
  }) async {
    return await repository.compareGCode(
      reference: reference,
      modified: modified,
    );
  }
}