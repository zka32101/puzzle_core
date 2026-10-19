/// レベルデータの共通の外枠。`spec` の中身だけがゲーム固有。
/// 文字列は埋め込まず、表示は l10n で引く。
library;

import 'storage.dart' show Json;

class LevelVerification {
  const LevelVerification({
    required this.solvable,
    this.minMoves,
    required this.solverVersion,
  });

  factory LevelVerification.fromJson(Json j) => LevelVerification(
        solvable: j['solvable']! as bool,
        minMoves: j['minMoves'] as int?,
        solverVersion: j['solverVersion']! as String,
      );

  final bool solvable;
  final int? minMoves;
  final String solverVersion;

  Json toJson() => {
        'solvable': solvable,
        'minMoves': minMoves,
        'solverVersion': solverVersion,
      };
}

class LevelEntry {
  const LevelEntry({
    required this.id,
    this.seed,
    required this.difficulty,
    required this.spec,
    this.verified,
  });

  factory LevelEntry.fromJson(Json j) => LevelEntry(
        id: j['id']! as String,
        seed: j['seed'] as int?,
        difficulty: (j['difficulty']! as num).toDouble(),
        spec: Map<String, Object?>.from(j['spec']! as Map),
        verified: j['verified'] == null
            ? null
            : LevelVerification.fromJson(
                Map<String, Object?>.from(j['verified']! as Map)),
      );

  final String id;
  final int? seed;
  final double difficulty;
  final Json spec;
  final LevelVerification? verified;

  LevelEntry withVerified(LevelVerification v) => LevelEntry(
        id: id,
        seed: seed,
        difficulty: difficulty,
        spec: spec,
        verified: v,
      );

  Json toJson() => {
        'id': id,
        if (seed != null) 'seed': seed,
        'difficulty': difficulty,
        'spec': spec,
        if (verified != null) 'verified': verified!.toJson(),
      };
}

class LevelPack {
  const LevelPack({
    this.schemaVersion = currentSchemaVersion,
    required this.game,
    required this.packId,
    required this.packVersion,
    required this.levels,
  });

  factory LevelPack.fromJson(Json j) {
    final schema = j['schemaVersion'];
    if (schema != currentSchemaVersion) {
      throw FormatException('未対応の schemaVersion: $schema');
    }
    return LevelPack(
      schemaVersion: schema! as int,
      game: j['game']! as String,
      packId: j['packId']! as String,
      packVersion: j['packVersion']! as int,
      levels: [
        for (final l in j['levels']! as List<Object?>)
          LevelEntry.fromJson(Map<String, Object?>.from(l! as Map)),
      ],
    );
  }

  static const currentSchemaVersion = 1;

  final int schemaVersion;
  final String game;
  final String packId;
  final int packVersion;
  final List<LevelEntry> levels;

  LevelPack withLevels(List<LevelEntry> l) => LevelPack(
        schemaVersion: schemaVersion,
        game: game,
        packId: packId,
        packVersion: packVersion,
        levels: l,
      );

  /// 出荷前検査。問題のある項目を文字列で返す（空なら合格）。
  /// 未検証・解けない・id重複が1件でもあれば不合格として扱う。
  List<String> validate() {
    final issues = <String>[];
    final seen = <String>{};
    for (final l in levels) {
      if (!seen.add(l.id)) issues.add('${l.id}: id が重複');
      final v = l.verified;
      if (v == null) {
        issues.add('${l.id}: 未検証');
      } else if (!v.solvable) {
        issues.add('${l.id}: 解けない');
      }
    }
    return issues;
  }

  Json toJson() => {
        'schemaVersion': schemaVersion,
        'game': game,
        'packId': packId,
        'packVersion': packVersion,
        'levels': [for (final l in levels) l.toJson()],
      };
}

/// レベル供給元の窓口（同梱 / 静的配信 / Remote Config はゲーム側で実装）。
abstract interface class LevelSource {
  Future<LevelPack> load(String packId);
}

class MemoryLevelSource implements LevelSource {
  MemoryLevelSource(Iterable<LevelPack> packs)
      : _packs = {for (final p in packs) p.packId: p};

  final Map<String, LevelPack> _packs;

  @override
  Future<LevelPack> load(String packId) async {
    final p = _packs[packId];
    if (p == null) throw StateError('パックが見つからない: $packId');
    return p;
  }
}
