import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:cli_completion/cli_completion.dart';
import 'package:discover/src/command_runner.dart';
import 'package:discover/src/system/system_runner.dart';
import 'package:discover/src/version.dart';
import 'package:file/memory.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pub_updater/pub_updater.dart';
import 'package:test/test.dart';

class _MockLogger extends Mock implements Logger {}

class _MockProgress extends Mock implements Progress {}

class _MockPubUpdater extends Mock implements PubUpdater {}

class _MockSystemRunner extends Mock implements SystemRunner {}

const latestVersion = '0.0.0';

final updatePrompt = '''
${lightYellow.wrap('Update available!')} ${lightCyan.wrap(packageVersion)} \u2192 ${lightCyan.wrap(latestVersion)}
Run ${lightCyan.wrap('$executableName update')} to update''';

void main() {
  group('DiscoverCommandRunner', () {
    late PubUpdater pubUpdater;
    late Logger logger;
    late DiscoverCommandRunner commandRunner;
    late MemoryFileSystem memoryFileSystem;
    late SystemRunner systemRunner;

    setUp(() {
      pubUpdater = _MockPubUpdater();

      when(
        () => pubUpdater.getLatestVersion(any()),
      ).thenAnswer((_) async => packageVersion);

      logger = _MockLogger();

      memoryFileSystem = MemoryFileSystem();

      systemRunner = _MockSystemRunner();

      commandRunner = DiscoverCommandRunner(
        logger: logger,
        pubUpdater: pubUpdater,
        fileSystem: memoryFileSystem,
        systemRunner: systemRunner,
      );
    });

    test('shows update message when newer version exists', () async {
      when(
        () => pubUpdater.getLatestVersion(any()),
      ).thenAnswer((_) async => latestVersion);

      final result = await commandRunner.run(['--version']);
      expect(result, equals(ExitCode.success.code));
      verify(() => logger.info(updatePrompt)).called(1);
    });

    test(
      'Does not show update message when the shell calls the '
      'completion command',
      () async {
        when(
          () => pubUpdater.getLatestVersion(any()),
        ).thenAnswer((_) async => latestVersion);

        final result = await commandRunner.run(['completion']);
        expect(result, equals(ExitCode.success.code));
        verifyNever(() => logger.info(updatePrompt));
      },
    );

    test('does not show update message when using update command', () async {
      when(
        () => pubUpdater.getLatestVersion(any()),
      ).thenAnswer((_) async => latestVersion);
      when(
        () => pubUpdater.update(
          packageName: packageName,
          versionConstraint: any(named: 'versionConstraint'),
        ),
      ).thenAnswer(
        (_) async => ProcessResult(0, ExitCode.success.code, null, null),
      );
      when(
        () => pubUpdater.isUpToDate(
          packageName: any(named: 'packageName'),
          currentVersion: any(named: 'currentVersion'),
        ),
      ).thenAnswer((_) async => true);

      final progress = _MockProgress();
      final progressLogs = <String>[];
      when(() => progress.complete(any())).thenAnswer((answer) {
        final message = answer.positionalArguments.elementAt(0) as String?;
        if (message != null) progressLogs.add(message);
      });
      when(() => logger.progress(any())).thenReturn(progress);

      final result = await commandRunner.run(['update']);
      expect(result, equals(ExitCode.success.code));
      verifyNever(() => logger.info(updatePrompt));
    });

    test('can be instantiated without an explicit analytics/logger instance',
        () {
      final commandRunner = DiscoverCommandRunner();
      expect(commandRunner, isNotNull);
      expect(commandRunner, isA<CompletionCommandRunner<int>>());
    });

    test('handles FormatException', () async {
      const exception = FormatException('oops!');
      var isFirstInvocation = true;
      when(() => logger.info(any())).thenAnswer((_) {
        if (isFirstInvocation) {
          isFirstInvocation = false;
          throw exception;
        }
      });
      final result = await commandRunner.run(['--version']);
      expect(result, equals(ExitCode.usage.code));
      verify(() => logger.err(exception.message)).called(1);
      verify(() => logger.info(commandRunner.usage)).called(1);
    });

    test('handles UsageException', () async {
      final exception = UsageException('oops!', 'exception usage');
      var isFirstInvocation = true;
      when(() => logger.info(any())).thenAnswer((_) {
        if (isFirstInvocation) {
          isFirstInvocation = false;
          throw exception;
        }
      });
      final result = await commandRunner.run(['--version']);
      expect(result, equals(ExitCode.usage.code));
      verify(() => logger.err(exception.message)).called(1);
      verify(() => logger.info('exception usage')).called(1);
    });

    group('--version', () {
      test('outputs current version', () async {
        final result = await commandRunner.run(['--version']);
        expect(result, equals(ExitCode.success.code));
        verify(() => logger.info(packageVersion)).called(1);
      });
    });

    group('--verbose', () {
      test('enables verbose logging', () async {
        final result = await commandRunner.run(['--verbose']);
        expect(result, equals(ExitCode.success.code));

        verify(() => logger.detail('Argument information:')).called(1);
        verify(() => logger.detail('  Top level options:')).called(1);
        verify(() => logger.detail('  - verbose: true')).called(1);
        verifyNever(() => logger.detail('    Command options:'));
      });

      test('enables verbose logging for sub commands', () async {
        // GIVEN
        memoryFileSystem.currentDirectory
            .childDirectory('coverage')
            .childFile('lcov.info')
            .createSync(recursive: true);
        memoryFileSystem.currentDirectory
            .childDirectory('lib')
            .childFile('main.dart')
            .createSync(recursive: true);

        when(() => systemRunner.runFlutterCoverage(any())).thenAnswer(
          (_) async => memoryFileSystem.currentDirectory
              .childDirectory('coverage')
              .childFile('lcov.info')
              .createSync(recursive: true),
        );

        when(() => logger.progress(any())).thenReturn(_MockProgress());

        // WHEN
        final result = await commandRunner.run([
          '--verbose',
          'scan',
          '--path',
          '.',
        ]);

        // THEN
        expect(result, equals(ExitCode.success.code));

        verify(() => logger.detail('Argument information:')).called(1);
        verify(() => logger.detail('  Top level options:')).called(1);
        verify(() => logger.detail('  - verbose: true')).called(1);
        verify(() => logger.detail('  Command: scan')).called(1);
        verify(() => logger.detail('    Command options:')).called(1);
        verify(() => logger.detail('    - path: .')).called(1);
      });
    });
  });
}
