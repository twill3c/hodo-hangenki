# スナップショット列からストーリーごとの (time, event) と KM 推定を計算し、
# data/processed/ に書き出す。
#
# 契約(loop_002 で実装、テスト T-001〜T-008 / G-05 が先行):
#  - 寿命導出は R/lifetimes.R、KM は R/km.R(いずれも純関数)
#  - 出力: data/processed/lifetimes.csv(story ごと)、km_by_category.csv(階段関数)、
#          halflife.csv(カテゴリ別中央値 + Greenwood 95%CI)
#  - 右打ち切り: 最新スナップショットに存在するストーリーは event=0
#  - 収集欠損の扱いは T-008 の定義に従う(実装時に固定してテストへ写す)

stop("loop_002 で実装する(テスト先行)。SPEC §2/§3 F-02〜F-04 参照")
