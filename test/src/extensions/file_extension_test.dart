import 'package:discover/src/extensions/extensions.dart';
import 'package:file/memory.dart';
import 'package:test/expect.dart';
import 'package:test/scaffolding.dart';

void main() {
  final fileSystem = MemoryFileSystem();

  group('readAsCodeLinesSync', () {
    test('empty file should return empty list', () {
      // GIVEN
      final file = fileSystem.file('test.dart')..writeAsStringSync('');

      // WHEN
      final codeLines = file.readAsCodeLinesSync();

      // THEN
      expect(codeLines, isEmpty);
    });
    test('empty lines should be ignored', () {
      // GIVEN
      final file = fileSystem.file('test.dart')
        ..writeAsStringSync(
          '''
        
        ''',
        );

      // WHEN
      final codeLines = file.readAsCodeLinesSync();

      // THEN
      expect(codeLines, isEmpty);
    });
    test('comments should be ignored', () {
      // GIVEN
      final file = fileSystem.file('test.dart')
        ..writeAsStringSync(
          '''
        // This is a comment
        // Another comment
        // Yet another comment
        ''',
        );

      // WHEN
      final codeLines = file.readAsCodeLinesSync();

      // THEN
      expect(codeLines, isEmpty);
    });
    test('code should be returned', () {
      // GIVEN
      final file = fileSystem.file('test.dart')
        ..writeAsStringSync(
          '''
        void main() {
          print('Hello, world!');
        }
        ''',
        );

      // WHEN
      final codeLines = file.readAsCodeLinesSync();

      // THEN
      expect(codeLines, isNotEmpty);
      expect(codeLines.length, 3);
      expect(codeLines[0], 'void main() {');
      expect(codeLines[1], "print('Hello, world!');");
      expect(codeLines[2], '}');
    });
    test('complex example', () {
      // GIVEN
      final file = fileSystem.file('test.dart')
        ..writeAsStringSync(
          '''
          
        /// This is a documentation comment
        void main() {
        
          // This is a comment
          print('Hello, world!');
          
        }
        
        ''',
        );

      // WHEN
      final codeLines = file.readAsCodeLinesSync();

      // THEN
      expect(codeLines, isNotEmpty);
      expect(codeLines.length, 3);
      expect(codeLines[0], 'void main() {');
      expect(codeLines[1], "print('Hello, world!');");
      expect(codeLines[2], '}');
    });
  });
  group('isNotEmpty', () {
    test('empty file should return false', () {
      // GIVEN
      final file = fileSystem.file('test.dart')..writeAsStringSync('');

      // WHEN
      final isNotEmpty = file.isNotEmpty();

      // THEN
      expect(isNotEmpty, isFalse);
    });
    test('file with only empty lines should return false', () {
      // GIVEN
      final file = fileSystem.file('test.dart')
        ..writeAsStringSync(
          '''
        
        ''',
        );

      // WHEN
      final isNotEmpty = file.isNotEmpty();

      // THEN
      expect(isNotEmpty, isFalse);
    });
    test('file with only comments should return false', () {
      // GIVEN
      final file = fileSystem.file('test.dart')
        ..writeAsStringSync(
          '''
        // This is a comment
        // Another comment
        ''',
        );

      // WHEN
      final isNotEmpty = file.isNotEmpty();

      // THEN
      expect(isNotEmpty, isFalse);
    });
  });
  group('isExportLibrary', () {
    test('empty file should return false', () {
      // GIVEN
      final file = fileSystem.file('test.dart')..writeAsStringSync('');

      // WHEN
      final isExportLibrary = file.isExportLibrary();

      // THEN
      expect(isExportLibrary, isFalse);
    });
    test('file with only empty lines should return false', () {
      // GIVEN
      final file = fileSystem.file('test.dart')
        ..writeAsStringSync(
          '''
        
        ''',
        );

      // WHEN
      final isExportLibrary = file.isExportLibrary();

      // THEN
      expect(isExportLibrary, isFalse);
    });
    test('file with only comments should return false', () {
      // GIVEN
      final file = fileSystem.file('test.dart')
        ..writeAsStringSync(
          '''
        // This is a comment
        // Another comment
        ''',
        );

      // WHEN
      final isExportLibrary = file.isExportLibrary();

      // THEN
      expect(isExportLibrary, isFalse);
    });
    test('file with library declaration should return true', () {
      // GIVEN
      final file = fileSystem.file('test.dart')
        ..writeAsStringSync(
          '''
        library my_library;
        ''',
        );

      // WHEN
      final isExportLibrary = file.isExportLibrary();

      // THEN
      expect(isExportLibrary, isTrue);
    });
    test('file with export declaration should return true', () {
      // GIVEN
      final file = fileSystem.file('test.dart')
        ..writeAsStringSync(
          '''
        export 'my_library.dart';
        ''',
        );

      // WHEN
      final isExportLibrary = file.isExportLibrary();

      // THEN
      expect(isExportLibrary, isTrue);
    });
    test('file with both library and export declarations should return true',
        () {
      // GIVEN
      final file = fileSystem.file('test.dart')
        ..writeAsStringSync(
          '''
        library my_library;
        export 'my_library.dart';
        ''',
        );

      // WHEN
      final isExportLibrary = file.isExportLibrary();

      // THEN
      expect(isExportLibrary, isTrue);
    });
  });
}
