# フッタ定義(F-06)。フリート標準の並び:
# MIT License(© 2026 坂田哲朗)・GitHub・歩き方・設計図・App Menu
# 歩き方/設計図はアーティファクト(2026-08-19 公開。閲覧には所有者の共有設定が必要)。

footer_links <- function() {
  list(
    list(label = "MIT License",
         href = "https://github.com/twill3c/hodo-hangenki/blob/main/LICENSE"),
    list(label = "GitHub",
         href = "https://github.com/twill3c/hodo-hangenki"),
    list(label = "hodo-hangenki の歩き方",
         href = "https://claude.ai/code/artifact/bad3724b-e037-4884-8498-883d94612f07"),
    list(label = "hodo-hangenki 設計図",
         href = "https://claude.ai/code/artifact/771cc407-8d2d-43fb-a1d6-37bfebbdc4c7"),
    list(label = "App Menu",
         href = "https://app-menu-amber.vercel.app")
  )
}

footer_html <- function(links = footer_links()) {
  parts <- vapply(seq_along(links), function(i) {
    l <- links[[i]]
    sep <- if (i > 1) " ・ " else ""
    suffix <- if (l$label == "MIT License") " © 2026 坂田哲朗" else ""
    sprintf('%s<a href="%s" target="_blank" rel="noopener">%s</a>%s',
            sep, l$href, l$label, suffix)
  }, character(1))
  sprintf('<footer class="site-footer"><p>%s</p></footer>',
          paste(parts, collapse = ""))
}
