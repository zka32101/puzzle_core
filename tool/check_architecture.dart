// 依存方向・禁止依存・時刻直書きの検査（CI用）。
// 使い方: dart run tool/check_architecture.dart [libディレクトリ]
import 'dart:io';

const _layers = ['foundation', 'puzzle', 'kits', 'meta']; // 下 → 上

/// 直 import を禁じるパッケージ（窓口＝抽象IF越しに使う）。
const _forbiddenPackages = [
  'firebase_',
  'cloud_firestore',
  'cloud_functions',
  'google_mobile_ads',
  'in_app_purchase',
  'app_common_kit',
  'shared_core',
];

/// 純Dartに保つ層。
const _pureLayers = {'foundation', 'puzzle'};

final _importRe = RegExp(r'''^\s*(?:import|export)\s+['"]([^'"]+)['"]''');

List<String> checkArchitecture(Directory lib) {
  final violations = <String>[];
  final root = lib.absolute.path;
  for (final f in lib.listSync(recursive: true).whereType<File>()) {
    if (!f.path.endsWith('.dart')) continue;
    final rel =
        f.absolute.path.substring(root.length + 1).replaceAll(r'\', '/');
    final layer = _layerOfPath(rel);
    final lines = f.readAsLinesSync();
    for (var i = 0; i < lines.length; i++) {
      final where = '$rel:${i + 1}';
      final line = lines[i];
      final trimmed = line.trimLeft();
      if (!trimmed.startsWith('//') &&
          line.contains('DateTime.now()') &&
          rel != 'foundation/clock.dart') {
        violations.add('$where: DateTime.now() 直書き（Clock を注入する）');
      }
      final m = _importRe.firstMatch(line);
      if (m == null) continue;
      final uri = m.group(1)!;
      if (uri.startsWith('package:')) {
        final pkg = uri.substring(8).split('/').first;
        for (final bad in _forbiddenPackages) {
          if (pkg.startsWith(bad)) {
            violations.add('$where: 禁止依存 $pkg（抽象IF越しに使う）');
          }
        }
        if (pkg == 'flutter' && _pureLayers.contains(layer)) {
          violations.add('$where: $layer は純Dartに保つ（flutter を import しない）');
        }
        if (pkg == 'puzzle_core') {
          final target =
              _layerOfPath(uri.substring('package:puzzle_core/'.length));
          _checkDirection(violations, where, layer, target);
        }
      } else if (!uri.startsWith('dart:')) {
        final resolved = f.absolute.uri.resolve(uri).toFilePath();
        if (resolved.startsWith(root)) {
          final target = _layerOfPath(
              resolved.substring(root.length + 1).replaceAll(r'\', '/'));
          _checkDirection(violations, where, layer, target);
        }
      }
    }
  }
  return violations;
}

String? _layerOfPath(String p) {
  final first = p.split('/').first.replaceAll('.dart', '');
  return _layers.contains(first) ? first : null;
}

void _checkDirection(List<String> out, String where, String? from, String? to) {
  if (from == null || to == null) return;
  if (_layers.indexOf(to) > _layers.indexOf(from)) {
    out.add(
        '$where: 逆参照 $from → $to（依存は foundation ← puzzle ← kits ← meta のみ）');
  }
}

void main(List<String> args) {
  final dir = Directory(args.isEmpty ? 'lib' : args.first);
  final v = checkArchitecture(dir);
  if (v.isEmpty) {
    stdout.writeln('architecture OK');
    return;
  }
  v.forEach(stderr.writeln);
  exit(1);
}
