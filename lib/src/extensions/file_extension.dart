import 'package:file/file.dart';

extension FileExtension on File {
  List<String> readAsCodeLinesSync() {
    final lines = readAsLinesSync();
    return lines
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty && !line.startsWith('//'))
        .toList();
  }

  bool isNotEmpty() {
    return existsSync() &&
        readAsCodeLinesSync()
            .where((line) => line.trim().isNotEmpty)
            .isNotEmpty;
  }

  bool isExportLibrary() {
    return isNotEmpty() &&
        readAsCodeLinesSync()
            .every((line) => _isExport(line) || _isLibrary(line));
  }

  bool isNotExportLibrary() => !isExportLibrary();

  bool _isExport(String line) {
    return line.startsWith('export');
  }

  bool _isLibrary(String line) {
    return line.startsWith('library');
  }
}
