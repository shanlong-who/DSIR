# Keep local development documents out of pkgdown's automatic Markdown scan.
# This file uses base R so its regression tests need no website dependencies.
stage_site_source <- function(root) {
  root <- normalizePath(root, winslash = "/", mustWork = TRUE)
  temporary <- normalizePath(tempdir(), winslash = "/", mustWork = TRUE)
  if (tolower(temporary) == tolower(root) ||
      startsWith(tolower(temporary), paste0(tolower(root), "/"))) {
    stop("Use a temporary directory outside the package source tree.", call. = FALSE)
  }
  stage <- tempfile("dsir-site-source-")
  dir.create(stage)
  entries <- c("DESCRIPTION", "NAMESPACE", "LICENSE", "LICENSE.md", "README.md",
               "NEWS.md", ".Rbuildignore", "_pkgdown.yml", "R", "man", "data",
               "inst", "demo", "vignettes", "pkgdown")
  sources <- file.path(root, entries)
  sources <- sources[file.exists(sources)]
  if (!all(file.copy(sources, stage, recursive = TRUE))) {
    stop("Could not prepare the website source tree.", call. = FALSE)
  }
  stage
}

validate_site_sources <- function(destination) {
  files <- list.files(destination, recursive = TRUE, all.files = TRUE)
  forbidden <- grepl(
    "^(AGENTS|CLAUDE|conversation-export|development_proposals)\\.(html|md)$",
    basename(files), ignore.case = TRUE)
  if (any(forbidden)) {
    stop("Development files must not be published: ",
         paste(files[forbidden], collapse = ", "), call. = FALSE)
  }
  invisible(TRUE)
}
