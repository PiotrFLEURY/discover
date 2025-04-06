import 'dart:io';

///
/// Utils class to run system commands
///
class SystemRunner {
  ///
  /// Runs flutter test --coverage command
  ///
  void runFlutterCoverage(
    String projectPath,
  ) {
    final process = Process.runSync(
      'flutter',
      [
        'test',
        '--coverage',
      ],
      workingDirectory: projectPath,
    );

    if (process.exitCode != 0) {
      throw Exception('Failed to run flutter test: ${process.stderr}');
    }
  }

  ///
  /// Runs genhtml command to generate HTML report from LCOV file
  ///
  void runGenHTML(
    String projectPath,
  ) {
    final process = Process.runSync(
      'genhtml',
      [
        '-o',
        'coverage/html',
        'coverage/**lcov.info',
      ],
      workingDirectory: projectPath,
    );

    if (process.exitCode != 0) {
      throw Exception('Failed to run genhtml: ${process.stderr}');
    }
  }
}
