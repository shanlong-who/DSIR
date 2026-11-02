# Website sources are excluded from package builds; test them in the checkout.
site_source_helpers <- function() {
  path <- testthat::test_path("..", "..", "pkgdown", "site-sources.R")
  skip_if_not(file.exists(path), "Website helpers are repository-only")
  env <- new.env(parent = baseenv())
  sys.source(path, envir = env)
  env
}

test_that("website staging preserves maintained sources and excludes local files", {
  helpers <- site_source_helpers()
  root <- withr::local_tempdir()
  dir.create(file.path(root, "R"))
  dir.create(file.path(root, "vignettes"))
  dir.create(file.path(root, "pkgdown"))
  dir.create(file.path(root, "scratch"))
  dir.create(file.path(root, ".github"))
  maintained <- c("DESCRIPTION", "NAMESPACE", "README.md", "NEWS.md",
                  "_pkgdown.yml", "R/example.R", "vignettes/example.Rmd",
                  "pkgdown/index.md")
  local <- c("AGENTS.md", "CLAUDE.md", "conversation-export.md",
             "development_proposals.md", "scratch/probe.R", ".github/notes.md")
  for (file in c(maintained, local)) writeLines(paste("Fixture:", file), file.path(root, file))

  stage <- helpers$stage_site_source(root)
  withr::defer(unlink(stage, recursive = TRUE))
  expect_true(all(file.exists(file.path(stage, maintained))))
  expect_identical(unname(tools::md5sum(file.path(stage, maintained))),
                   unname(tools::md5sum(file.path(root, maintained))))
  expect_false(any(file.exists(file.path(stage, local))))
  expect_false(any(dir.exists(file.path(stage, c("scratch", ".github")))))
  expect_true(all(file.exists(file.path(root, local))))
})

test_that("website validation rejects historical development pages and exports", {
  helpers <- site_source_helpers()
  destination <- withr::local_tempdir()
  writeLines("Public homepage", file.path(destination, "index.html"))
  expect_true(helpers$validate_site_sources(destination))

  files <- as.vector(outer(c("AGENTS", "CLAUDE", "conversation-export", "development_proposals"),
                           c("html", "md"), paste, sep = "."))
  for (file in files) {
    writeLines("Private development fixture", file.path(destination, file))
    expect_error(helpers$validate_site_sources(destination), file, fixed = TRUE)
    unlink(file.path(destination, file))
  }
  dir.create(file.path(destination, "zh"))
  writeLines("Private development fixture", file.path(destination, "zh", "agents.html"))
  expect_error(helpers$validate_site_sources(destination), "zh/agents.html", fixed = TRUE)
})

test_that("website staging rejects an in-tree temporary directory", {
  helpers <- site_source_helpers()
  expect_error(helpers$stage_site_source(tempdir()), "outside the package source tree", fixed = TRUE)
})
