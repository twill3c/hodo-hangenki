# スナップショット観測列 → (time, event) の純関数(F-02)。定義は TEST_SPEC T-006〜T-008:
#   Δ = 公称収集間隔(interval、秒)
#   消滅(最新スナップショットに不在): time = last_seen − first_seen + Δ, event = 1
#   在留(最新に存在): time = latest − first_seen, event = 0
# 収集欠損は「不在の観測」ではないため、欠損跨ぎの在留は 1 ストーリーのまま扱う
# (在の観測だけから first/last を取るので、この定義では自然に満たされる)。

suppressPackageStartupMessages(library(dplyr))

# obs: tibble(guid, category, t[秒])— 「時刻 t のスナップショットに載っていた」観測
# snap_times: 全スナップショット時刻(昇順)。latest = max(snap_times)
derive_lifetimes <- function(obs, snap_times, interval) {
  stopifnot(length(snap_times) > 0, interval > 0,
            all(obs$t %in% snap_times))
  latest <- max(snap_times)
  obs |>
    group_by(guid, category) |>
    summarise(first_seen = min(t), last_seen = max(t), .groups = "drop") |>
    mutate(
      event = ifelse(last_seen == latest, 0L, 1L),
      time = ifelse(event == 1L,
                    last_seen - first_seen + interval,
                    latest - first_seen)
    ) |>
    select(guid, category, time, event, first_seen, last_seen)
}
