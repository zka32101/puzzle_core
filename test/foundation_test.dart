import 'package:puzzle_core/foundation.dart';
import 'package:test/test.dart';

void main() {
  group('Economy', () {
    const config = EconomyConfig(
      maxLives: 3,
      lifeRegenInterval: Duration(minutes: 10),
      boosterCosts: {'shuffle': 20},
    );
    late FakeClock clock;
    late Economy eco;
    late EconomyState s;

    setUp(() {
      clock = FakeClock(DateTime.utc(2026, 1, 1, 12));
      eco = Economy(config, clock);
      s = EconomyState.initial(config, clock.now());
    });

    test('ライフ消費と時間経過での回復', () {
      s = eco.consumeLife(s)!;
      s = eco.consumeLife(s)!;
      expect(s.lives, 1);
      clock.advance(const Duration(minutes: 25));
      s = eco.refresh(s);
      expect(s.lives, 3);
    });

    test('端数の経過時間は次の回復に持ち越す', () {
      s = eco.consumeLife(s)!;
      s = eco.consumeLife(s)!;
      clock.advance(const Duration(minutes: 15));
      s = eco.refresh(s);
      expect(s.lives, 2);
      expect(eco.timeToNextLife(s), const Duration(minutes: 5));
    });

    test('ライフ切れは消費できない', () {
      for (var i = 0; i < 3; i++) {
        s = eco.consumeLife(s)!;
      }
      expect(eco.consumeLife(s), isNull);
    });

    test('満タンからの消費は消費時点から回復を数える', () {
      clock.advance(const Duration(hours: 5));
      s = eco.consumeLife(s)!;
      clock.advance(const Duration(minutes: 9));
      expect(eco.refresh(s).lives, 2);
      clock.advance(const Duration(minutes: 1));
      expect(eco.refresh(s).lives, 3);
    });

    test('コイン不足の購入・コンティニューは null で状態不変', () {
      expect(eco.buyBooster(s, 'shuffle'), isNull);
      expect(eco.payContinue(s), isNull);
      expect(s.coins, 0);
    });

    test('ブースター購入と使用', () {
      s = eco.addCoins(s, 50);
      s = eco.buyBooster(s, 'shuffle')!;
      expect(s.coins, 30);
      expect(s.boosterCount('shuffle'), 1);
      s = eco.useBooster(s, 'shuffle')!;
      expect(eco.useBooster(s, 'shuffle'), isNull);
      expect(eco.buyBooster(s, 'unknown'), isNull);
    });

    test('JSON往復', () {
      s = eco.addCoins(s, 7);
      final back = EconomyState.fromJson(s.toJson());
      expect(back.coins, 7);
      expect(back.lifeAnchor.isAtSameMomentAs(s.lifeAnchor), isTrue);
    });
  });

  group('Progress / 保存', () {
    test('勝利記録は星と最少手数の良い方を保持し、現在レベルは戻らない', () {
      var p = const Progress();
      p = p.recordWin('l1', stars: 2, moves: 10, levelIndex: 0);
      p = p.recordWin('l1', stars: 1, moves: 12, levelIndex: 0);
      expect(p.recordOf('l1').stars, 2);
      expect(p.recordOf('l1').bestMoves, 10);
      expect(p.recordOf('l1').attempts, 2);
      expect(p.currentLevelIndex, 1);
      p = p.recordFail('l2');
      expect(p.recordOf('l2').cleared, isFalse);
      expect(p.totalStars, 2);
    });

    test('KeyValueProgressStore 往復、未保存は初期値', () async {
      final store = KeyValueProgressStore(MemoryKeyValueStore());
      expect((await store.load()).currentLevelIndex, 0);
      await store.save(
          const Progress().recordWin('a', stars: 3, moves: 5, levelIndex: 0));
      final p = await store.load();
      expect(p.recordOf('a').stars, 3);
    });

    test('版管理: 旧版は migration で引き上げ、将来版・破損は null', () async {
      final kv = MemoryKeyValueStore();
      final vs = VersionedJsonStore(kv);
      await vs.save('k', 1, {'name': 'x'});
      final migrated = await vs.load('k', currentVersion: 2, migrations: {
        1: (d) => {...d, 'extra': 1},
      });
      expect(migrated, {'name': 'x', 'extra': 1});
      expect(await vs.load('k', currentVersion: 0), isNull);
      expect(await vs.load('k', currentVersion: 3), isNull); // 移行手順なし
      await kv.write('bad', '{not json');
      expect(await vs.load('bad', currentVersion: 1), isNull);
    });
  });

  group('LevelPack', () {
    Map<String, Object?> json({bool solvable = true, bool verified = true}) => {
          'schemaVersion': 1,
          'game': 'g',
          'packId': 'p',
          'packVersion': 1,
          'levels': [
            {
              'id': 'l1',
              'seed': 1,
              'difficulty': 1,
              'spec': {'a': 1},
              if (verified)
                'verified': {
                  'solvable': solvable,
                  'minMoves': 3,
                  'solverVersion': 's1',
                },
            },
          ],
        };

    test('往復と合格判定', () {
      final pack = LevelPack.fromJson(json());
      expect(pack.validate(), isEmpty);
      expect(LevelPack.fromJson(pack.toJson()).levels.single.spec, {'a': 1});
    });

    test('解けない・未検証・id重複は不合格', () {
      expect(LevelPack.fromJson(json(solvable: false)).validate(),
          contains('l1: 解けない'));
      expect(LevelPack.fromJson(json(verified: false)).validate(),
          contains('l1: 未検証'));
      final dup = LevelPack.fromJson(json());
      final twice = dup.withLevels([dup.levels.single, dup.levels.single]);
      expect(twice.validate(), contains('l1: id が重複'));
    });

    test('未対応の schemaVersion は拒否', () {
      expect(() => LevelPack.fromJson({...json(), 'schemaVersion': 99}),
          throwsFormatException);
    });
  });

  group('l10n', () {
    const bundles = {
      'ja': {'moves': 'あと{count, plural, other{#手}}', 'hi': 'こんにちは、{name}'},
      'en': {
        'moves': '{count, plural, one{# move} other{# moves}} left',
        'hi': 'Hello, {name}',
        'enOnly': 'only en',
      },
    };

    test('言語解決とフォールバック', () {
      const sup = {'ja', 'en', 'pt-BR'};
      expect(resolveLocale('pt_BR', sup), 'pt-BR');
      expect(resolveLocale('pt-PT', sup), 'pt-BR');
      expect(resolveLocale('fr', sup), 'en');
      expect(resolveLocale('fr', {'ja'}), 'ja');
    });

    test('置換と複数形', () {
      final en = Translator('en', bundles);
      expect(en.tr('hi', {'name': 'Ann'}), 'Hello, Ann');
      expect(en.tr('moves', {'count': 1}), '1 move left');
      expect(en.tr('moves', {'count': 3}), '3 moves left');
      expect(Translator('ja', bundles).tr('moves', {'count': 3}), 'あと3手');
    });

    test('欠落キーは他言語へフォールバック、全滅ならキーを返す', () {
      expect(Translator('ja', bundles).tr('enOnly'), 'only en');
      expect(Translator('ja', bundles).tr('nope'), 'nope');
    });

    test('lint: 欠落・未使用・プレースホルダ不一致・未承認', () {
      final issues = L10nLint.compare(
          {'a': 'x {n}', 'b': 'y'}, {'a': 'x', 'c': 'z'},
          locale: 'de');
      expect(issues.length, 3);
      expect(L10nLint.compare(bundles['ja']!, bundles['ja']!), isEmpty);
      expect(
          L10nLint.notApproved(
              {'a': ReviewStatus.approved, 'b': ReviewStatus.draft}),
          hasLength(1));
    });
  });

  test('Telemetry 共通イベント', () {
    final t = MemoryTelemetry()..log(TelemetryEvent.levelWin('l1', 2, 9));
    expect(t.events.single.name, 'level_win');
    expect(t.events.single.params['moves'], 9);
  });
}
