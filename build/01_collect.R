# RSS を取得して data/snapshots/ に 1 収集 = 1 CSV(不変)を書き、台帳に追記する。
#
# 契約(loop_001 で実装、テスト T-009〜T-011 が先行):
#  使い方: Rscript build/01_collect.R --at <ISO8601 UTC>(省略時のみ現在時刻)
#  - フィード定義は R/feeds.R(loop_001 で実 URL を pin。User-Agent にプロジェクト URL)
#  - 出力: data/snapshots/snap-YYYYMMDD-HHMM.csv
#      列: guid, link, title, category, collected_at_utc
#  - 既存スナップショットへの追記・上書きは禁止(同名ファイルが存在したら stop)
#  - 書き込み後、data/ledger.csv に filename + SHA256 + collected_at_utc を追記
#  - パース(XML → 行)は R/parse_feed.R の純関数。本スクリプトは取得と書き込みのみ

stop("loop_001 で実装する(テスト先行)。SPEC §3 F-01 / TEST_SPEC T-009〜T-011 参照")
