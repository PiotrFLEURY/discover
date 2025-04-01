import 'package:discover/src/converters/lcov_converter.dart';
import 'package:discover/src/models/code_line.dart';
import 'package:file/file.dart';
import 'package:file/memory.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class _MockLogger extends Mock implements Logger {}

class _MockFile extends Mock implements File {}

void main() {
  group('LcovConverter', () {
    late Logger logger;
    late MemoryFileSystem memoryFileSystem;
    late LcovConverter lcovConverter;
    late _MockFile mockLcovFile;
    setUp(() {
      logger = _MockLogger();
      memoryFileSystem = MemoryFileSystem();
      lcovConverter = LcovConverter(
        logger: logger,
      );
      mockLcovFile = _MockFile();
      when(() => mockLcovFile.path).thenReturn('coverage/lcov.info');
    });

    test('writeLcovFile no files', () {
      // GIVEN

      // WHEN
      lcovConverter.writeLcovFile(
        memoryFileSystem.currentDirectory
            .listSync()
            .map((it) => it as File)
            .toList(),
        mockLcovFile,
      );

      // THEN
      verify(() => logger.warn('No Dart files found.')).called(1);
    });

    test('writeLcovFile should convert', () {
      // GIVEN
      memoryFileSystem.currentDirectory.childFile('main.dart')
        ..createSync(recursive: true)
        ..writeAsStringSync('''
void main() {
  print('Hello, world!');
}
''');
      // create an empty file to ignore
      memoryFileSystem.currentDirectory.childFile('empty.dart')
        ..createSync(recursive: true)
        ..writeAsStringSync('');

      // WHEN
      lcovConverter.writeLcovFile(
        memoryFileSystem.currentDirectory
            .listSync()
            .map((it) => it as File)
            .toList(),
        mockLcovFile,
      );

      // THEN

      const expectedLcovContent = '''
SF:main.dart
DA:2,0
LF:1
LH:0
end_of_record
''';
      verify(() => mockLcovFile.writeAsStringSync(expectedLcovContent))
          .called(1);
      verify(() => logger.warn('File empty.dart is empty.')).called(1);
    });
  });
  group('ignore lines', () {
    test('should ignore imports', () {
      // GIVEN
      final lcovConverter = LcovConverter();
      final lines = [
        const CodeLine(
          code: "import 'package:json_annotation/json_annotation.dart';",
          lineNumber: 1,
        ),
      ];

      // WHEN
      lcovConverter.filterIgnoredLines(lines);

      // THEN
      expect(lines.isEmpty, true);
    });
    test('should ignore part', () {
      // GIVEN
      final lcovConverter = LcovConverter();
      final lines = [
        const CodeLine(code: "part 'car.g.dart';", lineNumber: 1),
      ];

      // WHEN
      lcovConverter.filterIgnoredLines(lines);

      // THEN
      expect(lines.isEmpty, true);
    });
    test('should ignore part of', () {
      // GIVEN
      final lcovConverter = LcovConverter();
      final lines = [
        const CodeLine(code: "part of 'car.dart';", lineNumber: 1),
      ];

      // WHEN
      lcovConverter.filterIgnoredLines(lines);

      // THEN
      expect(lines.isEmpty, true);
    });
    test('should ignore comments', () {
      // GIVEN
      final lcovConverter = LcovConverter();
      final lines = [
        const CodeLine(code: '// This is a comment', lineNumber: 1),
      ];

      // WHEN
      lcovConverter.filterIgnoredLines(lines);

      // THEN
      expect(lines.isEmpty, true);
    });
    test('should ignore class declaration', () {
      // GIVEN
      final lcovConverter = LcovConverter();
      final lines = [
        const CodeLine(code: 'class Car', lineNumber: 1),
        const CodeLine(code: 'class Car {', lineNumber: 1),
        const CodeLine(code: 'class Car<T> {', lineNumber: 1),
        const CodeLine(code: 'class Car extends Vehicle {', lineNumber: 1),
        const CodeLine(code: 'class Car<T> extends Vehicle {', lineNumber: 1),
        const CodeLine(
          code: 'class Car extends Vehicle<Road> {',
          lineNumber: 1,
        ),
        const CodeLine(
          code: 'class Car<T> extends Vehicle<Road> {',
          lineNumber: 1,
        ),
        const CodeLine(
          code: 'class Car<T> extends Vehicle<Road> implements Drivable {',
          lineNumber: 1,
        ),
        const CodeLine(
          code: '''
class Car<T> extends Vehicle<Road> implements Drivable With Honk {''',
          lineNumber: 1,
        ),
      ];

      // WHEN
      lcovConverter.filterIgnoredLines(lines);

      // THEN
      expect(lines.isEmpty, true);
    });
    test('should ignore mixin declaration', () {
      // GIVEN
      final lcovConverter = LcovConverter();
      final lines = [
        const CodeLine(code: 'mixin Honk {', lineNumber: 1),
      ];

      // WHEN
      lcovConverter.filterIgnoredLines(lines);

      // THEN
      expect(lines.isEmpty, true);
    });
    test('should ignore extensions declaration', () {
      // GIVEN
      final lcovConverter = LcovConverter();
      final lines = [
        const CodeLine(
          code: 'extension FileExtension on File {',
          lineNumber: 1,
        ),
      ];

      // WHEN
      lcovConverter.filterIgnoredLines(lines);

      // THEN
      expect(lines.isEmpty, true);
    });
    test('should ignore closing statement declaration', () {
      // GIVEN
      final lcovConverter = LcovConverter();
      final lines = [
        const CodeLine(code: ')', lineNumber: 1),
        const CodeLine(code: '}', lineNumber: 1),
        const CodeLine(code: ']', lineNumber: 1),
        const CodeLine(code: ');', lineNumber: 1),
        const CodeLine(code: '};', lineNumber: 1),
        const CodeLine(code: '];', lineNumber: 1),
        const CodeLine(code: '),', lineNumber: 1),
        const CodeLine(code: '},', lineNumber: 1),
        const CodeLine(code: '],', lineNumber: 1),
      ];

      // WHEN
      lcovConverter.filterIgnoredLines(lines);

      // THEN
      expect(lines.isEmpty, true);
    });
    test('should ignore return statement declaration', () {
      // GIVEN
      final lcovConverter = LcovConverter();
      final lines = [
        const CodeLine(code: 'return result;', lineNumber: 1),
      ];

      // WHEN
      lcovConverter.filterIgnoredLines(lines);

      // THEN
      expect(lines.isEmpty, true);
    });
    test('should ignore constructor declarations', () {
      // GIVEN
      final lcovConverter = LcovConverter();
      final lines = [
        const CodeLine(code: 'ScanCommand({', lineNumber: 1),
        const CodeLine(code: 'ScanCommand([', lineNumber: 1),
        const CodeLine(code: 'ScanCommand.named([', lineNumber: 1),
      ];

      // WHEN
      lcovConverter.filterIgnoredLines(lines);

      // THEN
      expect(lines.isEmpty, true);
    });
    test('should ignore method declarations', () {
      // GIVEN
      final lcovConverter = LcovConverter();
      final lines = [
        const CodeLine(code: 'void writeLcovFile(', lineNumber: 1),
        const CodeLine(
          code: 'List<String> readAsCodeLinesSync() {',
          lineNumber: 1,
        ),
        const CodeLine(code: 'bool isNotEmpty() {', lineNumber: 1),
      ];

      // WHEN
      lcovConverter.filterIgnoredLines(lines);

      // THEN
      expect(lines.isEmpty, true);
    });
    test('should keep function calls', () {
      // GIVEN
      final lcovConverter = LcovConverter();
      final lines = [
        const CodeLine(
          code: "debugPrint('This function is not tested');",
          lineNumber: 1,
        ),
      ];

      // WHEN
      lcovConverter.filterIgnoredLines(lines);

      // THEN
      expect(lines.isEmpty, false);
      expect(
        lines[0].code.trim(),
        "debugPrint('This function is not tested');",
      );
    });
    test('should keep only function body', () {
      // GIVEN
      final lcovConverter = LcovConverter();
      final lines = [
        const CodeLine(
          code: "import 'package:flutter/material.dart';",
          lineNumber: 1,
        ),
        const CodeLine(code: 'class NotTested {', lineNumber: 1),
        const CodeLine(code: '  void notTested() {', lineNumber: 1),
        const CodeLine(
          code: "    debugPrint('This function is not tested');",
          lineNumber: 1,
        ),
        const CodeLine(code: '  }', lineNumber: 1),
        const CodeLine(code: '}', lineNumber: 1),
      ];

      // WHEN
      lcovConverter.filterIgnoredLines(lines);

      // THEN
      expect(lines.isEmpty, false);
      expect(lines[0].trim(), "debugPrint('This function is not tested');");
    });
  });
}
