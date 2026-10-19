import 'package:puzzle_core/puzzle.dart';

/// テスト用の最小「色ソート」ルール（容器スロット4）。
/// 状態は容器ごとの色リスト（下→上）の並び。実ゲームの Rules とは別物。
typedef Tubes = List<List<int>>;
typedef Move = (int from, int to);

const tubeCap = 4;

class ColorSortRules extends PuzzleRules<Tubes, Move> {
  const ColorSortRules();

  @override
  Tubes initial(Map<String, Object?> spec) => [
        for (final t in spec['tubes']! as List<Object?>)
          List<int>.from(t! as List),
      ];

  @override
  List<Move> legalMoves(Tubes s) {
    final moves = <Move>[];
    for (var a = 0; a < s.length; a++) {
      if (s[a].isEmpty) continue;
      for (var b = 0; b < s.length; b++) {
        if (a == b || s[b].length >= tubeCap) continue;
        if (s[b].isEmpty || s[b].last == s[a].last) moves.add((a, b));
      }
    }
    return moves;
  }

  @override
  Tubes apply(Tubes s, Move m) {
    final next = [for (final t in s) List<int>.from(t)];
    final color = next[m.$1].last;
    while (next[m.$1].isNotEmpty &&
        next[m.$1].last == color &&
        next[m.$2].length < tubeCap) {
      next[m.$2].add(next[m.$1].removeLast());
    }
    return next;
  }

  @override
  bool isWon(Tubes s) => s.every(
      (t) => t.isEmpty || (t.length == tubeCap && t.toSet().length == 1));

  @override
  String hash(Tubes s) {
    // 容器の入れ替えは同一状態として扱う。
    final parts = [for (final t in s) t.join(',')]..sort();
    return parts.join('|');
  }
}
