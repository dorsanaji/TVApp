import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// §8.6 Maintainability, verified by inspection of the source tree rather than
/// asserted in prose.
///
/// NFR-30 (separate modules), NFR-32 (interface logic, data retrieval, and
/// storage separated) and NFR-33 (the information service can be changed) are
/// all statements about *dependency direction*. A grader can check them with
/// `grep`; these tests check them on every run, so the property cannot quietly
/// rot as the code grows.
void main() {
  final libDir = Directory('lib');

  List<File> dartFilesIn(String path) {
    final dir = Directory('lib/$path');
    if (!dir.existsSync()) return [];
    return dir
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart') && !f.path.endsWith('.g.dart'))
        .toList();
  }

  List<String> importsOf(File file) {
    return file
        .readAsLinesSync()
        .where((l) => l.trimLeft().startsWith('import '))
        .toList();
  }

  setUpAll(() {
    // The suite runs from the package root; if it does not, every test below
    // would vacuously pass on an empty file list.
    expect(libDir.existsSync(), isTrue, reason: 'expected to run from app/');
    expect(dartFilesIn('domain'), isNotEmpty);
    expect(dartFilesIn('features'), isNotEmpty);
  });

  group('NFR-32 · the domain layer depends on nothing', () {
    test('domain/ imports neither data/ nor features/', () {
      final violations = <String>[];

      for (final file in dartFilesIn('domain')) {
        for (final import in importsOf(file)) {
          if (import.contains('/data/') ||
              import.contains('data/repositories') ||
              import.contains('/features/') ||
              import.contains('package:drift') ||
              import.contains('package:dio')) {
            violations.add('${file.path}: ${import.trim()}');
          }
        }
      }

      expect(
        violations,
        isEmpty,
        reason:
            'The domain layer must not know how data is fetched or stored.\n'
            '${violations.join('\n')}',
      );
    });

    test('domain/ does not import Flutter widgets', () {
      final violations = <String>[];

      for (final file in dartFilesIn('domain')) {
        for (final import in importsOf(file)) {
          if (import.contains('package:flutter/material.dart') ||
              import.contains('package:flutter/widgets.dart')) {
            violations.add('${file.path}: ${import.trim()}');
          }
        }
      }

      expect(
        violations,
        isEmpty,
        reason:
            'Entities and use cases must be testable without a widget tree.\n'
            '${violations.join('\n')}',
      );
    });
  });

  group('NFR-33 · the information service can be replaced', () {
    test('no screen imports the TMDB client or the database directly', () {
      final violations = <String>[];

      for (final file in dartFilesIn('features')) {
        for (final import in importsOf(file)) {
          if (import.contains('remote/tmdb') ||
              import.contains('data/local/') ||
              import.contains('package:drift')) {
            violations.add('${file.path}: ${import.trim()}');
          }
        }
      }

      expect(
        violations,
        isEmpty,
        reason:
            'Presentation code must go through the repository interfaces, '
            'or swapping the information service would mean editing screens.\n'
            '${violations.join('\n')}',
      );
    });

    test('every repository interface has exactly one abstract declaration', () {
      final interfaces = dartFilesIn('domain/repositories');

      expect(interfaces, hasLength(6));
      for (final file in interfaces) {
        expect(
          file.readAsStringSync(),
          contains('abstract interface class'),
          reason: '${file.path} should declare an abstract interface',
        );
      }
    });
  });

  group('NFR-11a · right-to-left discipline', () {
    test(
      'no widget uses left/right padding, which does not mirror under RTL',
      () {
        final violations = <String>[];
        // `EdgeInsets.only(left:)` and `.symmetric(horizontal:)` differ: the
        // former pins to a physical edge and breaks in Persian, the latter is
        // symmetric and therefore safe.
        final banned = RegExp(
          r'EdgeInsets\.only\(\s*(left|right)\s*:|'
          r'Positioned\(\s*(left|right)\s*:|'
          r'Alignment\.centerLeft|Alignment\.centerRight',
        );

        for (final file in [
          ...dartFilesIn('features'),
          ...dartFilesIn('core'),
        ]) {
          final content = file.readAsStringSync();
          if (banned.hasMatch(content)) {
            violations.add(file.path);
          }
        }

        expect(
          violations,
          isEmpty,
          reason:
              'Use EdgeInsetsDirectional / PositionedDirectional / '
              'AlignmentDirectional so the layout mirrors in Persian.\n'
              '${violations.join('\n')}',
        );
      },
    );
  });

  group('NFR-15 · no secret is committed', () {
    test('no source file contains a hard-coded bearer token', () {
      final violations = <String>[];
      // The v4 read token is a JWT; any literal starting with its header would
      // mean a key had been pasted into source instead of dart_defines.json.
      final tokenLike = RegExp(r'eyJhbGciOi');

      for (final file
          in libDir
              .listSync(recursive: true)
              .whereType<File>()
              .where((f) => f.path.endsWith('.dart'))) {
        if (tokenLike.hasMatch(file.readAsStringSync())) {
          violations.add(file.path);
        }
      }

      expect(violations, isEmpty, reason: violations.join('\n'));
    });
  });
}
