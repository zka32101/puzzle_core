/// 標準のメニュー構成(ホーム+ショップ+設定+情報)。
/// 画面(UI)は各ゲームが持つ。ここは「何を・どの順で出すか」と「出す条件」だけを定める
/// 純Dartのモデル。ゲームが違っても、メニューの並び・設定の項目・情報の項目がそろう。
library;

/// 上位メニューの項目。ホームは各ゲーム固有なので、ここには含めない。
enum MenuAction { shop, settings, info }

/// 設定の項目の種類(UIの部品を選ぶのに使う)。
enum SettingKind {
  /// 言語(端末に合わせる/一覧から選ぶ)。
  language,

  /// 動きを減らす(歩く・揺れるなどの演出を止める)。
  toggle,

  /// ボタン(購入の復元・データの削除など)。
  action,
}

/// 設定の項目のID(文言キー・保存・計測のキー)。
enum SettingId { language, reduceMotion, restorePurchases, deleteData }

/// 情報の項目の種類。
enum InfoKind { link, credits, version }

enum InfoId { privacy, terms, credits, version }

/// クレジット(権利表記)1件。画像・音・ライブラリなど。
class CreditEntry {
  const CreditEntry({required this.titleKey, this.body = '', this.url});

  /// 見出しの文言キー(翻訳は各ゲームの辞書)。
  final String titleKey;

  /// 本文(固有名詞・ライセンス名など翻訳しないもの)。
  final String body;
  final String? url;
}

/// メニューを組み立てるための、ゲームごとの状況。
class MenuContext {
  const MenuContext({
    this.shopAvailable = false,
    this.privacyUrl,
    this.termsUrl,
    this.credits = const [],
    this.appVersion = '',
    this.supportedLanguages = const ['ja', 'en'],
  });

  /// 課金の窓口とキー・商品がそろっているか(無ければショップ・復元は出さない)。
  final bool shopAvailable;
  final String? privacyUrl;
  final String? termsUrl;
  final List<CreditEntry> credits;
  final String appVersion;

  /// 設定で選べる言語(端末言語のほか、ここから選ぶ)。
  final List<String> supportedLanguages;
}

class MenuEntry {
  const MenuEntry(this.action, this.labelKey, this.icon);

  final MenuAction action;

  /// 文言キー(共通辞書 [commonBundles] にある)。
  final String labelKey;

  /// アイコンの記号名。UIが各自のアイコンに対応づける(shop / settings / info)。
  final String icon;
}

/// 上位メニュー。ショップは使える時だけ。順は ショップ → 設定 → 情報。
List<MenuEntry> buildMenu(MenuContext c) => [
      if (c.shopAvailable)
        const MenuEntry(MenuAction.shop, 'menu.shop', 'shop'),
      const MenuEntry(MenuAction.settings, 'menu.settings', 'settings'),
      const MenuEntry(MenuAction.info, 'menu.info', 'info'),
    ];

class SettingItem {
  const SettingItem(this.id, this.kind, this.labelKey,
      {this.destructive = false});

  final SettingId id;
  final SettingKind kind;
  final String labelKey;

  /// 取り消せない操作(確認を挟む)。
  final bool destructive;
}

class SettingsSection {
  const SettingsSection(this.titleKey, this.items);

  final String titleKey;
  final List<SettingItem> items;
}

/// 設定の構成。空の区分は出さない。
List<SettingsSection> buildSettings(MenuContext c) => [
      const SettingsSection('settings.general', [
        SettingItem(
            SettingId.language, SettingKind.language, 'settings.language'),
        SettingItem(SettingId.reduceMotion, SettingKind.toggle,
            'settings.reduceMotion'),
      ]),
      if (c.shopAvailable)
        const SettingsSection('settings.purchases', [
          SettingItem(SettingId.restorePurchases, SettingKind.action,
              'settings.restore'),
        ]),
      const SettingsSection('settings.data', [
        SettingItem(
            SettingId.deleteData, SettingKind.action, 'settings.deleteData',
            destructive: true),
      ]),
    ];

class InfoItem {
  const InfoItem(this.id, this.kind, this.labelKey, {this.value});

  final InfoId id;
  final InfoKind kind;
  final String labelKey;

  /// リンクのURL・版の文字列。
  final String? value;
}

/// 情報の構成。URL が無いリンクは出さない。クレジットは1件でもあれば出す。
List<InfoItem> buildInfo(MenuContext c) => [
      if (c.privacyUrl != null)
        InfoItem(InfoId.privacy, InfoKind.link, 'info.privacy',
            value: c.privacyUrl),
      if (c.termsUrl != null)
        InfoItem(InfoId.terms, InfoKind.link, 'info.terms', value: c.termsUrl),
      if (c.credits.isNotEmpty)
        const InfoItem(InfoId.credits, InfoKind.credits, 'info.credits'),
      if (c.appVersion.isNotEmpty)
        InfoItem(InfoId.version, InfoKind.version, 'info.version',
            value: c.appVersion),
    ];
