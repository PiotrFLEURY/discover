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

  bool isNotEmpty() {
    return existsSync() &&
        readAsCodeLinesSync()
            .where((line) => line.isNotEmpty && !line.isComment)
            .isNotEmpty;
  }

  bool isExportLibrary() {
    return isNotEmpty() &&
        readAsCodeLinesSync()
            .where((line) => line.isNotEmpty)
            .every((line) => line.isExport || line.isLibrary);
  }

  bool isNotExportLibrary() => !isExportLibrary();
}
