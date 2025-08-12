import 'package:test_gcode/domain/repositories/gcode_repository.dart';

class GetGCodeVersionsUseCase {
  final GCodeRepository repository;

  GetGCodeVersionsUseCase(this.repository);

  Future<List<String>> call() async {
    return await repository.getAvailableVersions();
  }
}