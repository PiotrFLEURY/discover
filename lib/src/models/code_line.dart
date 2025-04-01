///
/// Represents a line of code in a Dart file.
///
class CodeLine {
  const CodeLine({
    required this.code,
    required this.lineNumber,
  });

  final String code;
  final int lineNumber;

  String trim() => code.trim();

  bool get isEmpty => trim().isEmpty;

  bool get isNotEmpty => trim().isNotEmpty;

  bool get isExport => trim().startsWith('export');

  bool get isLibrary => trim().startsWith('library');

  bool get isComment => trim().startsWith('//');
}
