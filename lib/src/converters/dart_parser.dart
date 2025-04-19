const importRegex = '^import\\s+["\'](.*)["\'];\$';
const partRegex = '^\\s*part\\s*(of)*\\s+["\'](.*)["\'];\$';
const commentRegex = r'^\s*//.*$';
const classDeclarationRegex = r'^\s*class\s+(\w+[<]*.*[>]*\s*)*\s*{*$';
const mixinDeclarationRegex = r'^\s*mixin\s+(\w+[<]*.*[>]*\s*)*\s*{$';
const extensionDeclarationRegex = r'^\s*extension\s+(\w+)\s+on\s+(\w+)\s*{$';
const closingStatementRegex = r'^\s*([\)\]};],*)+\s*$';
const returnStatementRegex = r'^\s*return\s+.*;$';
const constructorDeclarationRegex =
    r'^\s*(const\s)*[A-Z](\w+)([\.]\w+)*\s*\(.*$';
const methodDeclarationRegex = r'^\s*(\w+)(<\w+>)*\s+([a-z]\w+)+\s*\(.*$';

final closingStatementRegexpr = RegExp(closingStatementRegex);
final constructorDeclarationRegexpr = RegExp(constructorDeclarationRegex);
final methodDeclarationRegexpr = RegExp(methodDeclarationRegex);

/// List of regex patterns to ignore
final List<RegExp> ignoredLines = [
  //RegExp(importRegex),
  //RegExp(partRegex),
  //RegExp(commentRegex),
  //RegExp(classDeclarationRegex),
  //RegExp(mixinDeclarationRegex),
  //RegExp(extensionDeclarationRegex),
  //RegExp(returnStatementRegex),
  RegExp(closingStatementRegex),
  RegExp(constructorDeclarationRegex),
  RegExp(methodDeclarationRegex),
];

bool shouldIgnoreLine(String line) {
  final trimmedLine = line.trim();
  return trimmedLine.isEmpty ||
      trimmedLine.startsWith('//') ||
      trimmedLine.startsWith('import') ||
      trimmedLine.startsWith('export') ||
      trimmedLine.startsWith('part') ||
      trimmedLine.startsWith('class') ||
      trimmedLine.startsWith('mixin') ||
      trimmedLine.startsWith('extension') ||
      trimmedLine.startsWith('return') ||
      ignoredLines.any((regex) => regex.hasMatch(trimmedLine));
}

bool isExport(String line) {
  return line.trim().startsWith('export');
}

bool isLibrary(String line) {
  return line.trim().startsWith('library');
}
