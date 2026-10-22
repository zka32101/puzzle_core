/// ユーザー設定の保存(版管理つき)。メニューの設定画面が読み書きする。
library;

import '../foundation.dart';

class AppSettings {
  const AppSettings({this.languageOverride, this.reduceMotion = false});

  /// null なら端末の言語に合わせる。
  final String? languageOverride;

  /// 動きを減らす(端末の設定と、どちらかが有効なら動かさない)。
  final bool reduceMotion;

  static const defaults = AppSettings();

  AppSettings copyWith({
    String? languageOverride,
    bool clearLanguage = false,
    bool? reduceMotion,
  }) =>
      AppSettings(
        languageOverride:
            clearLanguage ? null : (languageOverride ?? this.languageOverride),
        reduceMotion: reduceMotion ?? this.reduceMotion,
      );

  Json toJson() => {
        'languageOverride': languageOverride,
        'reduceMotion': reduceMotion,
      };

  factory AppSettings.fromJson(Json j) => AppSettings(
        languageOverride: j['languageOverride'] as String?,
        reduceMotion: (j['reduceMotion'] as bool?) ?? false,
      );

  /// 使う言語。上書きがあり対応していればそれ、無ければ端末の言語から決める。
  String effectiveLocale(String deviceTag, Set<String> supported) {
    final o = languageOverride;
    if (o != null && supported.contains(o)) return o;
    return resolveLocale(deviceTag, supported);
  }

  /// 動きを止めるか(端末の「アニメーションを減らす」か、設定のどちらか)。
  bool shouldReduceMotion({required bool deviceDisablesAnimations}) =>
      reduceMotion || deviceDisablesAnimations;
}

class SettingsStore {
  const SettingsStore(this.kv);

  static const key = 'settings';
  static const schema = 1;

  final KeyValueStore kv;

  Future<void> save(AppSettings s) =>
      VersionedJsonStore(kv).save(key, schema, s.toJson());

  /// 未保存・破損・将来版は既定値。
  Future<AppSettings> load() async {
    final j = await VersionedJsonStore(kv).load(key, currentVersion: schema);
    if (j == null) return AppSettings.defaults;
    try {
      return AppSettings.fromJson(j);
    } on Object {
      return AppSettings.defaults;
    }
  }

  /// 設定を消す(「データの削除」の一部。進行・経済の削除は各ゲームが行う)。
  Future<void> clear() => kv.remove(key);
}
