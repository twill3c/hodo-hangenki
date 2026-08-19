# カプラン・マイヤー推定の純関数(F-03/F-04)。IO・時刻・乱数禁止。
# survival パッケージには依存しない(G-05 の照合相手のため)。

suppressPackageStartupMessages(library(tibble))

# 積極限推定。返り値: ユニーク時刻ごとの tibble(t, n_risk, n_event, n_censor, surv, se)
# se は Greenwood: se(S) = S * sqrt(Σ d/(n(n−d)))
km_fit <- function(time, event) {
  stopifnot(length(time) == length(event), all(time >= 0),
            all(event %in% c(0, 1)))
  ts <- sort(unique(time))
  n <- length(time)
  out <- tibble(t = ts, n_risk = 0L, n_event = 0L, n_censor = 0L,
                surv = NA_real_, se = NA_real_)
  s <- 1
  gw <- 0  # Greenwood 累積和 Σ d/(n(n−d))
  for (i in seq_along(ts)) {
    at <- ts[i]
    n_risk <- sum(time >= at)
    d <- sum(time == at & event == 1)
    c_ <- sum(time == at & event == 0)
    if (d > 0) {
      s <- s * (n_risk - d) / n_risk
      if (n_risk - d > 0) {
        gw <- gw + d / (n_risk * (n_risk - d))
      } else {
        gw <- Inf  # S=0 に到達(se は 0 とする — survfit と同じ 0*sqrt(Inf) 回避)
      }
    }
    out$n_risk[i] <- n_risk
    out$n_event[i] <- d
    out$n_censor[i] <- c_
    out$surv[i] <- s
    out$se[i] <- if (s == 0) 0 else s * sqrt(gw)
  }
  out
}

# S(t) を返す(階段関数の右連続評価)。t より後の最初の変化は反映しない。
km_surv_at <- function(fit, t) {
  idx <- which(fit$t <= t)
  if (length(idx) == 0) return(1)
  fit$surv[max(idx)]
}

# 中央生存時間(survfit 慣例: S(t) ≤ 0.5 となる最小のイベント時刻。無ければ NA)
km_median <- function(fit) {
  ev <- fit[fit$n_event > 0 & fit$surv <= 0.5, ]
  if (nrow(ev) == 0) return(NA_real_)
  min(ev$t)
}

# log 型 95% 信頼区間(survfit conf.type="log" と同一):
#   exp(log S ± z * se(S)/S)、上限は 1 に切り詰め。S=0 は NA。
km_ci_log <- function(fit, z = qnorm(0.975)) {
  rel <- ifelse(fit$surv > 0, fit$se / fit$surv, NA_real_)
  lower <- exp(log(fit$surv) - z * rel)
  upper <- pmin(1, exp(log(fit$surv) + z * rel))
  lower[fit$surv == 0] <- NA_real_
  upper[fit$surv == 0] <- NA_real_
  tibble(t = fit$t, lower = lower, upper = upper)
}
