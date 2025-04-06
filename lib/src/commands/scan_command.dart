import 'package:args/command_runner.dart';
import 'package:discover/src/converters/lcov_converter.dart';
import 'package:discover/src/extensions/extensions.dart';
import 'package:discover/src/system/system_runner.dart';
import 'package:file/file.dart';
import 'package:glob/glob.dart';
import 'package:mason_logger/mason_logger.dart';

/// {@template scan_command}
///
/// `discover scan`
/// A [Command] to scan the current directory for Dart files.
/// {@endtemplate}
class ScanCommand extends Command<int> {
  /// {@macro scan_command}
  ScanCommand({
    required Logger logger,
    required FileSystem fileSystem,
    required LcovConverter lcovConverter,
    required SystemRunner systemRunner,
  })  : _logger = logger,
        _fileSystem = fileSystem,
        _lcovConverter = lcovConverter,
        _systemRunner = systemRunner {
    argParser.addOption(
      'path',
      abbr: 'p',
      help: 'The path to scan for Dart files.',
      defaultsTo: '.',
    );
  }

  @override
  String get description => 'Scan the specified directory for Dart files.';

  @override
  String get name => 'scan';

  final Logger _logger;
  final FileSystem _fileSystem;
  final LcovConverter _lcovConverter;
  final SystemRunner _systemRunner;

  @override
  Future<int> run() async {
    _logger.info('Scanning directory: ${argResults?['path']}');
    final path = argResults?['path'] as String;
    final projectDirectory = path == '.'
        ? _fileSystem.currentDirectory
        : _fileSystem.currentDirectory.childDirectory(path);
    final libDirectory = projectDirectory.childDirectory('lib');
    if (!libDirectory.existsSync()) {
      _logger.err('lib directory does not exist');
      return ExitCode.noInput.code;
    }

    final dartFiles = listDartFiles(libDirectory);

    applyIgnoreFile(projectDirectory, dartFiles);

    if (dartFiles.isEmpty) {
      _logger.err('No Dart files found in ${libDirectory.path}');
      return ExitCode.noInput.code;
    } else {
      _logger.info('Found ${dartFiles.length} Dart files:');
      for (final file in dartFiles) {
        _logger.info(file.libPath);
      }
    }

    // Search for coverage file
    final coverageDirectory = projectDirectory.childDirectory('coverage');
    if (!coverageDirectory.existsSync()) {
      _logger.info('No coverage directory found.');
      _generateCoverage(projectDirectory.path);
    }

    final coverageFile = coverageDirectory.childFile('lcov.info');
    if (coverageFile.existsSync()) {
      _logger.info('Coverage file found.');
    } else {
      _logger.info('No coverage file found.');
      return ExitCode.noInput.code;
    }

    // List source files listed in the coverage file
    final sourceFiles = _readSourceFilesFromCoverage(coverageFile);

    // Compute dart files found but not listed in coverage file
    final dartFilesNotInCoverage = dartFiles
        .where(
          (file) => !sourceFiles.contains(file.libPath),
        )
        .toList();
    if (dartFilesNotInCoverage.isNotEmpty) {
      _logger.info('Some Dart files are not listed in coverage file:');
      for (final file in dartFilesNotInCoverage) {
        _logger.info(file.libPath);
      }
      generateLcovFile(coverageDirectory, dartFilesNotInCoverage);
      generateHtmlReport(projectDirectory.path);
    } else {
      _logger.info('All Dart files are listed in the coverage file.');
    }

    return ExitCode.success.code;
  }

  void applyIgnoreFile(
    Directory projectDirectory,
    List<File> dartFiles,
  ) {
    final ignoreFile = projectDirectory.childFile('.discoverignore');
    if (ignoreFile.existsSync()) {
      final ignorePatterns = ignoreFile.readAsLinesSync();
      _logger.info('Applying ignore patterns from .discoverignore:');
      for (final pattern in ignorePatterns) {
        _logger.info(pattern);
        final glob = Glob(pattern);
        dartFiles.removeWhere((file) {
          final matching = glob.matches(file.libPath);
          if (matching) {
            _logger.info(
              'Ignoring file ${file.libPath} matching pattern $pattern',
            );
          }
          return matching;
        });
      }
    } else {
      _logger.info('No .discoverignore file found.');
    }
  }

  List<File> listDartFiles(Directory libDirectory) {
    return libDirectory
        .listSync(recursive: true)
        .where((entity) => entity.path.endsWith('.dart'))
        .map((entity) => entity as File)
        .where((file) => file.isNotExportLibrary())
        .toList();
  }

  List<String> _readSourceFilesFromCoverage(File coverageFile) {
    final coverageLines = coverageFile.readAsLinesSync();
    final sourceFiles = coverageLines
        .where((line) => line.startsWith('SF:'))
        .map((line) => line.substring(3).trim())
        .toList();
    _logger.info('Source files listed in coverage file:');
    for (final sourceFile in sourceFiles) {
      _logger.info(sourceFile);
    }
    return sourceFiles;
  }

  void generateLcovFile(
    Directory coverageDirectory,
    List<File> dartFilesNotInCoverage,
  ) {
    _logger.info(
      'Generating lcov file for Dart files not listed in coverage file.',
    );
    final lcovFile = coverageDirectory.childFile('discover-lcov.info');
    if (lcovFile.existsSync()) {
      lcovFile.deleteSync();
    }
    _lcovConverter.writeLcovFile(dartFilesNotInCoverage, lcovFile);
  }

  void _generateCoverage(String projectPath) {
    _systemRunner.runFlutterCoverage(projectPath);
  }

  void generateHtmlReport(String projectPath) {
    _systemRunner.runGenHTML(projectPath);
    final fullPath = '$projectPath/coverage/html/index.html';
    final reportLink = link(
      message: fullPath,
      uri: Uri.parse(
        'file://$fullPath',
      ),
    );
    _logger.success('HTML report generated at $reportLink');
  }
}
