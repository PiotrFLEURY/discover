import 'package:discover/src/converters/dart_parser.dart' as parser;
import 'package:discover/src/models/code_line.dart';
import 'package:file/file.dart';

extension FileExtension on File {
  List<CodeLine> readAsCodeLinesSync() {
    final lines = readAsLinesSync();
    return lines
        .asMap()
        .entries
        .map(
          (entry) => CodeLine(
            code: entry.value,
            lineNumber: entry.key + 1,
          ),
        )
        .toList();
  }

  bool isExportLibrary() {
    final content = readAsStringSync().trim();
    return content.isNotEmpty &&
        content
            .split('\n')
            .map((line) => line.trim())
            .where((line) => line.isNotEmpty)
            .every((line) => parser.isExport(line) || parser.isLibrary(line));
  }

  bool isNotExportLibrary() => !isExportLibrary();
}
