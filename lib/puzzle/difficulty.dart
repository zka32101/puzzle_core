import 'dart:math';

import 'rules.dart';

/// ランダムに指したときの勝率（0〜1）。シード固定で再現可能。
/// 難易度指標の一つ（マッチ3系など、最短手数が測れない／意味が薄いゲーム向け）。
double randomPlayoutWinRate<S, M>(
  PuzzleRules<S, M> rules,
  Map<String, Object?> spec, {
  int playouts = 200,
  int maxSteps = 200,
  int seed = 0,
}) {
  final rnd = Random(seed);
  var wins = 0;
  for (var i = 0; i < playouts; i++) {
    var s = rules.initial(spec);
    for (var step = 0; step < maxSteps && !rules.isWon(s); step++) {
      final moves = rules.legalMoves(s);
      if (moves.isEmpty) break;
      s = rules.apply(s, moves[rnd.nextInt(moves.length)]);
    }
    if (rules.isWon(s)) wins++;
  }
  return wins / playouts;
}

/// 星計算。最短手数以内で3、最短の [twoStarFactor] 倍以内で2、それ以外は1。
int starsFor(
  int moves,
  int minMoves, {
  double twoStarFactor = 1.5,
}) {
  if (moves <= minMoves) return 3;
  if (moves <= (minMoves * twoStarFactor).ceil()) return 2;
  return 1;
}
