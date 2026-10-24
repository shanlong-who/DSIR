# Build the English site and the maintained Chinese and French reading guides.
# Run from the package root: Rscript pkgdown/build-site.R [destination]
library(pkgdown)
library(rmarkdown)
library(xml2)
library(yaml)
library(digest)
library(fs)
library(withr)

read_utf8 <- function(path) {
  readLines(path, warn = FALSE, encoding = "UTF-8")
}

source_hash <- function(path) {
  digest(paste(read_utf8(path), collapse = "\n"), algo = "sha256",
         serialize = FALSE)
}

extract_chunks <- function(path) {
  lines <- read_utf8(path)
  fences <- which(grepl("^```", lines))
  stopifnot(length(fences) %% 2L == 0L)
  lapply(seq.int(1L, length(fences), by = 2L), function(i) {
    lines[seq.int(fences[i], fences[i + 1L])]
  })
}

assemble_article <- function(template, source) {
  lines <- read_utf8(template)
  chunks <- extract_chunks(source)
  markers <- grep("^<!-- chunk:[0-9]+ -->$", lines)
  numbers <- as.integer(sub("^<!-- chunk:([0-9]+) -->$", "\\1", lines[markers]))
  if (!identical(numbers, seq_along(chunks))) {
    stop("Every source chunk must occur once, in source order: ", template)
  }
  result <- lapply(seq_along(lines), function(i) {
    if (i %in% markers) chunks[[numbers[match(i, markers)]]] else lines[i]
  })
  unlist(result, use.names = FALSE)
}

check_translations <- function(root = ".") {
  manifest <- read_yaml(file.path(root, "pkgdown/i18n/sources.yml"))
  for (source in names(manifest)) {
    if (!identical(source_hash(file.path(root, source)), manifest[[source]])) {
      stop("English source changed; review both translations and update ",
           "pkgdown/i18n/sources.yml: ", source)
    }
  }
  for (language in c("zh", "fr")) {
    for (article in c("DSIR", "ghe-xmart", "visualizing-indicators")) {
      assemble_article(file.path(root, "pkgdown/i18n", language,
                                 paste0(article, ".md")),
                       file.path(root, "vignettes", paste0(article, ".Rmd")))
    }
  }
  invisible(TRUE)
}

translate_home <- function(root, language) {
  text <- paste(read_utf8(file.path(root, "pkgdown/index.md")), collapse = "\n")
  dictionary <- read_yaml(file.path(root, "pkgdown/i18n/home.yml"))
  # Long phrases precede their component words, so replacements cannot overlap.
  order <- order(nchar(vapply(dictionary, `[[`, character(1), "en")), decreasing = TRUE)
  for (entry in dictionary[order]) {
    if (!grepl(entry$en, text, fixed = TRUE)) {
      stop("Homepage translation no longer matches: ", entry$en)
    }
    text <- gsub(entry$en, entry[[language]], text, fixed = TRUE)
  }
  text
}

translated_pages <- c("index.html", "articles/index.html", "articles/DSIR.html",
                      "articles/ghe-xmart.html", "articles/visualizing-indicators.html")

relative_link <- function(target, current) {
  as.character(path_rel(target, start = path_dir(current)))
}

finish_language_pages <- function(destination, language, labels, base.url) {
  prefix <- if (language == "en") "" else paste0(language, "/")
  files <- if (language == "en") {
    candidates <- dir_ls(destination, recurse = TRUE, glob = "*.html")
    candidates[!grepl("^(zh|fr)/", path_rel(candidates, start = destination))]
  } else {
    path(destination, language, translated_pages)
  }
  for (file in files) {
    relative <- as.character(path_rel(file, start = destination))
    page <- if (language == "en") relative else substring(relative, nchar(prefix) + 1L)
    document <- read_html(file, encoding = "UTF-8")
    # pkgdown also emits minimal redirect documents without a page template.
    if (length(xml_find_all(document, "//meta[translate(@http-equiv, 'REFSH', 'refsh')='refresh']"))) next
    code.before <- xml_text(xml_find_all(document, "//pre | //code[not(ancestor::pre)]"))
    xml_set_attr(xml_find_first(document, "//html"), "lang", labels$html_lang)

    menu <- xml_find_first(document, "//ul[li/a[normalize-space(.)='English']]")
    if (inherits(menu, "xml_missing")) stop("Language menu missing: ", file)
    # pkgdown derives dropdown IDs from translated text, which can collide for
    # Chinese labels. Give the language selector a stable, unique accessible ID.
    xml_set_attr(menu, "aria-labelledby", "dropdown-language")
    xml_set_attr(xml_find_first(menu, "../button"), "id", "dropdown-language")
    if (language == "zh") {
      names <- xml_find_all(document, "//text()[contains(., 'Shanlong Ding') and not(ancestor::pre or ancestor::code or ancestor::script)]")
      for (name in names) xml_set_text(name, gsub("Shanlong Ding", "丁善龙", xml_text(name), fixed = TRUE))
    }

    if (language != "en") {
      # Resolve links against their generated location, then route untranslated
      # package pages to the English original. Assets stay inside the locale.
      links <- xml_find_all(document, "//a[@href and not(ancestor::ul[@aria-labelledby='dropdown-language'])]")
      for (link in links) {
        href <- xml_attr(link, "href")
        if (grepl("^(#|[a-zA-Z][a-zA-Z0-9+.-]*:|//)", href)) next
        target <- sub("[?#].*$", "", href)
        suffix <- substring(href, nchar(target) + 1L)
        resolved <- path_norm(path(path_dir(page), target))
        resolved <- sub("^\\./", "", as.character(resolved))
        if (grepl("\\.html$", resolved) && !resolved %in% translated_pages) {
          xml_set_attr(link, "href", paste0(relative_link(resolved, relative), suffix))
          xml_set_attr(link, "hreflang", "en")
          # Code links are already recognisable API names; label prose links.
          if (length(xml_find_all(link, ".//code | ancestor::code | ancestor::pre")) == 0L &&
              !grepl(labels$english, xml_text(link), fixed = TRUE) &&
              nzchar(trimws(xml_text(link)))) {
            xml_add_child(link, "span", paste0(" (", labels$english, ")"),
                          class = "dsi-english-label")
          }
        }
      }
    }

    items <- xml_find_all(menu, ".//a")
    for (i in seq_along(c("en", "zh", "fr"))) {
      target.language <- c("en", "zh", "fr")[i]
      target.prefix <- if (target.language == "en") "" else paste0(target.language, "/")
      # Untranslated pages retain their English entry; other choices open the
      # selected language's tutorials, with the destination explicit in the menu.
      target.page <- if (page %in% translated_pages || target.language == "en") {
        page
      } else "articles/index.html"
      xml_set_attr(items[[i]], "href", relative_link(paste0(target.prefix, target.page), relative))
      xml_set_attr(items[[i]], "lang", c("en", "zh-CN", "fr")[i])
      xml_set_attr(items[[i]], "hreflang", c("en", "zh-CN", "fr")[i])
      if (target.language == language) xml_set_attr(items[[i]], "aria-current", "true")
      if (!page %in% translated_pages && target.language != "en") {
        xml_set_text(items[[i]], c("", "简体中文 · 教程", "Français · Tutoriels")[i])
      }
    }
    head <- xml_find_first(document, "//head")
    xml_remove(xml_find_all(head, "link[@rel='canonical' or @rel='alternate']"))
    xml_add_child(head, "link", rel = "canonical", href = paste0(base.url, relative))
    if (page %in% translated_pages) {
      for (i in seq_along(c("en", "zh", "fr"))) {
        target.prefix <- c("", "zh/", "fr/")[i]
        xml_add_child(head, "link", rel = "alternate", hreflang = c("en", "zh-CN", "fr")[i],
                      href = paste0(base.url, target.prefix, page))
      }
      xml_add_child(head, "link", rel = "alternate", hreflang = "x-default",
                    href = paste0(base.url, page))
    }
    code.after <- xml_text(xml_find_all(document, "//pre | //code[not(ancestor::pre)]"))
    stopifnot(identical(code.before, code.after))
    write_html(document, file, options = "format")
  }
}

build_multilingual_site <- function(root = ".", destination = "docs", build.english = TRUE) {
  root <- path_abs(root)
  destination <- path_abs(destination)
  check_translations(root)
  labels <- read_yaml(path(root, "pkgdown/i18n/navigation.yml"))
  config <- read_yaml(path(root, "_pkgdown.yml"))
  base.url <- config$url
  if (build.english) {
    build_site(root, override = list(destination = destination),
               new_process = FALSE, install = FALSE, preview = FALSE, examples = FALSE)
    finish_language_pages(destination, "en", labels$en, base.url)
  } else {
    stopifnot(file_exists(path(destination, "index.html")))
  }

  for (language in c("zh", "fr")) {
    stage <- tempfile(paste0("dsir-", language, "-"))
    dir_create(stage)
    # A temporary input tree avoids editing the package's English sources.
    for (name in c("DESCRIPTION", "NAMESPACE", "LICENSE", "LICENSE.md", "README.md")) {
      if (file_exists(path(root, name))) file_copy(path(root, name), path(stage, name))
    }
    for (name in c("R", "man", "data")) dir_copy(path(root, name), path(stage, name))
    dir_create(path(stage, "pkgdown"))
    dir_create(path(stage, "vignettes"))
    file_copy(path(root, "pkgdown/extra.css"), path(stage, "pkgdown/extra.css"))
    dir_copy(path(root, "pkgdown/favicon"), path(stage, "pkgdown/favicon"))
    writeLines(translate_home(root, language), path(stage, "pkgdown/index.md"), useBytes = TRUE)
    for (article in c("DSIR", "ghe-xmart", "visualizing-indicators")) {
      content <- assemble_article(path(root, "pkgdown/i18n", language, paste0(article, ".md")),
                                  path(root, "vignettes", paste0(article, ".Rmd")))
      writeLines(content, path(stage, "vignettes", paste0(article, ".Rmd")), useBytes = TRUE)
    }
    local.config <- config
    local.labels <- labels[[language]]
    local.config$lang <- local.labels$pkgdown_lang
    local.config$url <- paste0(base.url, language, "/")
    local.config$destination <- path(destination, language)
    local.config$home$title <- local.labels$title
    local.config$home$description <- local.labels$description
    local.config$navbar$components$home$text <- local.labels$home
    local.config$navbar$components$intro$text <- local.labels$overview
    local.config$navbar$components$reference$text <- local.labels$reference
    local.config$navbar$components$news$text <- local.labels$news
    local.config$navbar$components$language$text <- local.labels$language
    local.config$navbar$components$articles$text <- local.labels$tutorials
    for (i in seq_along(local.labels$articles)) {
      local.config$navbar$components$articles$menu[[i]]$text <- local.labels$articles[[i]]
    }
    local.config$articles <- list(list(title = local.labels$tutorials,
                                      navbar = NULL,
                                      contents = c("DSIR", "ghe-xmart", "visualizing-indicators")))
    write_yaml(local.config, path(stage, "_pkgdown.yml"))
    render_locale <- function() {
      init_site(stage)
      dir_copy(path(root, "man/figures"), path(destination, language, "reference/figures"), overwrite = TRUE)
      build_home_index(stage)
      build_articles(stage, lazy = FALSE)
      build_search(stage)
    }
    if (.Platform$OS.type == "windows") {
      with_envvar(c(LANGUAGE = local.labels$pkgdown_lang), render_locale())
    } else {
      # GNU gettext ignores LANGUAGE under the C message locale. The CI job
      # installs these UTF-8 locales before rendering the translated templates.
      with_envvar(c(LC_ALL = NA, LANG = local.labels$locale,
                    LC_MESSAGES = local.labels$locale, LANGUAGE = local.labels$pkgdown_lang), {
        with_locale(c(LC_MESSAGES = local.labels$locale), render_locale())
      })
    }
    finish_language_pages(destination, language, local.labels, base.url)
  }
  file_create(path(destination, ".nojekyll"))
  invisible(destination)
}

if (sys.nframe() == 0L) {
  arguments <- commandArgs(trailingOnly = TRUE)
  build_multilingual_site(destination = if (length(arguments)) arguments[[1L]] else "docs")
}
