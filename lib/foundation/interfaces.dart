/// ゲーム側が実装して差し込む窓口の定義（実装なし）。
/// Firebase / 広告SDK / ストア課金を puzzle_core が直接 import しないための境界。
library;

/// リワード広告の用途は3点に限定（強制の全画面広告は出さない）。
enum RewardedPlacement { continueLevel, restoreLife, doubleReward }

abstract interface class AdGate {
  /// 広告を見せ、報酬に値する視聴が完了したら true。広告削除済み・同意なし等で出せない場合は false。
  Future<bool> showRewarded(RewardedPlacement placement);
}

abstract interface class Entitlements {
  /// 広告削除の購入済みか。
  bool get adsRemoved;
}

/// ランキングは初回は実装しない。後付けできるよう窓口だけ定義する。
/// 提出時は手順ログ [moves] をソルバーで再生して検証できる形にする。
abstract interface class Leaderboard {
  Future<void> submit(String boardId, int score, {List<Object?> moves});
  Future<List<LeaderboardEntry>> top(String boardId, {int limit});
}

class LeaderboardEntry {
  const LeaderboardEntry(this.userId, this.score);

  final String userId;
  final int score;
}

/// アカウントなしが初期方針。引き継ぎを後付けする時の窓口。
abstract interface class Account {
  String? get userId;
}
