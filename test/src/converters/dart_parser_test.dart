import 'package:discover/src/converters/dart_parser.dart' as parser;
import 'package:test/test.dart';

void main() {
  group('should ignore line', () {
    test('real life example', () {
      // GIVEN
      const line = '    DeviceOrientation.portraitUp,';

      // WHEN
      final startTime = DateTime.now();
      final shouldIgnore = parser.shouldIgnoreLine(line);
      final endTime = DateTime.now();
      final duration = endTime.difference(startTime);

      // THEN
      expect(shouldIgnore, isFalse);
      expect(
        duration.inMilliseconds,
        lessThan(5),
        reason: 'Got $duration for $line',
      );
    });
    test('real life example', () {
      // GIVEN
      const lines = '''
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freenance/app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(
    ProviderScope(
      child: const Freenance(),
    ),
  );
}

''';

      // WHEN
      final results = <String, (bool, Duration)>{};
      for (final line in lines.split('\n')) {
        final startTime = DateTime.now();
        final shouldIgnore = parser.shouldIgnoreLine(line);
        final endTime = DateTime.now();
        final duration = endTime.difference(startTime);
        results[line] = (shouldIgnore, duration);
      }

      // THEN
      for (final entry in results.entries) {
        final line = entry.key;
        final (shouldIgnore, duration) = entry.value;
        expect(
          duration.inMilliseconds,
          lessThan(5),
          reason: 'Got $duration for $line',
        );
      }
    });
  });
}
