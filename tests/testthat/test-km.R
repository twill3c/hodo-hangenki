# KM 推定のオラクル(T-001〜T-005, T-015 / G-01・G-02・G-05)。
suppressPackageStartupMessages({
  library(dplyr)
})
source("../../R/km.R", chdir = TRUE)

# ---- 手計算フィクスチャ(G-01) ----------------------------------------------
# time  = 1, 2, 3, 4, 5, 6 / event = 1, 1, 0, 1, 0, 1(+ = 打ち切り: 3+, 5+)
# 導出(product-limit):
#   t=1: リスク集合 6、死亡 1 → S = 5/6
#   t=2: リスク集合 5、死亡 1 → S = 5/6 × 4/5 = 2/3
#   (t=3 は打ち切りのみ — S は変化しない。リスク集合から 1 減る)
#   t=4: リスク集合 3、死亡 1 → S = 2/3 × 2/3 = 4/9
#   (t=5 は打ち切りのみ)
#   t=6: リスク集合 1、死亡 1 → S = 4/9 × 0 = 0
# 中央値(survfit 慣例: S(t) ≤ 0.5 となる最小のイベント時刻)= 4(S=4/9 ≤ 0.5)
FIX <- data.frame(time = 1:6, event = c(1, 1, 0, 1, 0, 1))

test_that("手計算フィクスチャの KM 階段関数が厳密一致(T-001/G-01)", {
  fit <- km_fit(FIX$time, FIX$event)
  ev <- fit[fit$n_event > 0, ]
  expect_equal(ev$t, c(1, 2, 4, 6))
  expect_equal(ev$n_risk, c(6, 5, 3, 1))
  expect_equal(ev$surv, c(5/6, 2/3, 4/9, 0))
})

test_that("手計算フィクスチャの中央生存時間 = 4(T-002/G-01)", {
  expect_equal(km_median(km_fit(FIX$time, FIX$event)), 4)
})

test_that("S(t) の構造: 非増加・S(0)=1・イベント時刻でのみ変化(T-003)", {
  set.seed(7)
  time <- round(rexp(200, rate = 0.2), 3)
  event <- rbinom(200, 1, 0.7)
  fit <- km_fit(time, event)
  expect_true(all(diff(fit$surv) <= 1e-12))
  expect_equal(km_surv_at(fit, 0), 1)
  # イベントの無い時刻では S が変化しない
  no_ev <- fit[fit$n_event == 0, ]
  if (nrow(no_ev) > 0) {
    for (i in seq_len(nrow(no_ev))) {
      expect_equal(km_surv_at(fit, no_ev$t[i]),
                   km_surv_at(fit, no_ev$t[i] - 1e-9), tolerance = 1e-12)
    }
  }
})

test_that("survival::survfit との二実装照合(T-004/G-05)", {
  skip_if_not_installed("survival")
  library(survival)
  cases <- list(
    FIX,
    { set.seed(1); data.frame(time = round(rexp(500, 0.15), 2),
                              event = rbinom(500, 1, 0.6)) },
    { set.seed(2); data.frame(time = sample(1:24, 300, replace = TRUE),
                              event = rbinom(300, 1, 0.8)) }  # 同時刻タイあり
  )
  for (k in seq_along(cases)) {
    d <- cases[[k]]
    fit <- km_fit(d$time, d$event)
    sf <- survfit(Surv(d$time, d$event) ~ 1)
    ev <- fit[fit$n_event > 0, ]
    sf_ev <- sf$n.event > 0
    expect_equal(ev$t, sf$time[sf_ev], info = paste("case", k))
    expect_equal(ev$surv, sf$surv[sf_ev], tolerance = 1e-12, info = paste("case", k))
    expect_equal(ev$n_risk, sf$n.risk[sf_ev], info = paste("case", k))
    # Greenwood SE(survfit の std.err は log S スケールでなく S スケールの se/surv?
    # → 実測で確認済みの対応をここに固定する: survfit$std.err は
    #   sqrt(Var(log S)) 由来の cumulative。自前実装は se(S) を返すため
    #   surv * std.err と比較する)
    # S=0 の点は SE が定義されない(survfit は NaN)ため照合から除外
    pos <- ev$surv > 0
    expect_equal(ev$se[pos], (sf$surv * sf$std.err)[sf_ev][pos], tolerance = 1e-9,
                 info = paste("case", k))
    # 中央値
    med_sf <- unname(summary(sf)$table["median"])
    expect_equal(km_median(fit), med_sf, info = paste("case", k))
  }
})

test_that("指数分布の閉形式との照合(T-005/G-02)", {
  # 較正実験(loop_002, build/tmp_calib.R, n=2000・20 シード・t≤18h):
  #   max|S_km − exp(−λt)| は最大 0.032 / 中央値 0.021
  #   |中央値 − ln2/λ| は最大 0.355h / 中央値 0.138h
  # → 閾値は余裕を持って S: 0.05、中央値: 0.6h に固定(緩和は較正記録なしに不可)
  lambda <- log(2) / 6  # 半減期 6h
  set.seed(1)
  true_t <- rexp(2000, lambda)
  cens_t <- runif(2000, 0, 24)
  time <- pmin(true_t, cens_t)
  event <- as.integer(true_t <= cens_t)
  fit <- km_fit(time, event)
  sel <- fit$t <= 18
  expect_lt(max(abs(fit$surv[sel] - exp(-lambda * fit$t[sel]))), 0.05)
  expect_lt(abs(km_median(fit) - 6), 0.6)
})

test_that("Greenwood 95%CI(log 型)が survfit と一致(T-015)", {
  skip_if_not_installed("survival")
  library(survival)
  set.seed(3)
  d <- data.frame(time = round(rexp(400, 0.1), 2), event = rbinom(400, 1, 0.7))
  fit <- km_fit(d$time, d$event)
  ci <- km_ci_log(fit)
  sf <- survfit(Surv(d$time, d$event) ~ 1, conf.type = "log")
  ev <- fit$n_event > 0
  sf_ev <- sf$n.event > 0
  expect_equal(ci$lower[ev], sf$lower[sf_ev], tolerance = 1e-9)
  expect_equal(ci$upper[ev], sf$upper[sf_ev], tolerance = 1e-9)
})
