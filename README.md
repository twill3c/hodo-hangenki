# hodo-hangenki — 報道半減期

ニュース見出しの寿命観測所。公開 RSS を定時スナップショットし、各ニュースが
見出し欄に留まった時間をカプラン・マイヤー推定にかけて、カテゴリ別の**半減期**
(生存曲線の中央値)を静的サイトで公開する。

- 仕様: [SPEC.md](SPEC.md) / オラクル設計: [TEST_SPEC.md](TEST_SPEC.md) / 開発規範: [AGENTS.md](AGENTS.md)

## 構成

```
R/          純関数(RSS パース・寿命導出・KM 推定・描画・フッタ)— IO/時刻/乱数禁止
build/      パイプライン(副作用はここだけ)
  01_collect.R    RSS → data/snapshots/(1 収集 = 1 不変 CSV)+ 台帳追記
  02_lifetimes.R  スナップショット列 → (time, event) → KM・半減期
  03_render.R     KM 曲線 + ランキング + ヒストグラム → out/
data/snapshots/   不変スナップショット(git 管理・append-only)
data/ledger.csv   スナップショットの SHA256 台帳(G-03)
tests/testthat/   オラクル群(手計算 KM・閉形式・survival 二実装照合・台帳整合)
out/              静的サイト(git 管理 — Actions がコミットし Vercel Git 連携が配信)
```

## オラクル

公表統計の代わりに**理論と独立実装**を正解の源にする:
手計算フィクスチャの厳密一致(G-01)、指数分布の閉形式 S(t)=exp(−λt)・半減期 ln2/λ(G-02)、
`survival::survfit` との二実装照合(G-05)、append-only 台帳(G-03)、SVG 決定論(G-04)。

## 自動更新

GitHub Actions cron(1 時間周期)が 収集 → 再計算 → 再レンダリング → コミット を無人実行し、
Vercel の Git 連携が `out/` を配信する。R は Actions ランナー上で動き、Vercel 上では何もビルドしない。

## 法務・収集ポリシー

- 保存項目は **guid・link・title・category・収集時刻のみ**(本文・画像は取得も保存もしない・F-01)
- **見出しの著作権は各報道機関(NHK ほか)に帰属する。** `LICENSE`(MIT)が及ぶのは
  コードと本アプリの生成物(生存時間・推定値・SVG)であって、
  `data/snapshots/` に蓄積した見出しではない
- 各見出しは配信元へのリンクにする。全ページに出典とフィード取得時刻を明記する
