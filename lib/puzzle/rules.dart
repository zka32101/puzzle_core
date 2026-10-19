/// ゲームごとの盤面ルールの境界。ルールはここ1か所に書き、
/// 面の生成・ソルバー検証・アプリで共有する。
abstract class PuzzleRules<S, M> {
  const PuzzleRules();

  /// レベルの spec（ゲーム固有JSON）から初期状態を作る。
  S initial(Map<String, Object?> spec);

  List<M> legalMoves(S state);

  S apply(S state, M move);

  bool isWon(S state);

  /// 既定: 勝っておらず合法手がない。
  bool isLost(S state) => !isWon(state) && legalMoves(state).isEmpty;

  int score(S state) => 0;

  /// 同一状態は同一ハッシュ（探索の重複除外に使う）。
  String hash(S state);
}
