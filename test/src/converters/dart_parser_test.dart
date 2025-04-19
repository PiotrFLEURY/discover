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
    test('comments', () {
      // GIVEN
      const line = ' // This is a comment with a trailing space';

      // WHEN
      final shouldIgnore = parser.shouldIgnoreLine(line);

      // THEN
      expect(shouldIgnore, isTrue);
    });
    test('import', () {
      // GIVEN
      const line = "import 'package:flutter/material.dart';";

      // WHEN
      final shouldIgnore = parser.shouldIgnoreLine(line);

      // THEN
      expect(shouldIgnore, isTrue);
    });
    test('export', () {
      // GIVEN
      const line = "export 'package:flutter/foundation.dart';";

      // WHEN
      final shouldIgnore = parser.shouldIgnoreLine(line);

      // THEN
      expect(shouldIgnore, isTrue);
    });
    test('part', () {
      // GIVEN
      const line = "part 'car.g.dart';";

      // WHEN
      final shouldIgnore = parser.shouldIgnoreLine(line);

      // THEN
      expect(shouldIgnore, isTrue);
    });
    test('class', () {
      // GIVEN
      const line = 'class Car {';

      // WHEN
      final shouldIgnore = parser.shouldIgnoreLine(line);

      // THEN
      expect(shouldIgnore, isTrue);
    });
    test('mixin', () {
      // GIVEN
      const line = 'mixin Vehicle {';

      // WHEN
      final shouldIgnore = parser.shouldIgnoreLine(line);

      // THEN
      expect(shouldIgnore, isTrue);
    });
    test('extension', () {
      // GIVEN
      const line = 'extension Vehicle on Car {';

      // WHEN
      final shouldIgnore = parser.shouldIgnoreLine(line);

      // THEN
      expect(shouldIgnore, isTrue);
    });
    test('return', () {
      // GIVEN
      const line = 'return Car();';

      // WHEN
      final shouldIgnore = parser.shouldIgnoreLine(line);

      // THEN
      expect(shouldIgnore, isTrue);
    });
    test('closing curly brace', () {
      // GIVEN
      const line = '}';

      // WHEN
      final shouldIgnore = parser.shouldIgnoreLine(line);

      // THEN
      expect(shouldIgnore, isTrue);
    });
    test('closing parenthesis', () {
      // GIVEN
      const line = ');';

      // WHEN
      final shouldIgnore = parser.shouldIgnoreLine(line);

      // THEN
      expect(shouldIgnore, isTrue);
    });
    test('method', () {
      // GIVEN
      const line = 'void startEngine() {';

      // WHEN
      final shouldIgnore = parser.shouldIgnoreLine(line);

      // THEN
      expect(shouldIgnore, isTrue);
    });
    test('field', () {
      // GIVEN
      const line = 'final String brand;';

      // WHEN
      final shouldIgnore = parser.shouldIgnoreLine(line);

      // THEN
      expect(shouldIgnore, isFalse);
    });
  });
}
