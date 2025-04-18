import 'package:discover/src/converters/dart_parser.dart' as parser;
import 'package:discover/src/extensions/extensions.dart';
import 'package:discover/src/models/code_line.dart';
import 'package:file/file.dart';
import 'package:mason_logger/mason_logger.dart';

/// Utils class to convert Dart code coverage to lcov format
///
/// LCOV format:
///
/// SF:path/to/file.dart
/// DA:1,0
/// LF:[total lines]
/// LH:[lines hit]
/// end_of_record
///
class LcovConverter {
  LcovConverter({
    Logger? logger,
  }) : _logger = logger ?? Logger();

  /// Logger instance
  final Logger _logger;

  ///
  /// Writes the LCOV file to the specified path
  ///
  void writeLcovFile(
    List<File> dartFiles,
    File lcovFile,
  ) {
    if (dartFiles.isEmpty) {
      _logger.warn('No Dart files found.');
      return;
    }
    _logger.info('Writing LCOV file to ${lcovFile.path}');
    final dartFilesMap = <String, List<CodeLine>>{};
    for (final file in dartFiles) {
      final lines = file.readAsCodeLinesSync();
      filterIgnoredLines(lines);
      if (lines.isEmpty) {
        _logger.warn('File ${file.path} is empty.');
      } else {
        dartFilesMap[file.libPath] = lines;
      }
    }
    final lcovContent = _generateLcov(dartFilesMap);
    lcovFile.writeAsStringSync(lcovContent);
  }

  String _generateLcov(Map<String, List<CodeLine>> files) {
    _logger.info('Converting ${files.length} files to LCOV format.');
    final buffer = StringBuffer();

    for (final entry in files.entries) {
      final filePath = entry.key;
      final lines = entry.value;

      buffer.write(_fileToLcov(filePath, lines));
    }

    buffer.writeln('end_of_record');

    _logger.info('LCOV conversion completed.');

    return buffer.toString();
  }

  ///
  /// Converts a single file to LCOV format
  ///
  String _fileToLcov(String filePath, List<CodeLine> lines) {
    _logger.info('Converting file: $filePath');
    final buffer = StringBuffer()..writeln('SF:$filePath');

    var lineCount = 0;
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      if (line.isNotEmpty) {
        buffer.writeln('DA:${line.lineNumber},0');
        lineCount++;
      }
    }

    buffer
      ..writeln('LF:$lineCount')
      ..writeln('LH:0');

    _logger.info('Converted $lineCount lines in file: $filePath');

    return buffer.toString();
  }

  ///
  /// Filters out lines that match the ignored patterns
  ///
  /// Ignored patterns include:
  /// imports, part, part of, class, mixin, extension, closing statement,
  /// return statement, functions and constructors
  ///
  void filterIgnoredLines(List<CodeLine> lines) {
    for (var i = lines.length - 1; i >= 0; i--) {
      final line = lines[i];
      if (parser.shouldIgnoreLine(line.code)) {
        lines.removeAt(i);
      }
    }
  }
}
