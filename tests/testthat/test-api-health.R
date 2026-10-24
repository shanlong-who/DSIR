# The runner is excluded from CRAN builds; these tests run in the checkout.
health_script <- function() {
  path <- testthat::test_path("..", "..", ".github", "scripts", "api-health.R")
  skip_if_not(file.exists(path), "Health runner is repository-only and excluded from the package build")
  env <- new.env(parent = globalenv())
  sys.source(path, envir = env)
  env
}

health_fixture <- function() {
  raw <- tibble::tibble(observation = 1L)
  attr(raw, "who_provenance") <- list(backend = "legacy", complete = TRUE)
  clean <- tibble::tibble(
    source = "gho", id = "X", indicator = "Example", location = "PHL", iso3 = "PHL",
    location_name = "Philippines", year = 2020L, value = "1", value_num = 1,
    low = NA_real_, high = NA_real_, series = NA_character_,
    dim1 = NA_character_, dim2 = NA_character_, dim3 = NA_character_
  )
  list(raw = raw, clean = clean,
       case = list(backend = "legacy", source = "gho", query = "offline fixture",
                   expected = list(id = "X", iso3 = "PHL", year = 2020L),
                   fetch = function() raw, clean = function(x) clean))
}

test_that("health checks reject empty data and warnings even without an API error", {
  health <- health_script()
  fixture <- health_fixture()
  expect_identical(health$run_health_case(fixture$case)$status, "PASS")

  fixture$case$fetch <- function() tibble::tibble()
  empty <- health$run_health_case(fixture$case)
  expect_identical(empty$status, "FAIL")
  expect_match(empty$error, "no observations")

  fixture <- health_fixture()
  raw <- fixture$raw
  fixture$case$fetch <- function() { warning("Service returned suspect data"); raw }
  warned <- health$run_health_case(fixture$case)
  expect_identical(warned$status, "FAIL")
  expect_identical(warned$raw_rows, 1L)
  expect_match(warned$warnings, "suspect data")
})

test_that("health checks reject changed selections, types and incomplete downloads", {
  health <- health_script()
  fixture <- health_fixture()
  for (column in c("iso3", "year", "source", "id")) {
    bad <- fixture$clean
    bad[[column]] <- if (column == "year") 2021L else "unexpected"
    expect_error(health$validate_health(fixture$raw, bad, fixture$case), "Unexpected selection")
  }
  bad <- fixture$clean
  bad$year <- 2020
  expect_error(health$validate_health(fixture$raw, bad, fixture$case), "column types")
  bad <- fixture$clean
  bad$value_num <- NA_real_
  expect_error(health$validate_health(fixture$raw, bad, fixture$case), "usable numeric")
  raw <- fixture$raw
  attr(raw, "who_provenance")$complete <- FALSE
  expect_error(health$validate_health(raw, fixture$clean, fixture$case), "not marked complete")
  attr(raw, "who_provenance") <- list(backend = "xmart", complete = TRUE)
  expect_error(health$validate_health(raw, fixture$clean, fixture$case), "Unexpected WHO provider")
})

test_that("all four health cases run after failures and produce diagnostic reports", {
  health <- health_script()
  fixture <- health_fixture()
  cases <- rep(list(fixture$case), 4L)
  names(cases) <- c("gho_legacy", "gho_xmart", "ghe", "sdg")
  calls <- character()
  for (name in names(cases)) {
    cases[[name]]$fetch <- local({
      check.name <- name
      function() {
        calls <<- c(calls, check.name)
        if (check.name == "gho_legacy") stop("HTTP 503 | <unavailable>")
        if (check.name == "gho_xmart") return(tibble::tibble())
        if (check.name == "ghe") warning("Incomplete response")
        fixture$raw
      }
    })
  }
  output.dir <- withr::local_tempdir()
  results <- suppressMessages(health$run_api_health(output.dir, cases, commit = "offline-test"))
  expect_identical(calls, names(cases))
  expect_identical(results$status, c("FAIL", "FAIL", "FAIL", "PASS"))
  expect_identical(health$health_exit_status(results), 1L)
  expect_identical(read.csv(file.path(output.dir, "results.csv"))$status, results$status)
  report <- paste(readLines(file.path(output.dir, "summary.md")), collapse = "\n")
  expect_match(report, "offline-test", fixed = TRUE)
  expect_match(report, "\\| &lt;unavailable>", fixed = TRUE)
  expect_true(all(file.exists(file.path(output.dir, paste0(names(cases), ".log")))))
  expect_false(any(grepl("\\.rds$", list.files(output.dir))))

  results$status <- "PASS"
  expect_identical(health$health_exit_status(results), 0L)
  results$status[4] <- "NOT_RUN"
  expect_identical(health$health_exit_status(results), 1L)
  expect_identical(health$health_exit_status(results[FALSE, ]), 1L)
  expect_error(health$run_api_health(output.dir, cases[-1]), "All four")
})
