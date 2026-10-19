import 'storage.dart';

class LevelRecord {
  const LevelRecord({
    this.cleared = false,
    this.stars = 0,
    this.bestMoves,
    this.attempts = 0,
  });

  factory LevelRecord.fromJson(Json j) => LevelRecord(
        cleared: j['cleared']! as bool,
        stars: j['stars']! as int,
        bestMoves: j['bestMoves'] as int?,
        attempts: j['attempts']! as int,
      );

  final bool cleared;
  final int stars;
  final int? bestMoves;
  final int attempts;

  Json toJson() => {
        'cleared': cleared,
        'stars': stars,
        'bestMoves': bestMoves,
        'attempts': attempts,
      };
}

/// 進行状況（不変）。星・クリア履歴・現在レベル。
class Progress {
  const Progress({this.currentLevelIndex = 0, this.records = const {}});

  factory Progress.fromJson(Json j) => Progress(
        currentLevelIndex: j['currentLevelIndex']! as int,
        records: {
          for (final e in (j['records']! as Map).entries)
            e.key as String:
                LevelRecord.fromJson(Map<String, Object?>.from(e.value as Map)),
        },
      );

  final int currentLevelIndex;
  final Map<String, LevelRecord> records;

  LevelRecord recordOf(String levelId) =>
      records[levelId] ?? const LevelRecord();

  int get totalStars => records.values.fold(0, (a, r) => a + r.stars);

  Progress recordFail(String levelId) {
    final r = recordOf(levelId);
    return _with(
      levelId,
      LevelRecord(
        cleared: r.cleared,
        stars: r.stars,
        bestMoves: r.bestMoves,
        attempts: r.attempts + 1,
      ),
    );
  }

  /// クリアを記録する。星・最少手数は良い方を保持し、現在レベルは進める一方（戻さない）。
  Progress recordWin(
    String levelId, {
    required int stars,
    required int moves,
    required int levelIndex,
  }) {
    final r = recordOf(levelId);
    final best =
        r.bestMoves == null || moves < r.bestMoves! ? moves : r.bestMoves;
    final next = _with(
      levelId,
      LevelRecord(
        cleared: true,
        stars: stars > r.stars ? stars : r.stars,
        bestMoves: best,
        attempts: r.attempts + 1,
      ),
    );
    final idx = levelIndex + 1;
    return Progress(
      currentLevelIndex: idx > currentLevelIndex ? idx : currentLevelIndex,
      records: next.records,
    );
  }

  Progress _with(String id, LevelRecord r) => Progress(
      currentLevelIndex: currentLevelIndex, records: {...records, id: r});

  Json toJson() => {
        'currentLevelIndex': currentLevelIndex,
        'records': {for (final e in records.entries) e.key: e.value.toJson()},
      };
}

abstract interface class ProgressStore {
  Future<Progress> load();
  Future<void> save(Progress p);
}

class KeyValueProgressStore implements ProgressStore {
  const KeyValueProgressStore(this.store, {this.key = 'progress'});

  static const schemaVersion = 1;

  final KeyValueStore store;
  final String key;

  @override
  Future<Progress> load() async {
    final j = await VersionedJsonStore(store)
        .load(key, currentVersion: schemaVersion);
    return j == null ? const Progress() : Progress.fromJson(j);
  }

  @override
  Future<void> save(Progress p) =>
      VersionedJsonStore(store).save(key, schemaVersion, p.toJson());
}
