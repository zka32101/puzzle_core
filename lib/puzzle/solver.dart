import 'dart:collection';

import 'rules.dart';

class SolveResult<M> {
  const SolveResult({
    required this.solvable,
    required this.conclusive,
    this.solution,
    required this.exploredStates,
  });

  /// 解が見つかったか。
  final bool solvable;

  /// 結論が確定しているか。探索上限で打ち切られ解なしの場合は false
  /// （検証では不合格として扱う）。
  final bool conclusive;

  /// 最短手順（BFS のため最短）。
  final List<M>? solution;

  final int exploredStates;

  int? get minMoves => solution?.length;
}

/// 幅優先探索で解の有無と最短手数を求める。
/// [maxStates] を超えたら打ち切り（`conclusive: false`）。
SolveResult<M> solve<S, M>(
  PuzzleRules<S, M> rules,
  Map<String, Object?> spec, {
  int maxStates = 200000,
}) {
  final start = rules.initial(spec);
  final startHash = rules.hash(start);
  if (rules.isWon(start)) {
    return SolveResult<M>(
        solvable: true,
        conclusive: true,
        solution: const [],
        exploredStates: 1);
  }
  final parent = <String, (String, M)>{};
  final seen = <String>{startHash};
  final queue = Queue<(S, String)>()..add((start, startHash));

  while (queue.isNotEmpty) {
    final (state, h) = queue.removeFirst();
    for (final m in rules.legalMoves(state)) {
      final next = rules.apply(state, m);
      final nh = rules.hash(next);
      if (!seen.add(nh)) continue;
      parent[nh] = (h, m);
      if (rules.isWon(next)) {
        final path = <M>[];
        var cur = nh;
        while (cur != startHash) {
          final (p, mv) = parent[cur]!;
          path.add(mv);
          cur = p;
        }
        return SolveResult<M>(
          solvable: true,
          conclusive: true,
          solution: path.reversed.toList(),
          exploredStates: seen.length,
        );
      }
      if (seen.length >= maxStates) {
        return SolveResult<M>(
            solvable: false, conclusive: false, exploredStates: seen.length);
      }
      if (!rules.isLost(next)) queue.add((next, nh));
    }
  }
  return SolveResult<M>(
      solvable: false, conclusive: true, exploredStates: seen.length);
}

/// 手順ログを再生して「全手が合法で最後に勝つ」かを検証する
/// （ランキング提出時の不正対策に使う）。
bool replayWins<S, M>(
  PuzzleRules<S, M> rules,
  Map<String, Object?> spec,
  List<M> moves,
) {
  var s = rules.initial(spec);
  for (final m in moves) {
    if (!rules.legalMoves(s).contains(m)) return false;
    s = rules.apply(s, m);
  }
  return rules.isWon(s);
}
