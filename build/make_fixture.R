# G-04 回帰フィクスチャ(tests/testthat/fixtures/km_fixture.svg)の生成。
# 実行はフィクスチャ更新時のみ(test: update fixtures 専用コミット + 理由記録)。
# 入力データは tests/testthat/test-render.R の fix_lt と同一に保つこと。
source("R/km.R")
source("R/plot_km.R")

fix_lt <- data.frame(
  time = c(1, 2, 3, 4, 5, 6, 2, 8) * 3600,
  event = c(1, 1, 0, 1, 0, 1, 1, 0),
  category = rep(c("主要", "社会"), each = 4)
)
dir.create("tests/testthat/fixtures", recursive = TRUE, showWarnings = FALSE)
save_svg(plot_km_curves(km_by_category(fix_lt)),
         "tests/testthat/fixtures/km_fixture.svg", width = 8, height = 5)
message("FIXTURE DONE")
