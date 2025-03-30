import 'package:discover/src/converters/lcov_converter.dart';
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
        memoryFileSystem.currentDirectory.listSync(),
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
        memoryFileSystem.currentDirectory.listSync(),
        mockLcovFile,
      );

      // THEN
      const expectedLcovContent = '''
SF:main.dart
DA:1,0
DA:2,0
DA:3,0
LF:3
LH:0
end_of_record
''';
      verify(() => mockLcovFile.writeAsStringSync(expectedLcovContent))
          .called(1);
      verify(() => logger.warn('File empty.dart is empty.')).called(1);
    });
  });
}
