/// 経済（ライフ・コイン・ブースター・コンティニュー）。
/// 数値は [EconomyConfig]（設定データ）、価格・商品IDはゲーム側。
/// 通貨は1種類・報酬は固定のみ（確率報酬なし）。時刻は [Clock] 経由。
library;

import 'clock.dart';
import 'storage.dart' show Json;

class EconomyConfig {
  const EconomyConfig({
    this.maxLives = 5,
    this.lifeRegenInterval = const Duration(minutes: 30),
    this.continueCost = 30,
    this.winReward = 10,
    this.boosterCosts = const {},
  });

  final int maxLives;
  final Duration lifeRegenInterval;
  final int continueCost;
  final int winReward;

  /// ブースターID → コイン価格。
  final Map<String, int> boosterCosts;
}

/// 経済状態（不変）。[lifeAnchor] は「次の回復カウントの起点」。
class EconomyState {
  const EconomyState({
    required this.coins,
    required this.lives,
    required this.lifeAnchor,
    this.boosters = const {},
  });

  factory EconomyState.initial(EconomyConfig c, DateTime now) => EconomyState(
        coins: 0,
        lives: c.maxLives,
        lifeAnchor: now,
      );

  factory EconomyState.fromJson(Json j) => EconomyState(
        coins: j['coins']! as int,
        lives: j['lives']! as int,
        lifeAnchor: DateTime.parse(j['lifeAnchor']! as String),
        boosters: Map<String, int>.from(j['boosters']! as Map),
      );

  final int coins;
  final int lives;
  final DateTime lifeAnchor;
  final Map<String, int> boosters;

  int boosterCount(String id) => boosters[id] ?? 0;

  EconomyState copyWith({
    int? coins,
    int? lives,
    DateTime? lifeAnchor,
    Map<String, int>? boosters,
  }) =>
      EconomyState(
        coins: coins ?? this.coins,
        lives: lives ?? this.lives,
        lifeAnchor: lifeAnchor ?? this.lifeAnchor,
        boosters: boosters ?? this.boosters,
      );

  Json toJson() => {
        'coins': coins,
        'lives': lives,
        'lifeAnchor': lifeAnchor.toUtc().toIso8601String(),
        'boosters': boosters,
      };
}

/// 状態を返す純関数群。実行不能な操作（残高不足など）は null を返し、状態は変えない。
class Economy {
  const Economy(this.config, this.clock);

  final EconomyConfig config;
  final Clock clock;

  /// 経過時間ぶんのライフ回復を反映する。操作の前に必ず通す。
  EconomyState refresh(EconomyState s) {
    final now = clock.now();
    if (s.lives >= config.maxLives) {
      return s.copyWith(lives: config.maxLives, lifeAnchor: now);
    }
    final elapsed = now.difference(s.lifeAnchor);
    if (elapsed < config.lifeRegenInterval) return s;
    final gained =
        elapsed.inMicroseconds ~/ config.lifeRegenInterval.inMicroseconds;
    final lives = (s.lives + gained).clamp(0, config.maxLives);
    return s.copyWith(
      lives: lives,
      lifeAnchor: lives >= config.maxLives
          ? now
          : s.lifeAnchor.add(config.lifeRegenInterval * gained),
    );
  }

  /// 次のライフが回復するまでの残り時間。満タンなら null。
  Duration? timeToNextLife(EconomyState s) {
    final r = refresh(s);
    if (r.lives >= config.maxLives) return null;
    return r.lifeAnchor.add(config.lifeRegenInterval).difference(clock.now());
  }

  /// プレイ開始時にライフを1消費。ライフ切れなら null。
  EconomyState? consumeLife(EconomyState s) {
    final r = refresh(s);
    if (r.lives <= 0) return null;
    // 満タンからの消費は、この時点から回復カウントを開始する。
    final anchor = r.lives >= config.maxLives ? clock.now() : r.lifeAnchor;
    return r.copyWith(lives: r.lives - 1, lifeAnchor: anchor);
  }

  /// リワード広告などによるライフ回復（+1、上限まで）。
  EconomyState restoreLife(EconomyState s) {
    final r = refresh(s);
    return r.copyWith(lives: (r.lives + 1).clamp(0, config.maxLives));
  }

  EconomyState addCoins(EconomyState s, int amount) {
    assert(amount >= 0);
    return s.copyWith(coins: s.coins + amount);
  }

  EconomyState? spendCoins(EconomyState s, int amount) {
    if (amount < 0 || s.coins < amount) return null;
    return s.copyWith(coins: s.coins - amount);
  }

  EconomyState grantWinReward(EconomyState s) => addCoins(s, config.winReward);

  /// コインでコンティニュー。残高不足なら null。
  EconomyState? payContinue(EconomyState s) =>
      spendCoins(s, config.continueCost);

  /// コインでブースターを購入。未定義ID・残高不足なら null。
  EconomyState? buyBooster(EconomyState s, String id) {
    final cost = config.boosterCosts[id];
    if (cost == null) return null;
    final paid = spendCoins(s, cost);
    if (paid == null) return null;
    return paid.copyWith(
      boosters: {...paid.boosters, id: paid.boosterCount(id) + 1},
    );
  }

  EconomyState? useBooster(EconomyState s, String id) {
    final n = s.boosterCount(id);
    if (n <= 0) return null;
    return s.copyWith(boosters: {...s.boosters, id: n - 1});
  }
}
