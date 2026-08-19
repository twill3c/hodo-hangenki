# デプロイ・自動化設定の規約テスト(F-07)。
# YAML パーサへの依存を避け、存在と必須文字列で検査する(構文の完全検証は CI 実行が行う)。
suppressPackageStartupMessages(library(jsonlite))

root <- normalizePath(file.path(testthat::test_path(), "..", ".."))

test_that("vercel.json: ビルドなし・outputDirectory=out(F-07)", {
  p <- file.path(root, "vercel.json")
  expect_true(file.exists(p))
  skip_if_not(file.exists(p))
  v <- fromJSON(p)
  expect_equal(v$outputDirectory, "out")
  expect_true(is.null(v$buildCommand))   # null = Vercel 上でビルドしない
  expect_true(is.null(v$framework))
})

test_that("collect ワークフロー: cron 毎時・書き込み権限・パイプライン 3 段(F-07)", {
  p <- file.path(root, ".github", "workflows", "collect.yml")
  expect_true(file.exists(p))
  skip_if_not(file.exists(p))
  y <- paste(readLines(p, encoding = "UTF-8", warn = FALSE), collapse = "\n")
  expect_match(y, "schedule:", fixed = TRUE)
  expect_match(y, "workflow_dispatch", fixed = TRUE)
  expect_match(y, "contents: write", fixed = TRUE)
  expect_match(y, "concurrency", fixed = TRUE)     # 多重実行の防止
  for (s in c("build/01_collect.R", "build/02_lifetimes.R", "build/03_render.R")) {
    expect_match(y, s, fixed = TRUE)
  }
  # 収集間隔規約(SPEC §5): 毎時 1 回(分指定の毎時 cron)
  expect_match(y, "cron:", fixed = TRUE)
  expect_match(y, "\\* \\* \\* \\*")
})
