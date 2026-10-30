test_that("the bundled legacy catalog has complete metadata and valid fields", {
  snapshot <- readRDS(system.file("extdata", "gho-indicators.rds", package = "DSIR"))
  expect_identical(snapshot$backend, "legacy")
  expect_identical(snapshot$source, "https://ghoapi.azureedge.net/api/Indicator")
  expect_match(snapshot$retrieved, "^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9:]{8}Z$")
  expect_gt(nrow(snapshot$catalog), 0L)
  expect_named(snapshot$catalog, c("IndicatorCode", "IndicatorName", "Language"))
  expect_true(all(vapply(snapshot$catalog, is.character, logical(1))))
  expect_false(anyNA(snapshot$catalog))
  expect_false(anyDuplicated(snapshot$catalog[c("IndicatorCode", "Language")]) > 0L)
  expect_true("UHC_INDEX_REPORTED" %in% snapshot$catalog$IndicatorCode)
})

test_that("legacy failures use a dated snapshot with literal AND search semantics", {
  calls <- 0L
  httr2::with_mocked_responses(function(req) {
    calls <<- calls + 1L
    who_response("<html>Server Error</html>", status = 500L)
  }, {
    warnings <- character()
    out <- withCallingHandlers(gho_indicators("UHC service coverage", backend = "legacy"),
      warning = function(w) {
        warnings <<- c(warnings, conditionMessage(w))
        invokeRestart("muffleWarning")
      })
    expect_true(any(grepl("HTTP 500", warnings, fixed = TRUE)))
    expect_true(any(grepl("bundled legacy GHO.*[0-9]{4}-[0-9]{2}-[0-9]{2}", warnings)))
    expect_true("UHC_INDEX_REPORTED" %in% out$IndicatorCode)
    expect_identical(attr(out, "catalog_snapshot")$backend, "legacy")
    for (term in c("uhc", "service", "coverage")) {
      expect_true(all(grepl(term, tolower(out$IndicatorName), fixed = TRUE)))
    }
    phrase <- suppressWarnings(gho_indicators(c("UHC", "Service Coverage"), backend = "legacy"))
    expect_equal(phrase, out)
    literal <- suppressWarnings(gho_indicators(".*", backend = "legacy"))
    expect_equal(nrow(literal), 0L)
    expect_false(is.null(attr(literal, "catalog_snapshot")))
    catalog <- suppressWarnings(gho_indicators(backend = "legacy"))
    expect_gt(nrow(catalog), nrow(out))
  })
  # httr2 mocks bypass retry; only the chosen backend is requested.
  expect_equal(calls, 4L)
})

test_that("successful live searches take priority including zero matches", {
  httr2::with_mocked_responses(who_page('{"value":[]}'), {
    expect_no_warning(out <- gho_indicators("unknown", backend = "legacy"))
    expect_equal(nrow(out), 0L)
    expect_null(attr(out, "catalog_snapshot"))
  })
  httr2::with_mocked_responses(who_page(paste0('{"value":[{"IndicatorCode":"NEW",',
    '"IndicatorName":"New live name","Language":"EN"}]}')), {
    expect_no_warning(out <- gho_indicators("New", backend = "legacy"))
    expect_equal(out$IndicatorCode, "NEW")
    expect_null(attr(out, "catalog_snapshot"))
  })
})

test_that("invalid JSON and malformed legacy catalogs use the snapshot", {
  for (body in c('{broken', '{}', '{"value":[{"Unexpected":"field"}]}')) {
    httr2::with_mocked_responses(who_page(body), {
      out <- suppressWarnings(gho_indicators("UHC", backend = "legacy"))
      expect_true("UHC_INDEX_REPORTED" %in% out$IndicatorCode)
      expect_false(is.null(attr(out, "catalog_snapshot")))
    })
  }
})

test_that("xMart failures never consult the legacy snapshot", {
  testthat::local_mocked_bindings(
    .xmart_catalog = function() NULL,
    .gho_bundled_catalog = function(...) stop("Legacy snapshot called"),
    .package = "DSIR"
  )
  out <- gho_indicators("UHC", backend = "xmart")
  expect_equal(nrow(out), 0L)
  expect_null(attr(out, "catalog_snapshot"))
})
