# 収集系のテスト(T-009〜T-011)。実フィードへのネットワークアクセスは行わず、
# パーサは保存済みフィクスチャ(2026-08-19 取得の cat0)に対して検証する。
suppressPackageStartupMessages({
  library(readr)
  library(digest)
  library(xml2)
})
source("../../R/feeds.R", chdir = TRUE)
source("../../R/parse_feed.R", chdir = TRUE)

root <- normalizePath(file.path(testthat::test_path(), "..", ".."))

test_that("フィード定義: cat0〜cat7 の 8 本・全 https・カテゴリ名非空(F-01)", {
  f <- feeds()
  expect_equal(nrow(f), 8)
  expect_equal(f$feed_id, paste0("cat", 0:7))
  expect_true(all(grepl("^https://news\\.web\\.nhk/", f$url)))
  expect_true(all(nchar(f$category) > 0))
  # 2026-08-19 検分: cat0=主要, cat1=社会, cat2=暮らし, cat3=科学・文化,
  # cat4=政治, cat5=経済, cat6=国際, cat7=スポーツ
  expect_equal(f$category[f$feed_id == "cat0"], "主要")
  expect_equal(f$category[f$feed_id == "cat7"], "スポーツ")
})

test_that("RSS パーサ: フィクスチャ XML から guid/link/title を取り出す(T-011)", {
  xml <- read_xml(file.path(testthat::test_path(), "fixtures", "nhk_cat0_sample.xml"))
  d <- parse_feed(xml, category = "主要")
  expect_equal(nrow(d), 7)  # フィクスチャ取得時の item 数(取得時に確認済み)
  expect_true(all(c("guid", "link", "title", "category") == names(d)))
  expect_true(all(grepl("^https://", d$guid)))
  expect_true(all(grepl("^https://", d$link)))
  expect_true(all(nchar(d$title) > 0))
  expect_true(all(d$category == "主要"))
  expect_false(any(duplicated(d$guid)))
})

test_that("台帳整合: 全スナップショットの SHA256 が台帳と一致(T-009/G-03)", {
  ledger <- read_csv(file.path(root, "data", "ledger.csv"), col_types = "ccc")
  snaps <- list.files(file.path(root, "data", "snapshots"), pattern = "^snap-.*\\.csv$")
  # 台帳とディレクトリの集合一致
  expect_setequal(ledger$filename, snaps)
  expect_gt(nrow(ledger), 0)  # 初回収集済みであること
  for (i in seq_len(nrow(ledger))) {
    path <- file.path(root, "data", "snapshots", ledger$filename[i])
    expect_true(file.exists(path), info = ledger$filename[i])
    expect_equal(digest(file = path, algo = "sha256"), ledger$sha256[i],
                 info = ledger$filename[i])
  }
})

test_that("スナップショットの中身: guid 重複 0・時刻整合・列規約(T-010)", {
  ledger <- read_csv(file.path(root, "data", "ledger.csv"), col_types = "ccc")
  skip_if(nrow(ledger) == 0, "スナップショットなし")
  # 台帳の収集時刻が単調非減少
  expect_false(is.unsorted(ledger$collected_at_utc))
  for (fn in ledger$filename) {
    s <- read_csv(file.path(root, "data", "snapshots", fn), col_types = "ccccc")
    expect_equal(names(s), c("guid", "link", "title", "category", "collected_at_utc"))
    # 同一 (guid, category) の重複 0(同一ストーリーが複数カテゴリに載るのは可)
    expect_false(any(duplicated(paste(s$guid, s$category))), info = fn)
    # ファイル名 snap-YYYYMMDD-HHMM.csv と列の収集時刻が一致
    stamp <- sub("^snap-([0-9]{8}-[0-9]{4})\\.csv$", "\\1", fn)
    t <- as.POSIXct(s$collected_at_utc, tz = "UTC", format = "%Y-%m-%dT%H:%M:%SZ")
    expect_false(any(is.na(t)), info = fn)
    expect_true(all(format(t, "%Y%m%d-%H%M", tz = "UTC") == stamp), info = fn)
  }
})
