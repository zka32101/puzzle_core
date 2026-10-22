# puzzle_core

Everpuzz パズルシリーズの共通基盤（内部名。ストアには出さない）。純Dart。
各ゲームは別リポジトリで、この基盤を **版を固定した git 依存**（タグ `ref: vX.Y.Z`、またはコミットのハッシュ）で使う。基盤を直しても、ゲーム側は自分のタイミングで版を上げるまで壊れない。
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
| `lib/meta` | メニュー構成(ショップ・設定・情報)・設定の保存。町づくり・図鑑などは1本目で書き、2本目で使われたものだけ昇格 | メニュー・設定は実装済み |

ゲームは必要な範囲だけ import する: `package:puzzle_core/foundation.dart` / `puzzle.dart`。

## 標準のメニュー構成（`package:puzzle_core/meta.dart`）

ホームは各ゲーム固有。ホームの上部に **ショップ → 設定 → 情報** を並べる(ショップは課金の窓口・商品がそろっている時だけ)。画面(UI)は各ゲームが持ち、ここは「何を・どの順で・どの条件で出すか」と文言・設定の保存だけを定める純Dart。

| 関数・型 | 内容 |
|---|---|
| `buildMenu(MenuContext)` | 上位メニュー(ショップ/設定/情報) |
| `buildSettings(MenuContext)` | 設定: 言語・動きを減らす・購入の復元(ショップがある時)・データ削除(確認つき) |
| `buildInfo(MenuContext)` | 情報: プライバシー・規約(URLがある時)・クレジット(権利表記)・版 |
| `AppSettings` / `SettingsStore` | 言語の上書き・動きを減らす。版管理つき保存、破損は既定値 |
| `commonBundles` | 上の文言(ja/en)。ゲームの辞書に足して使う |

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

## ゲームからの使い方

```yaml
dependencies:
  puzzle_core:
    git:
      url: https://github.com/zka32101/puzzle_core.git
      ref: v0.1.0   # タグ。タグがまだ無い間はコミットのハッシュを書く
```

破壊的変更はメジャー(またはv0系ではマイナー)を上げ、`docs/decisions/` に ADR を残す。

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
