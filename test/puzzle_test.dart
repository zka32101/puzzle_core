import 'package:puzzle_core/foundation.dart';
import 'package:puzzle_core/puzzle.dart';
import 'package:test/test.dart';

import 'support/color_sort.dart';

Map<String, Object?> spec(List<List<int>> tubes) => {'tubes': tubes};

void main() {
  const rules = ColorSortRules();

  test('既に完成している面は 0 手', () {
    final r = solve(
        rules,
        spec([
          [0, 0, 0, 0],
          []
        ]));
    expect(r.solvable, isTrue);
    expect(r.minMoves, 0);
  });

  test('最短手数を返す（BFS）', () {
    // 2色・空1本: [0,1,0,1] [1,0,1,0] [] は解ける。
    final r = solve(
        rules,
        spec([
          [0, 1, 0, 1],
          [1, 0, 1, 0],
          []
        ]));
    expect(r.solvable, isTrue);
    expect(r.conclusive, isTrue);
    expect(
        replayWins(
            rules,
            spec([
              [0, 1, 0, 1],
              [1, 0, 1, 0],
              []
            ]),
            r.solution!),
        isTrue);
  });

  test('詰み面は解なしと確定する', () {
    // 空き容器なし・移せない配置。
    final r = solve(
        rules,
        spec([
          [0, 1, 0, 1],
          [1, 0, 1, 0]
        ]));
    expect(r.solvable, isFalse);
    expect(r.conclusive, isTrue);
  });

  test('探索上限で打ち切ると結論未確定', () {
    final r = solve(
        rules,
        spec([
          [0, 1, 0, 1],
          [1, 0, 1, 0],
          []
        ]),
        maxStates: 2);
    expect(r.solvable, isFalse);
    expect(r.conclusive, isFalse);
  });

  test('replayWins: 違法手・未完了は false', () {
    final s = spec([
      [0, 0, 1, 1],
      [1, 1, 0, 0],
      []
    ]);
    expect(replayWins(rules, s, [(0, 1)]), isFalse); // 未完了
    expect(replayWins(rules, s, [(2, 0)]), isFalse); // 空からは動かせない
    final sol = solve(rules, s).solution!;
    expect(replayWins(rules, s, sol), isTrue);
  });

  test('LevelVerifier: 解けない面は solvable:false で残り、validate が落ちる', () {
    LevelEntry entry(String id, List<List<int>> tubes) =>
        LevelEntry(id: id, seed: 1, difficulty: 1, spec: spec(tubes));
    final pack = LevelPack(game: 'cs', packId: 'p', packVersion: 1, levels: [
      entry('ok', [
        [0, 1, 0, 1],
        [1, 0, 1, 0],
        []
      ]),
      entry('stuck', [
        [0, 1, 0, 1],
        [1, 0, 1, 0]
      ]),
    ]);
    final out =
        const LevelVerifier(rules, solverVersion: 'bfs-1').verifyPack(pack);
    expect(out.levels[0].verified!.solvable, isTrue);
    expect(out.levels[0].verified!.minMoves, isNotNull);
    expect(out.validate(), ['stuck: 解けない']);
  });

  test('randomPlayoutWinRate は同シードで再現する', () {
    final s = spec([
      [0, 1, 0, 1],
      [1, 0, 1, 0],
      []
    ]);
    final a = randomPlayoutWinRate(rules, s, seed: 7);
    final b = randomPlayoutWinRate(rules, s, seed: 7);
    expect(a, b);
    expect(a, inInclusiveRange(0, 1));
  });

  test('starsFor', () {
    expect(starsFor(5, 5), 3);
    expect(starsFor(7, 5), 2); // ceil(7.5)=8 以内
    expect(starsFor(9, 5), 1);
  });
}
