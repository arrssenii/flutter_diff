import 'package:test_gcode/domain/repositories/gcode_repository.dart';

class SaveReferenceUseCase {
  final GCodeRepository repository;

  SaveReferenceUseCase(this.repository);

  Future<void> call(String controllerId, String code) async {
    await repository.saveAsReference(controllerId, code);
  }
}