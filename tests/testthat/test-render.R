# レンダリング(T-012〜T-014 / F-05, F-06, F-08, G-04)。
# 単体はフィクスチャ駆動、統合は build/02_lifetimes.R → build/03_render.R 実行後の out/。
suppressPackageStartupMessages({
  library(digest)
  library(dplyr)
})
source("../../R/km.R", chdir = TRUE)
source("../../R/plot_km.R", chdir = TRUE)
source("../../R/footer.R", chdir = TRUE)

root <- normalizePath(file.path(testthat::test_path(), "..", ".."))
out_dir <- file.path(root, "out")

fix_lt <- data.frame(
  time = c(1, 2, 3, 4, 5, 6, 2, 8) * 3600,
  event = c(1, 1, 0, 1, 0, 1, 1, 0),
  category = rep(c("主要", "社会"), each = 4)
)

test_that("G-04: KM 曲線 SVG の 2 回レンダリングでバイト一致(T-012)", {
  km <- km_by_category(fix_lt)
  f1 <- tempfile(fileext = ".svg"); f2 <- tempfile(fileext = ".svg")
  save_svg(plot_km_curves(km), f1, width = 8, height = 5)
  save_svg(plot_km_curves(km), f2, width = 8, height = 5)
  expect_equal(digest(file = f1, algo = "sha256"), digest(file = f2, algo = "sha256"))
})

test_that("G-04: 回帰フィクスチャとハッシュ一致(T-012)", {
  fixture <- file.path(testthat::test_path(), "fixtures", "km_fixture.svg")
  expect_true(file.exists(fixture), info = "build/make_fixture.R 未実行")
  skip_if_not(file.exists(fixture))
  km <- km_by_category(fix_lt)
  f <- tempfile(fileext = ".svg")
  save_svg(plot_km_curves(km), f, width = 8, height = 5)
  expect_equal(digest(file = f, algo = "sha256"),
               digest(file = fixture, algo = "sha256"))
})

test_that("半減期表: カテゴリごとの中央値と件数(F-04 の表示用)", {
  h <- halflife_table(fix_lt)
  expect_equal(nrow(h), 2)
  expect_true(all(c("category", "n", "events", "median_h") %in% names(h)))
  expect_equal(h$n, c(4, 4))
})

test_that("全件打ち切り(消滅ゼロ)でもランキング・ヒスト・半減期表が描ける(初期運用の正常系)", {
  cens <- data.frame(time = c(0, 3600, 7200), event = c(0, 0, 0),
                     category = "主要", guid = c("a", "b", "c"),
                     title = c("あ", "い", "う"))
  h <- halflife_table(cens)
  expect_true(is.na(h$median_h))
  rk <- ranking_lifetimes(cens)
  expect_equal(nrow(rk$short), 0)
  f <- tempfile(fileext = ".svg")
  save_svg(plot_ranking_lifetimes(rk, "主要"), f, width = 6, height = 6)
  expect_true(file.size(f) > 0)
  f2 <- tempfile(fileext = ".svg")
  save_svg(plot_lifetime_hist(cens, "主要"), f2, width = 6, height = 4)
  expect_true(file.size(f2) > 0)
})

test_that("フッタ定義: フリート標準 5 リンク・全 https(T-014/F-06)", {
  links <- footer_links()
  labels <- vapply(links, function(l) l$label, character(1))
  expect_equal(labels, c("MIT License", "GitHub",
                         "hodo-hangenki の歩き方", "hodo-hangenki 設計図",
                         "App Menu"))
  hrefs <- vapply(links, function(l) l$href, character(1))
  for (h in hrefs) expect_match(h, "^https://")
  expect_false(hrefs[3] == hrefs[4])
  expect_match(hrefs[3], "^https://claude\\.ai/code/artifact/")
  expect_match(hrefs[4], "^https://claude\\.ai/code/artifact/")
  expect_match(footer_html(links), "© 2026 坂田哲朗", fixed = TRUE)
})

# ---- 統合(out/) ----

test_that("out/ の構成: index + カテゴリ 8 ページ + 定型 4 ブロック + JS なし(T-013)", {
  expect_true(file.exists(file.path(out_dir, "index.html")),
              info = "03_render 未実行")
  skip_if_not(file.exists(file.path(out_dir, "index.html")))
  cats <- paste0("cat", 0:7)
  for (cid in cats) {
    page <- file.path(out_dir, cid, "index.html")
    expect_true(file.exists(page), info = cid)
    html <- paste(readLines(page, encoding = "UTF-8", warn = FALSE), collapse = "\n")
    for (cls in c("block-map", "block-ranking", "block-hist", "block-notes",
                  "site-footer")) {
      expect_match(html, cls, fixed = TRUE, info = paste(cid, cls))
    }
    expect_false(grepl("<script", html, fixed = TRUE), info = cid)
    expect_match(html, "NHK", fixed = TRUE)      # 出典明記(SPEC §5)
    expect_match(html, "取得", fixed = TRUE)     # 取得時刻の明記
  }
  idx <- paste(readLines(file.path(out_dir, "index.html"), encoding = "UTF-8",
                         warn = FALSE), collapse = "\n")
  expect_match(idx, "半減期", fixed = TRUE)
  expect_false(grepl("<script", idx, fixed = TRUE))
})
