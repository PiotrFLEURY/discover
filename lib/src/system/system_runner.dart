import 'dart:io';

import 'package:mason_logger/mason_logger.dart';

///
/// Utils class to run system commands
///
class SystemRunner {
  SystemRunner({
    required Logger logger,
  }) : _logger = logger;

  final Logger _logger;

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
        'coverage/lcov.info',
        'coverage/discover-lcov.info',
      ],
      workingDirectory: projectPath,
    );

    if (process.exitCode != 0) {
      throw Exception('Failed to run genhtml: ${process.stderr}');
    }
  }

  void runLcovRemove(
    String coverageDirectoryPath,
    List<String> ignorePatterns,
  ) {
    final process = Process.runSync(
      'lcov',
      [
        '--ignore-errors',
        'unused',
        '--remove',
        'lcov.info',
        '-o',
        'lcov.info',
        ...ignorePatterns,
      ],
      workingDirectory: coverageDirectoryPath,
    );

    if (process.exitCode != 0) {
      _logger.err('Failed to run lcov remove: ${process.stderr}');
    }
  }
}
