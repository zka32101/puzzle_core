/// 時刻の窓口。`DateTime.now()` は直接呼ばず、必ずこれを注入する
/// （ライフ回復・日替わりをテスト可能にするため）。
abstract interface class Clock {
  DateTime now();
}

class SystemClock implements Clock {
  const SystemClock();

  @override
  DateTime now() => DateTime.now();
}

/// テスト用の可変時計。
class FakeClock implements Clock {
  FakeClock(DateTime start) : _now = start;

  DateTime _now;

  @override
  DateTime now() => _now;

  void advance(Duration d) => _now = _now.add(d);

  void set(DateTime t) => _now = t;
}
