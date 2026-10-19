import 'dart:io';

import 'package:test/test.dart';

import '../tool/check_architecture.dart';

void main() {
  test('puzzle_core 自身の lib は検査に合格する', () {
    expect(checkArchitecture(Directory('lib')), isEmpty);
  });

  group('違反の検出', () {
    late Directory tmp;
    setUp(() => tmp = Directory.systemTemp.createTempSync('arch'));
    tearDown(() => tmp.deleteSync(recursive: true));

    File write(String rel, String body) {
      final f = File('${tmp.path}/$rel')..createSync(recursive: true);
      return f..writeAsStringSync(body);
    }

    test('逆参照・禁止依存・flutter・DateTime.now()', () {
      write('foundation/a.dart', "import '../puzzle/b.dart';\n");
      write('puzzle/b.dart', '''
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
final t = DateTime.now();
''');
      write('foundation/clock.dart', 'final t = DateTime.now();\n');
      final v = checkArchitecture(tmp);
      expect(v.where((e) => e.contains('逆参照')), hasLength(1));
      expect(v.where((e) => e.contains('禁止依存')), hasLength(1));
      expect(v.where((e) => e.contains('純Dart')), hasLength(1));
      expect(v.where((e) => e.contains('DateTime.now()')), hasLength(1));
    });

    test('package: 形式の逆参照も検出', () {
      write('puzzle/c.dart', "import 'package:puzzle_core/meta.dart';\n");
      expect(checkArchitecture(tmp), hasLength(1));
    });
  });
}
