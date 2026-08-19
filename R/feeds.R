# フィード定義(F-01)。URL は 2026-08-19 に検分した最終 URL(旧 www.nhk.or.jp/rss は
# news.web.nhk へ 301 — リダイレクト依存を避けるため最終 URL を pin)。
# cat8 は 404(存在しない)。

suppressPackageStartupMessages(library(tibble))

FEED_UA <- "hodo-hangenki/0.1 (+https://github.com/twill3c/hodo-hangenki)"

feeds <- function() {
  base <- "https://news.web.nhk/n-data/conf/na/rss/"
  tibble(
    feed_id  = paste0("cat", 0:7),
    category = c("主要", "社会", "暮らし", "科学・文化",
                 "政治", "経済", "国際", "スポーツ"),
    url = paste0(base, "cat", 0:7, ".xml")
  )
}
