# KM 曲線・半減期表・寿命ランキングの純関数 + SVG 書き出し(F-04/F-05)。
# save_svg 以外はファイル IO なし。時間軸は「時間(h)」で表示する。

suppressPackageStartupMessages({
  library(dplyr)
  library(ggplot2)
})

CAT_ORDER <- c("主要", "社会", "暮らし", "科学・文化", "政治", "経済", "国際", "スポーツ")

# lifetimes(time[s], event, category)→ カテゴリ別 KM 階段関数(時間単位: h)
km_by_category <- function(lt) {
  bind_rows(lapply(split(lt, lt$category), function(d) {
    fit <- km_fit(d$time / 3600, d$event)
    ci <- km_ci_log(fit)
    fit$lower <- ci$lower
    fit$upper <- ci$upper
    fit$category <- d$category[1]
    fit
  }))
}

# カテゴリ別の半減期表: n・イベント数・中央値(h)。イベント不足で NA(=蓄積中)
halflife_table <- function(lt) {
  km <- km_by_category(lt)
  med <- vapply(split(km, km$category), function(k) {
    ev <- k[k$n_event > 0 & k$surv <= 0.5, ]
    if (nrow(ev) == 0) NA_real_ else min(ev$t)
  }, numeric(1))
  out <- lt |>
    group_by(category) |>
    summarise(n = n(), events = sum(event), .groups = "drop")
  out$median_h <- unname(med[out$category])
  arrange(out, match(category, CAT_ORDER))
}

PLOT_THEME <- theme_minimal(base_family = "sans", base_size = 11) +
  theme(plot.background = element_rect(fill = "#ffffff", colour = NA),
        panel.grid.minor = element_blank(),
        plot.title = element_text(size = 12, face = "bold"))

# 全カテゴリの KM 曲線を重ね描き(index の主役)
plot_km_curves <- function(km) {
  km$category <- factor(km$category, levels = CAT_ORDER)
  ggplot(km, aes(t, surv, colour = category)) +
    geom_step(linewidth = 0.7) +
    geom_hline(yintercept = 0.5, linetype = "dashed", colour = "#888888",
               linewidth = 0.3) +
    scale_colour_viridis_d(name = NULL, drop = FALSE) +
    scale_y_continuous(limits = c(0, 1)) +
    labs(x = "見出しに載ってからの経過時間(時間)", y = "生存率 S(t)",
         title = "ニュースはどれだけ見出しに残るか — カテゴリ別 KM 曲線") +
    PLOT_THEME
}

# 1 カテゴリの KM 曲線 + Greenwood 95%CI(カテゴリページの主役)
plot_km_single <- function(km_cat, category) {
  ggplot(km_cat, aes(t, surv)) +
    geom_ribbon(aes(ymin = lower, ymax = upper), fill = "#2563eb", alpha = 0.15) +
    geom_step(colour = "#2563eb", linewidth = 0.8) +
    geom_hline(yintercept = 0.5, linetype = "dashed", colour = "#888888",
               linewidth = 0.3) +
    scale_y_continuous(limits = c(0, 1)) +
    labs(x = "経過時間(時間)", y = "生存率 S(t)",
         title = paste0(category, " — KM 曲線と 95% 信頼区間")) +
    PLOT_THEME
}

# 滞在時間ヒストグラム(確定寿命=event 1 のみ)
plot_lifetime_hist <- function(lt_cat, category, bins = 24) {
  d <- lt_cat[lt_cat$event == 1, ]
  ggplot(d, aes(time / 3600)) +
    geom_histogram(bins = bins, fill = "#5c88c5", colour = NA) +
    labs(x = "滞在時間(時間)", y = "ストーリー数",
         title = paste0(category, " — 確定した滞在時間の分布")) +
    PLOT_THEME
}

# 長寿・短命ランキング(各 10)。打ち切り(event=0)は「≥」付きで長寿側のみ許す
ranking_lifetimes <- function(lt_cat, n = 10) {
  lab <- function(d) paste0(substr(d$title, 1, 24),
                            ifelse(d$event == 0, "(継続中)", ""))
  long <- lt_cat[order(-lt_cat$time, lt_cat$guid), ][seq_len(min(n, nrow(lt_cat))), ]
  dead <- lt_cat[lt_cat$event == 1, ]
  short <- dead[order(dead$time, dead$guid), ][seq_len(min(n, nrow(dead))), ]
  list(long = transform(long, label = lab(long)),
       short = transform(short, label = lab(short)))
}

plot_ranking_lifetimes <- function(rk, category) {
  # 0 行グループ(消滅ゼロの初期運用)にも耐える — transform でなく mutate を使い、
  # 全体 0 行なら「蓄積中」プレースホルダを返す
  d <- bind_rows(mutate(rk$long, group = "長く残った 10"),
                 mutate(rk$short, group = "すぐ消えた 10"))
  if (nrow(d) == 0) {
    return(ggplot() +
             annotate("text", x = 0, y = 0, label = "データ蓄積中", size = 5,
                      colour = "#888888") +
             theme_void(base_family = "sans") +
             theme(plot.background = element_rect(fill = "#ffffff", colour = NA)))
  }
  d$group <- factor(d$group, levels = c("長く残った 10", "すぐ消えた 10"))
  d <- d[order(d$group, -d$time), ]
  d$label <- factor(make.unique(d$label), levels = rev(make.unique(d$label)))
  ggplot(d, aes(time / 3600, label)) +
    geom_col(fill = "#2563eb", width = 0.7) +
    facet_wrap(~group, ncol = 1, scales = "free_y", drop = TRUE) +
    labs(x = "滞在時間(時間)", y = NULL,
         title = paste0(category, " — 滞在時間ランキング")) +
    PLOT_THEME +
    theme(axis.text.y = element_text(size = 7))
}

save_svg <- function(p, path, width, height) {
  ggsave(path, p, device = svglite::svglite, width = width, height = height,
         bg = "#ffffff")
  invisible(path)
}
