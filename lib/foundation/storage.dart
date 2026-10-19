import 'dart:convert';

/// 保存先の窓口。Firebase / SharedPreferences などはゲーム側で実装して差し込む。
abstract interface class KeyValueStore {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> remove(String key);
}

class MemoryKeyValueStore implements KeyValueStore {
  final Map<String, String> _data = {};

  @override
  Future<String?> read(String key) async => _data[key];

  @override
  Future<void> write(String key, String value) async => _data[key] = value;

  @override
  Future<void> remove(String key) async => _data.remove(key);
}

typedef Json = Map<String, Object?>;

/// 版管理つきJSON保存。`{"v": 版, "data": {...}}` の形で保存し、
/// 読み込み時に古い版を [migrations] で1版ずつ引き上げる。
/// `migrations[n]` は「版 n → n+1」の変換。
class VersionedJsonStore {
  const VersionedJsonStore(this.store);

  final KeyValueStore store;

  Future<void> save(String key, int version, Json data) =>
      store.write(key, jsonEncode({'v': version, 'data': data}));

  /// 未保存・破損・将来版（現行より新しい）の場合は null。
  Future<Json?> load(
    String key, {
    required int currentVersion,
    Map<int, Json Function(Json)> migrations = const {},
  }) async {
    final raw = await store.read(key);
    if (raw == null) return null;
    try {
      final envelope = jsonDecode(raw) as Map<String, Object?>;
      var v = envelope['v'] as int;
      var data = Map<String, Object?>.from(envelope['data']! as Map);
      if (v > currentVersion) return null;
      while (v < currentVersion) {
        final step = migrations[v];
        if (step == null) return null;
        data = step(data);
        v++;
      }
      return data;
    } on Object {
      return null;
    }
  }
}
