# Validate generated multilingual pages and shared examples without live APIs.
# Run after building: Rscript pkgdown/validate-site.R [destination]
source("pkgdown/build-site.R")

validate_multilingual_site <- function(destination = "docs") {
  check_translations()
  destination <- path_abs(destination)
  failures <- character()
  check <- function(condition, message) {
    if (!isTRUE(condition)) failures <<- c(failures, message)
  }

  for (language in c("en", "zh", "fr")) {
    prefix <- if (language == "en") "" else paste0(language, "/")
    for (page in translated_pages) {
      relative <- paste0(prefix, page)
      file <- path(destination, relative)
      check(file_exists(file), paste("Missing page:", relative))
      if (!file_exists(file)) next
      document <- read_html(file, encoding = "UTF-8")
      check(length(xml_find_all(document, "//pre//span[@class='dsi-english-label'] | //code//span[@class='dsi-english-label']")) == 0L,
            paste("Language label changes copied code:", relative))
      expected.lang <- c(en = "en", zh = "zh-CN", fr = "fr")[[language]]
      check(identical(xml_attr(xml_find_first(document, "//html"), "lang"), expected.lang),
            paste("Incorrect document language:", relative))
      check(!grepl("<!-- chunk:", paste(read_utf8(file), collapse = "\n"), fixed = TRUE),
            paste("Unresolved code marker:", relative))
      alternates <- xml_find_all(document, "//link[@rel='alternate']")
      check(length(alternates) == 4L, paste("Missing language alternates:", relative))
      canonical <- xml_attr(xml_find_first(document, "//link[@rel='canonical']"), "href")
      check(endsWith(canonical, relative), paste("Incorrect canonical URL:", relative))

      links <- xml_find_all(document, "//a[@href]")
      for (link in links) {
        href <- xml_attr(link, "href")
        if (grepl("^([a-zA-Z][a-zA-Z0-9+.-]*:|//)", href)) next
        target <- sub("[?#].*$", "", href)
        resolved <- if (nzchar(target)) path_norm(path(path_dir(file), URLdecode(target))) else file
        check(file_exists(resolved), paste("Broken link:", relative, "->", href))
        if (grepl("#", href, fixed = TRUE) && file_exists(resolved) &&
            grepl("\\.html$", resolved)) {
          anchor <- URLdecode(sub("^[^#]*#", "", href))
          if (nzchar(anchor)) {
            target.doc <- if (resolved == file) document else read_html(resolved)
            ids <- xml_attr(xml_find_all(target.doc, "//*[@id]"), "id")
            check(anchor %in% ids, paste("Missing anchor:", relative, "->", href))
          }
        }
      }

      assets <- xml_find_all(document, "//img[@src] | //script[@src] | //link[@rel='stylesheet']")
      for (asset in assets) {
        href <- xml_attr(asset, if (xml_name(asset) == "link") "href" else "src")
        if (grepl("^([a-zA-Z][a-zA-Z0-9+.-]*:|//)", href)) next
        resolved <- path_norm(path(path_dir(file), sub("[?#].*$", "", href)))
        check(file_exists(resolved), paste("Missing asset:", relative, "->", href))
      }

      menu <- xml_find_all(document, "//ul[@aria-labelledby='dropdown-language']//a")
      check(length(menu) == 3L, paste("Incorrect language menu:", relative))
      if (length(menu) == 3L) {
        for (i in seq_along(menu)) {
          target <- path_norm(path(path_dir(file), xml_attr(menu[[i]], "href")))
          expected <- path_norm(path(destination, c("", "zh/", "fr/")[i], page))
          check(target == expected, paste("Language switch loses current page:", relative))
        }
      }
    }
  }

  # The two locales must execute exactly the existing source chunks, including
  # hidden setup, evaluation guards, plot sizes and random seeds.
  for (language in c("zh", "fr")) {
    for (article in c("DSIR", "ghe-xmart", "visualizing-indicators")) {
      template <- path("pkgdown/i18n", language, paste0(article, ".md"))
      source <- path("vignettes", paste0(article, ".Rmd"))
      generated <- tempfile(fileext = ".Rmd")
      writeLines(assemble_article(template, source), generated, useBytes = TRUE)
      actual <- Filter(function(chunk) grepl("^```\\{r", chunk[[1L]]), extract_chunks(generated))
      check(identical(actual, extract_chunks(source)), paste("Example code differs:", template))
    }
  }

  if (length(failures)) stop(paste(unique(failures), collapse = "\n"), call. = FALSE)
  message("Validated 15 multilingual pages: languages, switches, links, anchors, assets and shared R chunks.")
  invisible(TRUE)
}

if (sys.nframe() == 0L) {
  arguments <- commandArgs(trailingOnly = TRUE)
  validate_multilingual_site(if (length(arguments)) arguments[[1L]] else "docs")
}
