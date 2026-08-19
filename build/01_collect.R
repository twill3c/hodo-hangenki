# RSS を取得して data/snapshots/ に 1 収集 = 1 CSV(不変)を書き、台帳に追記する(F-01)。
# 使い方: Rscript build/01_collect.R [--at 2026-08-19T13:00:00Z]
#   --at 省略時は現在時刻(UTC、分単位に切り捨て)。R/ は純関数のみの規約のため
#   時刻とネットワークはこのスクリプトだけが扱う。

suppressPackageStartupMessages({
  library(readr)
  library(xml2)
  library(digest)
  library(dplyr)
})
source("R/feeds.R")
source("R/parse_feed.R")

args <- commandArgs(trailingOnly = TRUE)
at <- if (length(args) >= 2 && args[1] == "--at") {
  as.POSIXct(args[2], tz = "UTC", format = "%Y-%m-%dT%H:%M:%SZ")
} else {
  as.POSIXct(trunc(Sys.time(), "mins"), tz = "UTC")
}
stopifnot(!is.na(at))
stamp <- format(at, "%Y%m%d-%H%M", tz = "UTC")
dest <- file.path("data/snapshots", paste0("snap-", stamp, ".csv"))
if (file.exists(dest)) stop("スナップショットが既に存在する(不変規約): ", dest)

f <- feeds()
rows <- vector("list", nrow(f))
for (i in seq_len(nrow(f))) {
  message("fetch: ", f$feed_id[i], " (", f$category[i], ")")
  con <- url(f$url[i], headers = c(`User-Agent` = FEED_UA))
  xml <- read_xml(con)
  rows[[i]] <- parse_feed(xml, f$category[i])
}
snap <- bind_rows(rows)
snap$collected_at_utc <- format(at, "%Y-%m-%dT%H:%M:%SZ", tz = "UTC")

# 同一 (guid, category) はフィード横断でも一意に(cat0 主要と各論カテゴリの併載は許す)
stopifnot(!any(duplicated(paste(snap$guid, snap$category))))

write_csv(snap, dest)
sha <- digest(file = dest, algo = "sha256")
ledger_line <- sprintf("%s,%s,%s\n", basename(dest), sha,
                       format(at, "%Y-%m-%dT%H:%M:%SZ", tz = "UTC"))
cat(ledger_line, file = "data/ledger.csv", append = TRUE)
message("collected: ", nrow(snap), " rows -> ", dest)
message("COLLECT DONE")
