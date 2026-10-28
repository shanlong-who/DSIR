test_that("SDG update queries use the V5 database endpoint and preserve raw time", {
  urls <- character()
  started <- Sys.time()
  httr2::with_mocked_responses(function(req) {
    urls <<- c(urls, req$url)
    who_response('"2026-09-30T16:48:24"')
  }, {
    out <- sdg_last_updated()
    again <- sdg_last_updated()
  })
  expect_s3_class(out, "tbl_df")
  expect_named(out, c("source", "backend", "scope", "indicator", "updated",
                      "timestamp_field", "checked_at", "status"))
  expect_equal(nrow(out), 1L)
  expect_identical(out$source, "sdg")
  expect_identical(out$scope, "database")
  expect_identical(out$backend, NA_character_)
  expect_identical(out$indicator, NA_character_)
  expect_identical(out$updated, "2026-09-30T16:48:24")
  expect_identical(out$timestamp_field, "Series/LastUpdated")
  expect_identical(out$status, "ok")
  expect_s3_class(out$checked_at, "POSIXct")
  expect_identical(attr(out$checked_at, "tzone"), "UTC")
  expect_gte(as.numeric(out$checked_at), as.numeric(started))
  expect_lte(as.numeric(out$checked_at), as.numeric(Sys.time()))
  expect_identical(urls, rep(paste0(
    "https://unstats.un.org/sdgs/UNSDGAPIV5/v1/sdg/Series/LastUpdated"
  ), 2L))
  expect_identical(again$updated, out$updated)
})

test_that("legacy update queries request only the latest non-missing date", {
  withr::local_options(DSIR.who_backend = NULL)
  urls <- character()
  httr2::with_mocked_responses(function(req) {
    urls <<- c(urls, utils::URLdecode(req$url))
    who_response('{"value":[{"Date":"2026-05-18T12:07:03.230+02:00"}]}')
  }, out <- gho_last_updated("WHS4_100"))
  expect_identical(out$source, "gho")
  expect_identical(out$backend, "legacy")
  expect_identical(out$scope, "indicator")
  expect_identical(out$indicator, "WHS4_100")
  expect_identical(out$updated, "2026-05-18T12:07:03.230+02:00")
  expect_identical(out$timestamp_field, "Date")
  expect_identical(out$status, "ok")
  expect_length(urls, 1L)
  expect_match(urls, "https://ghoapi.azureedge.net/api/WHS4_100?", fixed = TRUE)
  expect_match(urls, "$select=Date", fixed = TRUE)
  expect_match(urls, "$filter=Date ne null", fixed = TRUE)
  expect_match(urls, "$orderby=Date desc", fixed = TRUE)
  expect_match(urls, "$top=1", fixed = TRUE)
  expect_false(grepl("$count", urls, fixed = TRUE))
  expect_null(getOption("DSIR.who_backend"))
})

test_that("update queries inherit backend options and explicit overrides", {
  withr::local_options(DSIR.who_backend = "xmart")
  testthat::local_mocked_bindings(
    .xmart_gho_route = function(indicator) list(path = "DATA_/RELAY_WHS", id = "ID'X"),
    .xmart_fields = function(path) c("IND_ID", "Sys_CommitDateUtc"),
    .package = "DSIR"
  )
  urls <- character()
  httr2::with_mocked_responses(function(req) {
    urls <<- c(urls, utils::URLdecode(req$url))
    who_response(if (grepl("azureedge", req$url))
      '{"value":[{"Date":"2026-09-30T16:48:24Z"}]}' else
      '{"value":[{"Sys_CommitDateUtc":"2026-05-18T10:07:03.23Z"}]}')
  }, {
    xmart <- gho_last_updated("X")
    legacy <- gho_last_updated("X", backend = "legacy")
    expect_equal(getOption("DSIR.who_backend"), "xmart")
    withr::local_options(DSIR.who_backend = "legacy")
    explicit <- gho_last_updated("X", backend = "xmart")
    expect_equal(getOption("DSIR.who_backend"), "legacy")
  })
  expect_identical(xmart$backend, "xmart")
  expect_identical(legacy$backend, "legacy")
  expect_identical(explicit$backend, "xmart")
  expect_identical(xmart$updated, "2026-05-18T10:07:03.23Z")
  expect_identical(xmart$timestamp_field, "Sys_CommitDateUtc")
  expect_length(urls, 3L)
  expect_match(urls[1], "IND_ID eq 'ID''X'", fixed = TRUE)
  expect_match(urls[1], "Sys_CommitDateUtc ne null", fixed = TRUE)
  expect_match(urls[1], "$select=Sys_CommitDateUtc", fixed = TRUE)
  expect_match(urls[1], "$orderby=Sys_CommitDateUtc desc", fixed = TRUE)
  expect_match(urls[1], "$top=1", fixed = TRUE)
})

test_that("xMart update queries use the existing directory route and custom origin", {
  withr::local_options(DSIR.who_base_url = "https://updates-test.who.int")
  testthat::local_mocked_bindings(
    .xmart_catalog = function() tibble::tibble(
      IND_CODE_GHO = "X", IND_PER_CODE = "X", IND_ID = "EXACT_ID",
      IND_NAME_FULL = "Test", IND_UNIT = "percent",
      DWNL_QUERY = "https://portal-uat.who.int/xmart4/DATA_/data/RELAY_TEST",
      IND_PUBLISH_TABLE = NA_character_
    ),
    .package = "DSIR"
  )
  urls <- character()
  httr2::with_mocked_responses(function(req) {
    urls <<- c(urls, utils::URLdecode(req$url))
    who_response('{"value":[{"Sys_CommitDateUtc":"2026-01-02T03:04:05Z"}]}')
  }, out <- gho_last_updated("X", backend = "xmart"))
  expect_identical(out$status, "ok")
  expect_length(urls, 2L)
  expect_true(all(startsWith(urls, "https://updates-test.who.int/DATA_/RELAY_TEST?")))
  expect_match(urls[2], "IND_ID eq 'EXACT_ID'", fixed = TRUE)
  expect_false(any(grepl("portal-uat", urls, fixed = TRUE)))
})

test_that("invalid update arguments fail before network calls", {
  testthat::local_mocked_bindings(
    .dsi_request = function(...) stop("network called"), .package = "DSIR"
  )
  for (indicator in list(NULL, character(), NA_character_, "", "  ",
                        c("X", "Y"), 1L, list("X"))) {
    expect_error(gho_last_updated(indicator), "indicator")
  }
  for (backend in list("auto", "XMart", "", NA_character_, character(),
                      c("legacy", "xmart"), 1L)) {
    expect_error(gho_last_updated("X", backend = backend), "backend")
  }
  withr::local_options(DSIR.who_backend = "invalid")
  expect_error(gho_last_updated("X"), "DSIR.who_backend")
  expect_error(sdg_last_updated(indicator = "3.2.1"), "unused argument")
})

test_that("missing timestamps retain one row and differ from request failures", {
  for (body in c("null", '""', '"  "')) {
    httr2::with_mocked_responses(who_page(body), out <- sdg_last_updated())
    expect_identical(out$status, "not_available")
    expect_identical(out$updated, NA_character_)
    expect_equal(nrow(out), 1L)
  }
  for (body in c('{"value":[]}', '{"value":[{"Date":null}]}')) {
    httr2::with_mocked_responses(who_page(body),
      out <- gho_last_updated("X", backend = "legacy"))
    expect_identical(out$status, "not_available")
    expect_identical(out$updated, NA_character_)
    expect_equal(nrow(out), 1L)
  }
})

test_that("xMart distinguishes unavailable timestamps from failed lookups", {
  testthat::local_mocked_bindings(
    .xmart_gho_route = function(indicator) list(path = "DATA_/RELAY_WHS", id = "ID"),
    .xmart_fields = function(path) "IND_ID",
    .who_query = function(...) stop("date request should not run"),
    .package = "DSIR"
  )
  expect_identical(gho_last_updated("X", backend = "xmart")$status, "not_available")
  testthat::local_mocked_bindings(.xmart_fields = function(path) character(), .package = "DSIR")
  expect_identical(gho_last_updated("X", backend = "xmart")$status, "failed")
  testthat::local_mocked_bindings(.xmart_gho_route = function(indicator) NULL, .package = "DSIR")
  expect_identical(gho_last_updated("X", backend = "xmart")$status, "failed")
})

test_that("xMart unknown codes warn without querying another provider", {
  testthat::local_mocked_bindings(
    .xmart_catalog = function() tibble::tibble(IND_CODE_GHO = "KNOWN"),
    .dsi_request = function(...) stop("network called"), .package = "DSIR"
  )
  expect_warning(out <- gho_last_updated("UNKNOWN", backend = "xmart"), "not listed in the public xMart directory")
  expect_identical(out$status, "failed")
  expect_identical(out$backend, "xmart")
  expect_identical(out$updated, NA_character_)
})

test_that("update failures never fall back and preserve output types", {
  testthat::local_mocked_bindings(
    .xmart_gho_route = function(indicator) list(path = "DATA_/RELAY_WHS", id = "ID"),
    .xmart_fields = function(path) "Sys_CommitDateUtc",
    .package = "DSIR"
  )
  for (backend in c("legacy", "xmart")) {
    urls <- character()
    httr2::with_mocked_responses(function(req) {
      urls <<- c(urls, req$url)
      who_response('{"error":"failed {external}"}', status = 500L)
    }, {
      expect_warning(out <- gho_last_updated("X", backend = backend), "request failed")
    })
    expect_length(urls, 1L)
    expect_identical(out$backend, backend)
    expect_identical(out$status, "failed")
    expect_identical(out$updated, NA_character_)
    expect_true(startsWith(urls, if (backend == "legacy")
      "https://ghoapi.azureedge.net/" else "https://xmart-api-public.who.int/"))
  }
  httr2::with_mocked_responses(list(who_response('{}', status = 503L)), {
    expect_warning(out <- sdg_last_updated(), "SDG update request failed")
    expect_identical(out$status, "failed")
    expect_identical(out$updated, NA_character_)
  })
})

test_that("legacy missing codes use the existing directory diagnostic", {
  urls <- character()
  httr2::with_mocked_responses(function(req) {
    urls <<- c(urls, req$url)
    if (length(urls) == 1L) who_response('{}', status = 404L) else
      who_response('{"value":[]}')
  }, {
    expect_warning(out <- gho_last_updated("UNKNOWN", backend = "legacy"),
                   "absent from the legacy directory")
  })
  expect_identical(out$status, "failed")
  expect_identical(out$updated, NA_character_)
  expect_length(urls, 2L)
  expect_true(all(startsWith(urls, "https://ghoapi.azureedge.net/")))
  expect_match(urls[2], "/api/Indicator?", fixed = TRUE)
})

test_that("malformed update JSON fails soft even with braces in parser errors", {
  testthat::local_mocked_bindings(
    .xmart_gho_route = function(indicator) list(path = "DATA_/RELAY_WHS", id = "ID"),
    .xmart_fields = function(path) "Sys_CommitDateUtc",
    .package = "DSIR"
  )
  calls <- list(sdg_last_updated,
    function() gho_last_updated("X", backend = "legacy"),
    function() gho_last_updated("X", backend = "xmart"))
  for (fun in calls) {
    httr2::with_mocked_responses(who_page('{"broken":{'), {
      expect_warning(out <- fun(), "could not be parsed as JSON")
      expect_identical(out$status, "failed")
      expect_identical(out$updated, NA_character_)
    })
  }
})

test_that("malformed scalar timestamps are not reported as successful updates", {
  for (body in c('42', 'true', '{}', '[]', '["2026-01-01T00:00:00","2026-02-01T00:00:00"]',
                 '"2026"', '"not a date"', '"2026-02-30T00:00:00"',
                 '"2026-01-01T25:00:00"', '"2026-01-01T00:00:00+99:00"')) {
    httr2::with_mocked_responses(who_page(body), {
      expect_warning(out <- sdg_last_updated(), "invalid timestamp")
      expect_identical(out$status, "failed")
      expect_identical(out$updated, NA_character_)
    })
  }
})

test_that("unexpected GHO envelopes cannot masquerade as latest dates", {
  for (body in c('null', '42', '{}', '{"value":null}', '{"value":[{"wrong":"x"}]}',
                 '{"value":[{"Date":"2026-01-01T00:00:00"},{"Date":"2026-02-01T00:00:00"}]}')) {
    httr2::with_mocked_responses(who_page(body), {
      expect_warning(out <- gho_last_updated("X", backend = "legacy"), "Malformed")
      expect_identical(out$status, "failed")
      expect_identical(out$updated, NA_character_)
    })
  }
})

test_that("xMart empty or malformed date responses keep explicit statuses", {
  testthat::local_mocked_bindings(
    .xmart_gho_route = function(indicator) list(path = "DATA_/RELAY_WHS", id = "ID"),
    .xmart_fields = function(path) "Sys_CommitDateUtc", .package = "DSIR"
  )
  for (body in c('{"value":[]}', '{"value":[{"Sys_CommitDateUtc":null}]}')) {
    httr2::with_mocked_responses(who_page(body),
      out <- gho_last_updated("X", backend = "xmart"))
    expect_identical(out$status, "not_available")
  }
  httr2::with_mocked_responses(who_page('{"value":[{"Date":"2026-01-01T00:00:00"}]}'), {
    expect_warning(out <- gho_last_updated("X", backend = "xmart"), "Malformed")
    expect_identical(out$status, "failed")
  })
})

test_that("sequential update results bind consistently across missing values", {
  httr2::with_mocked_responses(list(
    who_response('{"value":[{"Date":"2026-01-01T00:00:00Z"}]}'),
    who_response('{"value":[]}')
  ), {
    rows <- lapply(c("A", "B"), gho_last_updated, backend = "legacy")
    out <- do.call(rbind, rows)
  })
  expect_equal(nrow(out), 2L)
  expect_identical(out$indicator, c("A", "B"))
  expect_identical(out$status, c("ok", "not_available"))
  expect_identical(out$updated, c("2026-01-01T00:00:00Z", NA_character_))
  expect_s3_class(out$checked_at, "POSIXct")
})
