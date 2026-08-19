<!-- scaffold:block agents_core v1.8.0 -->
## 共通規律(scaffold 管理領域 — 手動編集禁止)

このセクションはスキャフォールド・レジストリが管理する。内容を変更したい場合は、
このファイルを直接編集せず、失敗ログ → HARNESS_CHANGELOG 起票 → レジストリ改訂 → `scaffoldctl update` の経路で行うこと。

### 7 段階ループプロトコル

| 段階 | 名称 | 完了条件 |
|---|---|---|
| 1 | 計画 | 対象の要求 ID を特定し、`loop_start` を記録した |
| 2 | 文脈読込 | SPEC.md / IMPLEMENTATION_GUIDE.md の該当箇所と、直近ループのログを読んだ |
| 3 | テスト先行 | TEST_SPEC.md にトレースする失敗するテストを書き、赤を確認した |
| 4 | 実装 | ファイル編集 2 回ごとにテストを実行し、赤のまま次の編集に進んでいない |
| 5 | 検証 | 全テスト合格 + 独立再計算(該当時)を確認した |
| 6 | 文書同期 | SPEC/docs と実装の乖離(SPEC-DRIFT)を解消し、生成ドキュメントを再生成した |
| 7 | 完了 | `loop_end` を記録し、ループログ validate に合格し、専用コミットを積んだ |

### ループ可観測性

全ループは loop-observability の規律(LOOP_LOG_SPEC / FAILURE_TAXONOMY)に従い
`logs/loops/{loop_id}.jsonl` に記録する。失敗は気づいた瞬間に分類コード付きで記録する。
ツーストライク(LL-10)と S1 即時起票(LL-12)は本プロジェクトでも有効である。

### エスカレーション規範

以下の場合は作業を止め、`escalation` を記録してから人間に確認する:
仕様の複数解釈(SPEC-AMB 相当)/ スコープ外ファイルへの変更が必要になった /
破壊的操作(履歴改変・データ削除・強制 push)/ 同種の修正の 3 回目の失敗(PROC-LOOP)。

### コミット規約

Conventional Commits(feat/fix/test/docs/refactor/chore)。スキャフォールド更新は
`chore: scaffold vX.Y.Z` の専用コミットで行い、機能変更と混ぜない。
<!-- /scaffold:block agents_core -->

# AGENTS.md — hodo-hangenki

報道半減期。ニュース見出しの RSS スナップショットを生存時間解析(カプラン・マイヤー)にかけ、
カテゴリ別の半減期を静的サイトで公開する。オラクルは閉形式(kobai-walk 型)+
survival パッケージとの二実装照合(tegaki-yomi 型)。仕様は SPEC.md、テストは TEST_SPEC.md。

## 1. 技術構成

- R 4.6.1(`%LOCALAPPDATA%\Programs\R\R-4.6.1`、PATH 未登録 — Rscript.exe をフルパスで呼ぶ)
- xml2 / dplyr / readr / ggplot2 / glue / svglite / digest / testthat / survival(照合専用 — 本線コードから import しない)
- サイトは glue テンプレートから直接 HTML 生成(toukei-atlas と同方針。Quarto・Node 不使用)
- 自動更新: GitHub Actions cron(収集 → 計算 → レンダリング → out/ コミット → Vercel Git 連携で配信)

## 2. looplog 運用の注意

- テスト実行と `test_run` 記録は **`python harness/testrun.py --loop <loop_id>` 経由を必須**とする
  (toukei-atlas HC-003 直移植。手動転記はしない)
- 新しいイベント種別の初回使用前に `harness/looplog.py` の EVENT_SPECS を確認する
- enum の許容値は `schema/taxonomy.json` と looplog.py の ENUMS が正
- loop_end の failure_count は記憶で書かず `grep -c '"event": "failure"'` で数える

## 3. 品質ゲート(完了条件)

testthat 全 green(SPEC §4 の G-01〜G-06)。ゲートを緩める変更(許容誤差の拡大、
テスト削除・skip、SVG ハッシュ期待値の理由なき更新)は人間の承認なしに行わない。
G-02 の許容誤差は較正実験の記録(looplog note か SPEC 追記)を伴って初めて固定できる。

## 4. アーキテクチャ規約

- `R/` は**純関数のみ**。ネットワーク・ファイル IO・`Sys.time()`・乱数を直接呼ばない。
  収集時刻は build/ スクリプトが引数で注入し、合成データの乱数はシード注入の PRNG で作る
- 副作用(RSS 取得・スナップショット書き込み・レンダリング)は `build/` に集約。依存方向は build/ → R/ のみ
- **スナップショットは不変**: 既存ファイルの編集・削除は禁止。修正が必要な場合も
  新しい世代のファイルで表現し、台帳(data/ledger.csv)に追記する
- survival パッケージは `tests/` からのみ import する(本線が照合相手に依存したら二実装照合にならない)
- ネイティブ拡張・外部形式の新しい呼び出し経路は最小スモークを通してから本線へ(HC-002 直移植)
- `Rscript … | tail` のパイプ包み実行をしない — ファイルリダイレクト + 完了マーカー + exit code で判定(HC-002 直移植)
- 実フィードへのアクセスはテストから行わない。パーサのテストは保存済みフィクスチャ XML に対して行う

## 5. 変更禁止領域

- `data/snapshots/` 配下(不変スナップショット)と `data/ledger.csv` の既存行
- `tests/testthat/fixtures/` の期待 SVG・手計算フィクスチャ(更新は専用コミット + 理由記録)
- scaffold:block 管理領域

## 6. デプロイ

- Vercel 静的配信(プロジェクト名 hodo-hangenki、予定 URL https://hodo-hangenki.vercel.app)
- GitHub Actions が out/ を生成してコミットし、Vercel Git 連携が out/ を配信する(Vercel 上でビルドしない)。
  Actions の cron は 1 時間周期(SPEC §5 の収集間隔規約)
- 初回デプロイ後に app-menu へのカード登録を行う(死にリンクの事前公開はしない — toukei-atlas の運用と同じ)
