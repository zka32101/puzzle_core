import '../foundation/level.dart';
import 'rules.dart';
import 'solver.dart';

/// 出荷前のレベル検証。全レベルをソルバーで解き、`verified` を書き込む。
/// 解けない（または探索打ち切り）レベルは `solvable: false` として残す。
class LevelVerifier<S, M> {
  const LevelVerifier(
    this.rules, {
    required this.solverVersion,
    this.maxStates = 200000,
  });

  final PuzzleRules<S, M> rules;
  final String solverVersion;
  final int maxStates;

  LevelEntry verify(LevelEntry level) {
    final r = solve(rules, level.spec, maxStates: maxStates);
    return level.withVerified(LevelVerification(
      solvable: r.solvable && r.conclusive,
      minMoves: r.minMoves,
      solverVersion: solverVersion,
    ));
  }

  /// パック全体を検証して返す。結果は `LevelPack.validate()` で合否を確認する。
  LevelPack verifyPack(LevelPack pack) =>
      pack.withLevels([for (final l in pack.levels) verify(l)]);
}
