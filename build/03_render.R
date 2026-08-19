# data/processed/ から index + カテゴリ別ページを out/ に生成(F-05/F-06/F-08)。
suppressPackageStartupMessages({
  library(readr)
  library(dplyr)
  library(glue)
})
source("R/km.R")
source("R/plot_km.R")
source("R/footer.R")
source("R/feeds.R")

lt <- read_csv("data/processed/lifetimes.csv", col_types = cols())
meta <- read_csv("data/processed/meta.csv", col_types = cols())
tpl_page <- paste(readLines("site/template_page.html", encoding = "UTF-8"), collapse = "\n")
tpl_index <- paste(readLines("site/template_index.html", encoding = "UTF-8"), collapse = "\n")
footer <- footer_html()

dir.create("out", showWarnings = FALSE)
file.copy("site/style.css", "out/style.css", overwrite = TRUE)

km_all <- km_by_category(lt)
hl <- halflife_table(lt)
hl_label <- function(m) if (is.na(m)) "蓄積中" else sprintf("%.1f 時間", m)

save_svg(plot_km_curves(km_all), "out/km_all.svg", width = 8.5, height = 5.5)

f <- feeds()
for (i in seq_len(nrow(f))) {
  cid <- f$feed_id[i]; cat_ <- f$category[i]
  lt_c <- lt[lt$category == cat_, ]
  km_c <- km_all[km_all$category == cat_, ]
  h <- hl[hl$category == cat_, ]
  dir.create(file.path("out", cid), showWarnings = FALSE)
  save_svg(plot_km_single(km_c, cat_), file.path("out", cid, "km.svg"),
           width = 7.5, height = 5)
  save_svg(plot_ranking_lifetimes(ranking_lifetimes(lt_c), cat_),
           file.path("out", cid, "ranking.svg"), width = 6.5, height = 8)
  save_svg(plot_lifetime_hist(lt_c, cat_), file.path("out", cid, "hist.svg"),
           width = 6.5, height = 4)
  html <- glue(tpl_page,
               category = cat_,
               halflife_label = hl_label(h$median_h),
               n_stories = format(h$n, big.mark = ","),
               n_events = format(h$events, big.mark = ","),
               n_snapshots = meta$n_snapshots,
               first_utc = meta$first_utc,
               latest_utc = meta$latest_utc,
               footer = footer,
               .open = "{{", .close = "}}")
  writeLines(html, file.path("out", cid, "index.html"), useBytes = TRUE)
}

rows <- vapply(seq_len(nrow(hl)), function(i) {
  cid <- f$feed_id[f$category == hl$category[i]]
  sprintf('<tr><td><a href="%s/">%s</a></td><td>%s</td><td>%s</td><td>%s</td></tr>',
          cid, hl$category[i], hl_label(hl$median_h[i]),
          format(hl$n[i], big.mark = ","), format(hl$events[i], big.mark = ","))
}, character(1))

idx <- glue(tpl_index,
            halflife_rows = paste(rows, collapse = "\n        "),
            n_snapshots = meta$n_snapshots,
            first_utc = meta$first_utc,
            latest_utc = meta$latest_utc,
            footer = footer,
            .open = "{{", .close = "}}")
writeLines(idx, "out/index.html", useBytes = TRUE)
message("RENDER DONE")
