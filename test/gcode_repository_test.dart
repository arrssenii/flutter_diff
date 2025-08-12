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

  group('GCodeRepositoryImpl', () {
    test('should compare small files successfully', () async {
      when(mockService.getFileSize('ref')).thenAnswer((_) async => 1024);
      when(mockService.getFileSize('mod')).thenAnswer((_) async => 2048);
      when(mockService.getReferenceGCode('ref')).thenAnswer((_) async => 'G1 X10');
      when(mockService.getModifiedGCode('mod')).thenAnswer((_) async => 'G1 X20');

      final result = await repository.compareGCode(
        reference: 'ref',
        modified: 'mod',
      );

      expect(result, isA<domain.GCodeDiff>());
      expect(result.changes, isNotEmpty);
      verify(mockService.getFileSize('ref')).called(1);
      verify(mockService.getFileSize('mod')).called(1);
    });

    test('should throw when file exceeds size limit', () async {
      when(mockService.getFileSize('large'))
          .thenAnswer((_) async => repo.GCodeRepositoryImpl.maxFileSizeBytes + 1);

      expect(
        () => repository.compareGCode(reference: 'large', modified: 'large'),
        throwsA(isA<Exception>()),
      );
    });

    test('should process chunks correctly', () async {
      when(mockService.getFileSize('ref')).thenAnswer((_) async => 1024);
      when(mockService.getFileSize('mod')).thenAnswer((_) async => 1024);
      when(mockService.getReferenceGCodeChunked('ref'))
          .thenAnswer((_) => Stream.fromIterable(['G1 X10\n']));
      when(mockService.getModifiedGCodeChunked('mod'))
          .thenAnswer((_) => Stream.fromIterable(['G1 X20\n']));

      final stream = repository.compareGCodeChunked(
        reference: 'ref',
        modified: 'mod',
      );

      await expectLater(
        stream,
        emits(predicate<domain.GCodeDiff>((diff) => diff.changes.isNotEmpty))
      );
    });

    test('should work with asset files', () async {
      // Arrange
      final realService = GCodeService();
      final testRepo = repo.GCodeRepositoryImpl(realService);
      
      // Act & Assert
      await expectLater(
        realService.getFileSize('reference.gcode'),
        completion(isA<int>()),
      );
      
      await expectLater(
        realService.getReferenceGCode(''),
        completion(isA<String>()),
      );
      
      await expectLater(
        realService.getReferenceGCodeChunked(''),
        emits(isA<String>()),
      );
    });
  });
}