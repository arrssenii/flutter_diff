import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:test_gcode/data/repositories/gcode_repository_impl.dart' as repo;
import 'package:test_gcode/core/services/gcode_service.dart';
import 'package:test_gcode/domain/entities/gcode_diff.dart' as domain;

import 'gcode_repository_test.mocks.dart';

@GenerateMocks([GCodeService])
void main() {
  late repo.GCodeRepositoryImpl repository;
  late MockGCodeService mockService;

  setUp(() {
    mockService = MockGCodeService();
    repository = repo.GCodeRepositoryImpl(mockService);
  });

  group('GCodeRepositoryImpl API tests', () {
    test('should return valid diff from API', () async {
      const testData = {
        'old': 'G1 X10\nG1 Y20',
        'new': 'G1 X15\nG1 Y20',
        'differences': 'modified line 1'
      };

      when(mockService.getLastChangesFromAPI('65'))
        .thenAnswer((_) async => testData);

      final result = await repository.getLastChanges('65');

      expect(result['old'], testData['old']);
      expect(result['new'], testData['new']);
      expect(result['diffResult'], isA<domain.GCodeDiff>());
      verify(mockService.getLastChangesFromAPI('65')).called(1);
    });

    test('should throw on API timeout', () async {
      when(mockService.getLastChangesFromAPI('65'))
        .thenAnswer((_) => Future.delayed(
          const Duration(seconds: 31),
          () => {}
        ));

      expect(
        () => repository.getLastChanges('65'),
        throwsA(isA<Exception>()),
      );
    });

    test('should handle API errors', () async {
      when(mockService.getLastChangesFromAPI('65'))
        .thenThrow(Exception('API error'));

      expect(
        () => repository.getLastChanges('65'),
        throwsA(isA<Exception>()),
      );
    });
  });
}