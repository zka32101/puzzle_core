import 'package:puzzle_core/foundation.dart';
import 'package:puzzle_core/meta.dart';
import 'package:test/test.dart';

void main() {
  group('メニュー構成', () {
    test('ショップが使える時は ショップ→設定→情報、使えない時はショップなし', () {
      final on = buildMenu(const MenuContext(shopAvailable: true));
      expect(on.map((e) => e.action),
          [MenuAction.shop, MenuAction.settings, MenuAction.info]);
      final off = buildMenu(const MenuContext());
      expect(off.map((e) => e.action), [MenuAction.settings, MenuAction.info]);
      expect(on.map((e) => e.icon), ['shop', 'settings', 'info']);
    });

    test('設定: 言語・動きを減らす・(ショップがあれば)購入の復元・データ削除。削除は確認つき', () {
      final withShop = buildSettings(const MenuContext(shopAvailable: true));
      expect(withShop.map((s) => s.titleKey),
          ['settings.general', 'settings.purchases', 'settings.data']);
      final ids = [for (final s in withShop) ...s.items.map((i) => i.id)];
      expect(ids, [
        SettingId.language,
        SettingId.reduceMotion,
        SettingId.restorePurchases,
        SettingId.deleteData,
      ]);
      final delete = withShop.last.items.single;
      expect(delete.destructive, isTrue);
      final noShop = buildSettings(const MenuContext());
      expect(
          noShop.map((s) => s.titleKey), ['settings.general', 'settings.data']);
    });

    test('情報: URLの無いリンク・空のクレジット・空の版は出さない', () {
      expect(buildInfo(const MenuContext()), isEmpty);
      final all = buildInfo(const MenuContext(
        privacyUrl: 'https://example.com/privacy',
        termsUrl: 'https://example.com/terms',
        credits: [CreditEntry(titleKey: 'credit.ai', body: 'x')],
        appVersion: '1.2.3',
      ));
      expect(all.map((i) => i.id),
          [InfoId.privacy, InfoId.terms, InfoId.credits, InfoId.version]);
      expect(all.last.value, '1.2.3');
      expect(buildInfo(const MenuContext(termsUrl: 'u')).map((i) => i.id),
          [InfoId.terms]);
    });

    test('メニューと設定と情報の文言キーは共通辞書にそろっている(ja/en)', () {
      final keys = <String>{
        for (final e in buildMenu(const MenuContext(shopAvailable: true)))
          e.labelKey,
        for (final s
            in buildSettings(const MenuContext(shopAvailable: true))) ...[
          s.titleKey,
          for (final i in s.items) i.labelKey,
        ],
        for (final i in buildInfo(const MenuContext(
          privacyUrl: 'a',
          termsUrl: 'b',
          credits: [CreditEntry(titleKey: 'k')],
          appVersion: '1',
        )))
          i.labelKey,
      };
      for (final l in commonBundles.keys) {
        for (final k in keys) {
          expect(commonBundles[l]!.containsKey(k), isTrue, reason: '$l: $k');
        }
      }
    });

    test('共通辞書は、全ての言語が ja と過不足なく同じキーを持ち、プレースホルダが合う', () {
      expect(commonBundles.keys,
          containsAll(['ja', 'en', 'ko', 'es', 'zh-Hans', 'zh-Hant']));
      for (final l in commonBundles.keys.where((l) => l != 'ja')) {
        expect(
            L10nLint.compare(commonBundles['ja']!, commonBundles[l]!,
                locale: l),
            isEmpty,
            reason: 'ja → $l');
        expect(
            L10nLint.compare(commonBundles[l]!, commonBundles['ja']!,
                locale: 'ja'),
            isEmpty,
            reason: '$l → ja');
      }
    });
  });

  group('設定の保存', () {
    test('既定値と往復', () async {
      final kv = MemoryKeyValueStore();
      final store = SettingsStore(kv);
      expect((await store.load()).languageOverride, isNull);
      expect((await store.load()).reduceMotion, isFalse);
      await store
          .save(const AppSettings(languageOverride: 'en', reduceMotion: true));
      final back = await store.load();
      expect(back.languageOverride, 'en');
      expect(back.reduceMotion, isTrue);
      await store.clear();
      expect((await store.load()).reduceMotion, isFalse);
    });

    test('破損・将来版は既定値', () async {
      final kv = MemoryKeyValueStore();
      await kv.write(SettingsStore.key, 'not json');
      expect((await SettingsStore(kv).load()).languageOverride, isNull);
      await kv.write(SettingsStore.key, '{"v":99,"data":{}}');
      expect((await SettingsStore(kv).load()).reduceMotion, isFalse);
    });

    test('言語: 上書きが対応していればそれ、非対応や未設定なら端末から', () {
      const s = AppSettings(languageOverride: 'en');
      expect(s.effectiveLocale('ja-JP', {'ja', 'en'}), 'en');
      expect(
          const AppSettings(languageOverride: 'xx')
              .effectiveLocale('ja-JP', {'ja', 'en'}),
          'ja');
      expect(AppSettings.defaults.effectiveLocale('en-US', {'ja', 'en'}), 'en');
      expect(s.copyWith(clearLanguage: true).languageOverride, isNull);
    });

    test('動きを止める: 設定か端末のどちらかが有効なら止める', () {
      expect(
          AppSettings.defaults
              .shouldReduceMotion(deviceDisablesAnimations: false),
          isFalse);
      expect(
          AppSettings.defaults
              .shouldReduceMotion(deviceDisablesAnimations: true),
          isTrue);
      expect(
          const AppSettings(reduceMotion: true)
              .shouldReduceMotion(deviceDisablesAnimations: false),
          isTrue);
    });
  });
}
