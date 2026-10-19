/// 計測の窓口。実体（analytics 等）はゲーム側で差し込む。
abstract interface class Telemetry {
  void log(TelemetryEvent event);
}

class TelemetryEvent {
  const TelemetryEvent(this.name, [this.params = const {}]);

  /// 共通イベント。levelId・attempt・moves を持たせる。
  factory TelemetryEvent.levelStart(String levelId, int attempt) =>
      TelemetryEvent('level_start', {'levelId': levelId, 'attempt': attempt});

  factory TelemetryEvent.levelWin(String levelId, int attempt, int moves) =>
      TelemetryEvent('level_win',
          {'levelId': levelId, 'attempt': attempt, 'moves': moves});

  factory TelemetryEvent.levelFail(String levelId, int attempt, int moves) =>
      TelemetryEvent('level_fail',
          {'levelId': levelId, 'attempt': attempt, 'moves': moves});

  factory TelemetryEvent.continueUsed(String levelId, int attempt) =>
      TelemetryEvent('continue_used', {'levelId': levelId, 'attempt': attempt});

  factory TelemetryEvent.boosterUsed(String levelId, String boosterId) =>
      TelemetryEvent(
          'booster_used', {'levelId': levelId, 'boosterId': boosterId});

  factory TelemetryEvent.adShown(String placement) =>
      TelemetryEvent('ad_shown', {'placement': placement});

  factory TelemetryEvent.purchase(String productId) =>
      TelemetryEvent('purchase', {'productId': productId});

  final String name;
  final Map<String, Object?> params;
}

class NoopTelemetry implements Telemetry {
  const NoopTelemetry();

  @override
  void log(TelemetryEvent event) {}
}

/// テスト用。記録するだけ。
class MemoryTelemetry implements Telemetry {
  final List<TelemetryEvent> events = [];

  @override
  void log(TelemetryEvent event) => events.add(event);
}
