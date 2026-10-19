# 0001 構成と境界

- 日付: 2026-10-19
- 状態: 採用

## 決定

- 基盤名は `puzzle_core`。1パッケージ・純Dartで、層は `lib/` 配下のディレクトリで表す
  （foundation ← puzzle ← kits ← meta）。逆参照は `tool/check_architecture.dart` で CI 失敗にする。
- foundation / puzzle は Flutter に依存しない（テスト容易性）。UIを持つ部品は kits / meta で扱う。
- 時刻・保存・広告・課金・計測・ランキング・アカウントは抽象IF。実装はゲーム側（shared_core の Firebase 直結の反省）。
- ソルバーは BFS（最短手数が確定する）。探索上限で打ち切った場合は「結論未確定」とし、検証では不合格扱い。
- kits / meta は空で開始。2本目のゲームで使われた部品だけを昇格し、使われないものは削除して ADR に残す。

## 根拠

Drive: 決定事項_v0_1 / 追補1〜3、共通基盤_設計案_v0_1、共通化範囲の拡張_v0_2。

## 保留

リポジトリを独立させる時期（現在は monorepo の `puzzle_core/`。設計上は非公開の独立リポジトリが想定）、
liveops / regional / flow / feel、ランキング実装。
