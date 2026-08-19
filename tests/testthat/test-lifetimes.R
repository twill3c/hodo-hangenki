# 寿命導出の境界ケース(T-006〜T-008 / G-06)。
# 定義(SPEC §2 / loop_002 で固定):
#   Δ = 公称収集間隔(引数注入、既定 3600 秒)
#   消滅(最新スナップショットに不在): time = (last_seen − first_seen) + Δ, event = 1
#     — 「last_seen までは確実に居て、その後 Δ 以内のどこかで消えた」の上限側慣例値。
#     1 回だけ観測 → 消えた場合も time = Δ となり 0 にならない
#   在留(最新スナップショットに存在): time = latest − first_seen, event = 0(右打ち切り)
#     — 新着(first_seen = latest)は time = 0 の打ち切りで、KM のリスク集合に影響しない
suppressPackageStartupMessages(library(dplyr))
source("../../R/lifetimes.R", chdir = TRUE)

H <- 3600
snap_times <- c(0, 1, 2, 4, 5) * H  # t=3H に収集欠損がある 5 スナップショット

# presence: guid × スナップショット時刻(在=1)
obs <- tribble(
  ~guid, ~t,
  # A: t=0 のみ観測 → 消滅(T-006)
  "A", 0 * H,
  # B: 最新(5H)まで在留 → 打ち切り(T-007)
  "B", 0 * H, "B", 1 * H, "B", 2 * H, "B", 4 * H, "B", 5 * H,
  # C: 欠損(3H)を跨いで 2H と 4H に在 → 生存扱い、4H で last_seen、その後消滅(T-008)
  "C", 2 * H, "C", 4 * H,
  # D: 最新スナップショットで初観測 → time 0 の打ち切り
  "D", 5 * H
)
obs$category <- "主要"

lt <- derive_lifetimes(obs, snap_times = snap_times, interval = H)

test_that("1 回観測 → 消滅: time = Δ, event = 1(T-006)", {
  a <- lt[lt$guid == "A", ]
  expect_equal(a$time, H)
  expect_equal(a$event, 1)
})

test_that("最新まで在留: event = 0, time = 経過時間(T-007)", {
  b <- lt[lt$guid == "B", ]
  expect_equal(b$event, 0)
  expect_equal(b$time, 5 * H)
})

test_that("収集欠損を跨ぐ在留を消滅と誤判定しない(T-008)", {
  cc <- lt[lt$guid == "C", ]
  expect_equal(nrow(cc), 1)          # 欠損跨ぎで 2 つのストーリーに分裂しない
  expect_equal(cc$event, 1)          # 最新(5H)に不在なので最終的には消滅
  expect_equal(cc$time, (4 - 2) * H + H)  # last_seen(4H) − first_seen(2H) + Δ
})

test_that("最新スナップショットで初観測: time = 0 の打ち切り", {
  d <- lt[lt$guid == "D", ]
  expect_equal(d$event, 0)
  expect_equal(d$time, 0)
})
