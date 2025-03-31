import 'package:discover/src/command_runner.dart';
import 'package:discover/src/converters/lcov_converter.dart';
import 'package:discover/src/extensions/file_system_entity_extension.dart';
import 'package:discover/src/system/system_runner.dart';
import 'package:file/file.dart';
import 'package:file/memory.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class _MockLogger extends Mock implements Logger {}

class _MockSystemRunner extends Mock implements SystemRunner {}

class _MockLcovConverter extends Mock implements LcovConverter {}

class _MockFile extends Mock implements File {}

void main() {
  group('scan', () {
    late Logger logger;
    late DiscoverCommandRunner commandRunner;
    late MemoryFileSystem memoryFileSystem;
    late SystemRunner systemRunner;
    late LcovConverter lcovConverter;

    setUp(() {
      logger = _MockLogger();
      memoryFileSystem = MemoryFileSystem();
      systemRunner = _MockSystemRunner();
      lcovConverter = _MockLcovConverter();
      commandRunner = DiscoverCommandRunner(
        logger: logger,
        fileSystem: memoryFileSystem,
        systemRunner: systemRunner,
        lcovConverter: lcovConverter,
      );

      registerFallbackValue(_MockFile());
    });

    test('scan lib not found', () async {
      final exitCode = await commandRunner.run(['scan']);

      expect(exitCode, ExitCode.noInput.code);

      verify(
        () => logger.err('lib directory does not exist'),
      ).called(1);
    });

    test('scan with no sources', () async {
      // GIVEN
      final currentDirectory = memoryFileSystem.currentDirectory;
      currentDirectory.childDirectory('lib').createSync(recursive: true);

      // WHEN
      final exitCode = await commandRunner.run(['scan']);

      // THEN
      expect(exitCode, ExitCode.noInput.code);

      verify(
        () => logger.err('No Dart files found in /lib'),
      ).called(1);
    });

    test('scan sources should generate coverage', () async {
      // GIVEN
      final currentDirectory = memoryFileSystem.currentDirectory;
      final libDirectory = currentDirectory.childDirectory('lib')
        ..createSync(recursive: true);
      libDirectory.childFile('foo.dart')
        ..createSync(recursive: true)
        ..writeAsStringSync('void main() {}');
      when(
        () => systemRunner.runFlutterCoverage(currentDirectory.path),
      ).thenAnswer((_) async {
        currentDirectory.childDirectory('coverage').createSync(recursive: true);
        currentDirectory.childDirectory('coverage').childFile('lcov.info')
          ..createSync(recursive: true)
          ..writeAsStringSync('''
SF:lib/foo.dart
DA:3,0
LF:1
LH:0
end_of_record
''');
      });

      // WHEN
      final exitCode = await commandRunner.run(['scan']);

      // THEN
      expect(exitCode, ExitCode.success.code);

      verify(
        () => systemRunner.runFlutterCoverage(currentDirectory.path),
      ).called(1);
    });

    test('scan sources', () async {
      // GIVEN
      final currentDirectory = memoryFileSystem.currentDirectory;
      final libDirectory = currentDirectory.childDirectory('lib')
        ..createSync(recursive: true);
      libDirectory.childFile('foo.dart')
        ..createSync(recursive: true)
        ..writeAsStringSync('void main() {}');
      final coverageDirectory = currentDirectory.childDirectory('coverage')
        ..createSync(recursive: true);
      coverageDirectory.childFile('lcov.info')
        ..createSync(recursive: true)
        ..writeAsStringSync('''
SF:lib/foo.dart
DA:3,0
LF:1
LH:0
end_of_record
''');

      // WHEN
      final exitCode = await commandRunner.run(['scan']);

      // THEN
      expect(exitCode, ExitCode.success.code);

      verify(
        () => logger.info('Found 1 Dart files:'),
      ).called(1);
      verify(
        () => logger.info('lib/foo.dart'),
      ).called(2);
    });

    test('scan coverage', () async {
      // GIVEN
      final currentDirectory = memoryFileSystem.currentDirectory;
      final libDirectory = currentDirectory.childDirectory('lib')
        ..createSync(recursive: true);
      libDirectory.childFile('main.dart')
        ..createSync(recursive: true)
        ..writeAsStringSync('void main() {}');
      final coverageDirectory = currentDirectory.childDirectory('coverage')
        ..createSync(recursive: true);
      coverageDirectory.childFile('lcov.info')
        ..createSync(recursive: true)
        ..writeAsStringSync('''
SF:lib/main.dart
DA:3,0
LF:1
LH:0
end_of_record
''');

      // WHEN
      final exitCode = await commandRunner.run(['scan']);

      // THEN
      expect(exitCode, ExitCode.success.code);

      verify(
        () => logger.info('Coverage file found.'),
      ).called(1);
      verify(
        () => logger.info('All Dart files are listed in the coverage file.'),
      ).called(1);
    });

    test('scan should identity uncovered files', () async {
      // GIVEN
      final currentDirectory = memoryFileSystem.currentDirectory;
      final libDirectory = currentDirectory.childDirectory('lib')
        ..createSync(recursive: true);
      libDirectory.childFile('main.dart')
        ..createSync(recursive: true)
        ..writeAsStringSync('void main() {}');
      final untestedFile = libDirectory.childFile('untested.dart')
        ..createSync(recursive: true)
        ..writeAsStringSync('class Untested {}');
      final coverageDirectory = currentDirectory.childDirectory('coverage')
        ..createSync(recursive: true);
      coverageDirectory.childFile('lcov.info')
        ..createSync(recursive: true)
        ..writeAsStringSync('''
SF:lib/main.dart
DA:3,0
LF:1
LH:0
end_of_record
''');

      // WHEN
      final exitCode = await commandRunner.run(['scan']);

      // THEN
      expect(exitCode, ExitCode.success.code);

      verify(
        () => logger.info('Coverage file found.'),
      ).called(1);
      verify(
        () => logger.info(
          'Some Dart files are not listed in coverage file:',
        ),
      ).called(1);
      verify(
        () => logger.info(
          untestedFile.libPath,
        ),
      ).called(2);
      const generatingMessage =
          'Generating lcov file for Dart files not listed in coverage file.';
      verify(
        () => logger.info(
          generatingMessage,
        ),
      ).called(1);

      verify(
        () => lcovConverter.writeLcovFile(any(), any()),
      ).called(1);
      verify(
        () => systemRunner.runGenHTML(currentDirectory.path),
      ).called(1);
      verify(
        () => systemRunner.runOpenHtmlReport(currentDirectory.path),
      ).called(1);
    });

    test('scan should ignore export library files', () async {
      // GIVEN
      final currentDirectory = memoryFileSystem.currentDirectory;
      final libDirectory = currentDirectory.childDirectory('lib')
        ..createSync(recursive: true);
      libDirectory.childFile('main.dart')
        ..createSync(recursive: true)
        ..writeAsStringSync('void main() {}');
      libDirectory.childFile('library.dart')
        ..createSync(recursive: true)
        ..writeAsStringSync('export "foo.dart";')
        ..writeAsStringSync('library library_name;');
      final coverageDirectory = currentDirectory.childDirectory('coverage')
        ..createSync(recursive: true);
      coverageDirectory.childFile('lcov.info')
        ..createSync(recursive: true)
        ..writeAsStringSync('''
SF:lib/main.dart
DA:3,0
LF:1
LH:0
end_of_record
''');

      // WHEN
      final exitCode = await commandRunner.run(['scan']);

      // THEN
      expect(exitCode, ExitCode.success.code);

      verify(
        () => logger.info('Coverage file found.'),
      ).called(1);
      verify(
        () => logger.info(
          'All Dart files are listed in the coverage file.',
        ),
      ).called(1);

      verifyNever(() => lcovConverter.writeLcovFile(any(), any()));
      verifyNever(() => systemRunner.runGenHTML(currentDirectory.path));
      verifyNever(() => systemRunner.runOpenHtmlReport(currentDirectory.path));
    });

    test('scan no coverage', () async {
      // GIVEN
      final currentDirectory = memoryFileSystem.currentDirectory;
      final libDirectory = currentDirectory.childDirectory('lib')
        ..createSync(recursive: true);
      libDirectory.childFile('foo.dart')
        ..createSync(recursive: true)
        ..writeAsStringSync('void main() {}');

      // WHEN
      final exitCode = await commandRunner.run(['scan']);

      // THEN
      expect(exitCode, ExitCode.noInput.code);

      verify(
        () => logger.info('No coverage directory found.'),
      ).called(1);
    });

    test('scan path', () async {
      // GIVEN
      final currentDirectory = memoryFileSystem.currentDirectory;
      final exampleDirectory = currentDirectory.childDirectory('example')
        ..createSync(recursive: true);
      final libDirectory = exampleDirectory.childDirectory('lib')
        ..createSync(recursive: true);
      libDirectory.childFile('foo.dart')
        ..createSync(recursive: true)
        ..writeAsStringSync('void main() {}');

      final coverageDirectory = exampleDirectory.childDirectory('coverage')
        ..createSync(recursive: true);
      coverageDirectory.childFile('lcov.info')
        ..createSync(recursive: true)
        ..writeAsStringSync('''
SF:lib/foo.dart
DA:3,0
LF:1
LH:0
end_of_record
''');

      // WHEN
      final exitCode = await commandRunner.run(['scan', '--path', 'example']);

      // THEN
      expect(exitCode, ExitCode.success.code);

      verify(
        () => logger.info('Found 1 Dart files:'),
      ).called(1);
      verify(
        () => logger.info('lib/foo.dart'),
      ).called(2);
    });

    test('wrong usage', () async {
      final exitCode = await commandRunner.run(['scan', '-z']);

      expect(exitCode, ExitCode.usage.code);

      verify(() => logger.err('Could not find an option or flag "-z".'))
          .called(1);
      verify(
        () => logger.info(
          '''
Usage: discover scan [arguments]
-h, --help    Print this usage information.
-p, --path    The path to scan for Dart files.
              (defaults to ".")

Run "discover help" to see global options.''',
        ),
      ).called(1);
    });
  });
}
