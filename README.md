# puzzle_core

Everpuzz パズルシリーズの共通基盤（内部名。ストアには出さない）。純Dart。
設計: Drive `puzzle-series（パズル共通基盤）` の 02_設計書 / 03_決定事項。

## 構成（依存は下向きのみ。CIで検査）

```
foundation ← puzzle ← kits ← meta ← 各ゲーム
```

| ディレクトリ | 内容 | 状態 |
|---|---|---|
| `lib/foundation` | Clock・保存(版管理)・level・progress・economy・telemetry・l10n・差し込みIF | 実装済み |
| `lib/puzzle` | PuzzleRules・ソルバー(BFS)・レベル検証・星計算・難易度推定 | 実装済み |
| `lib/kits` | 盤面・入力・アニメーション部品 | 空（1本目で書き、2本目で使われたものだけ昇格） |
| `lib/meta` | 町づくり・図鑑など | 空（同上） |

ゲームは必要な範囲だけ import する: `package:puzzle_core/foundation.dart` / `puzzle.dart`。

## 守ること

- 時刻は `Clock` を注入（`DateTime.now()` は `clock.dart` のみ）
- Firebase・広告・課金SDKを直 import しない（`AdGate` / `Entitlements` / `Telemetry` 等の窓口越し）
- 価格・商品IDはゲーム側。経済は設定データ、通貨1種類、確率報酬なし
- 文言は l10n 経由（直書きしない）。レベルデータに文字を埋め込まない
- foundation は 8,000 行以内を目安

## 使い方（ルールを書いて検証する）

```dart
class MyRules extends PuzzleRules<MyState, MyMove> { /* initial/legalMoves/apply/isWon/hash */ }

final verified = LevelVerifier(MyRules(), solverVersion: 'bfs-1').verifyPack(pack);
assert(verified.validate().isEmpty); // 解けない面が1件でもあれば不合格
```

## 開発

```
dart pub get
dart analyze
dart test
dart run tool/check_architecture.dart
```

## 未実装（設計済み・後続）

liveops（日替わり・遠隔難易度）、regional/（地域設定）、flow/feel（画面骨格・演出）、
レベル生成補助、アクセシビリティ検査（色覚・文字200%・コントラスト）。
