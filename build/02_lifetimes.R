# スナップショット列 → (time, event) → data/processed/(F-02〜F-04)。
suppressPackageStartupMessages({
  library(readr)
  library(dplyr)
})
source("R/lifetimes.R")

INTERVAL <- 3600  # 公称収集間隔 Δ(秒、SPEC §2)

ledger <- read_csv("data/ledger.csv", col_types = "ccc")
stopifnot(nrow(ledger) > 0)

parse_utc <- function(x) {
  t <- as.POSIXct(x, tz = "UTC", format = "%Y-%m-%dT%H:%M:%SZ")  # format 明示(HC-001)
  stopifnot(!any(is.na(t)))
  as.numeric(t)
}

snaps <- lapply(seq_len(nrow(ledger)), function(i) {
  s <- read_csv(file.path("data/snapshots", ledger$filename[i]),
                col_types = "ccccc")
  tibble(guid = s$guid, category = s$category, title = s$title, link = s$link,
         t = parse_utc(s$collected_at_utc))
})
obs <- bind_rows(snaps)
snap_times <- sort(unique(parse_utc(ledger$collected_at_utc)))

lt <- derive_lifetimes(obs[, c("guid", "category", "t")],
                       snap_times = snap_times, interval = INTERVAL)
# 表示用にタイトル・リンク(最後に見えたときのもの)を付ける
meta <- obs |>
  group_by(guid, category) |>
  slice_max(t, n = 1, with_ties = FALSE) |>
  ungroup() |>
  select(guid, category, title, link)
lt <- left_join(lt, meta, by = c("guid", "category"))

dir.create("data/processed", showWarnings = FALSE, recursive = TRUE)
write_csv(lt, "data/processed/lifetimes.csv")
write_csv(tibble(
  n_snapshots = length(snap_times),
  first_utc = format(as.POSIXct(min(snap_times), tz = "UTC"), "%Y-%m-%dT%H:%M:%SZ"),
  latest_utc = format(as.POSIXct(max(snap_times), tz = "UTC"), "%Y-%m-%dT%H:%M:%SZ")
), "data/processed/meta.csv")
message("lifetimes: ", nrow(lt), " stories / ", length(snap_times), " snapshots")
message("LIFETIMES DONE")
