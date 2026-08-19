# RSS 2.0 → 行データの純関数(T-011)。入力は xml2::read_xml 済みドキュメント。
# ネットワーク・時刻は扱わない(収集時刻は build/01_collect.R が付与する)。

suppressPackageStartupMessages({
  library(xml2)
  library(tibble)
})

parse_feed <- function(xml, category) {
  items <- xml_find_all(xml, "//item")
  guid <- xml_text(xml_find_first(items, "guid"))
  link <- xml_text(xml_find_first(items, "link"))
  d <- tibble(
    guid = ifelse(is.na(guid) | guid == "", link, guid),  # guid 欠落時は link で識別(SPEC §2)
    link = link,
    title = xml_text(xml_find_first(items, "title")),
    category = category
  )
  if (any(is.na(d$guid) | d$guid == "")) stop("guid も link も無い item がある")
  # 同一フィード内の重複 guid は最初の 1 件を採る(再掲対策)
  d[!duplicated(d$guid), ]
}
