test_that("diagnostics are opt-in and preserve the default GHO result", {
  withr::local_options(DSIR.who_backend = "xmart")
  calls <- character()
  httr2::with_mocked_responses(function(req) {
    calls <<- c(calls, req$url)
    who_response('{"value":[{"Date":"2026-05-18T12:07:03.23+02:00"}]}')
  }, {
    plain <- gho_last_updated("MCV2", backend = "legacy")
    detailed <- gho_last_updated("MCV2", backend = "legacy", diagnostics = TRUE)
  })
  base_columns <- c("source", "backend", "scope", "indicator", "updated",
                    "timestamp_field", "checked_at", "status")
  expect_named(plain, base_columns)
  expect_identical(detailed[setdiff(base_columns, "checked_at")],
                   plain[setdiff(base_columns, "checked_at")])
  expect_named(detailed, c(base_columns, "reason", "stage", "http_status",
                           "timestamp_kind", "provider_route", "provider_indicator"))
  expect_identical(detailed$reason, "timestamp_available")
  expect_identical(detailed$stage, "timestamp")
  expect_identical(detailed$http_status, 200L)
  expect_identical(detailed$timestamp_kind, "legacy_observation_date")
  expect_identical(detailed$provider_route, "api/MCV2")
  expect_identical(detailed$provider_indicator, "MCV2")
  expect_identical(calls[1L], calls[2L])
  expect_length(calls, 2L)
  expect_identical(getOption("DSIR.who_backend"), "xmart")
})

test_that("invalid diagnostics arguments fail before network calls", {
  testthat::local_mocked_bindings(
    .dsi_request = function(...) stop("network called"), .package = "DSIR")
  for (value in list(NULL, logical(), NA, c(TRUE, FALSE), 1L, "TRUE")) {
    expect_error(gho_last_updated("X", diagnostics = value), "diagnostics")
  }
})

test_that("a directory omission is not an HTTP failure or an invalid GHO code", {
  testthat::local_mocked_bindings(
    .xmart_catalog = function() tibble::tibble(IND_CODE_GHO = "MCV2"),
    .dsi_request = function(...) stop("network called"), .package = "DSIR")
  expect_warning(out <- gho_last_updated("TB_1", backend = "xmart", diagnostics = TRUE),
                 "does not establish that the GHO code is invalid")
  expect_identical(out$reason, "directory_not_listed")
  expect_identical(out$stage, "directory")
  expect_identical(out$status, "failed")
  expect_identical(out$http_status, NA_integer_)
  expect_identical(out$provider_indicator, NA_character_)
  expect_identical(out$provider_route, NA_character_)
})

test_that("directory HTTP failures are not reported as absent codes", {
  withr::local_options(DSIR.who_base_url = "https://diagnostic-directory.who.int")
  calls <- character()
  httr2::with_mocked_responses(function(req) {
    calls <<- c(calls, req$url)
    who_response('{}', status = 500L)
  }, expect_warning(out <- gho_last_updated("TB_1", backend = "xmart",
                                            diagnostics = TRUE), "request failed"))
  expect_identical(out$reason, "http_error")
  expect_identical(out$http_status, 500L)
  expect_identical(out$stage, "directory")
  expect_length(calls, 1L)
  expect_match(calls, "/DATA_/IND_DIRECTORY_WIDE?", fixed = TRUE)
})

test_that("both backends capture observation HTTP errors without fallback", {
  testthat::local_mocked_bindings(
    .xmart_gho_route = function(indicator) list(path = "DATA_/RELAY_WHS", id = "EXACT_ID"),
    .xmart_fields = function(path) "Sys_CommitDateUtc", .package = "DSIR")
  for (backend in c("legacy", "xmart")) {
    calls <- character()
    httr2::with_mocked_responses(function(req) {
      calls <<- c(calls, req$url)
      who_response('<html>Server Error {500}</html>', status = 500L)
    }, expect_warning(out <- gho_last_updated("MCV2", backend = backend,
                                              diagnostics = TRUE), "request failed"))
    expect_identical(out$reason, "http_error")
    expect_identical(out$stage, "timestamp")
    expect_identical(out$http_status, 500L)
    expect_identical(out$backend, backend)
    expect_identical(out$updated, NA_character_)
    expect_length(calls, 1L)
  }
})

test_that("transport failures remain distinct from HTTP error responses", {
  for (backend in c("legacy", "xmart")) {
    testthat::local_mocked_bindings(
      .xmart_gho_route = function(indicator) list(path = "DATA_/RELAY_WHS", id = "ID"),
      .xmart_fields = function(path) "Sys_CommitDateUtc", .package = "DSIR")
    httr2::with_mocked_responses(function(req) stop("Connection failed {external}"), {
      expect_warning(out <- gho_last_updated("X", backend = backend, diagnostics = TRUE),
                     "request failed")
    })
    expect_identical(out$reason, "request_failed")
    expect_identical(out$http_status, NA_integer_)
  }
})

test_that("schema failures and missing timestamp fields are distinguished", {
  testthat::local_mocked_bindings(
    .xmart_gho_route = function(indicator) list(path = "DATA_/RELAY_TEST", id = "ID"),
    .package = "DSIR")
  withr::local_options(DSIR.who_base_url = "https://diagnostic-schema.who.int")
  httr2::with_mocked_responses(list(who_response('{}', status = 503L)), {
    expect_warning(failed <- gho_last_updated("X", backend = "xmart", diagnostics = TRUE),
                   "request failed")
  })
  expect_identical(failed$reason, "http_error")
  expect_identical(failed$stage, "schema")
  expect_identical(failed$http_status, 503L)
  httr2::with_mocked_responses(who_page('{"value":[{"IND_ID":"ID"}]}'),
    missing <- gho_last_updated("X", backend = "xmart", diagnostics = TRUE))
  expect_identical(missing$reason, "timestamp_field_missing")
  expect_identical(missing$status, "not_available")
  expect_identical(missing$http_status, 200L)
  expect_identical(missing$stage, "schema")
  expect_identical(missing$provider_route, "DATA_/RELAY_TEST")
  httr2::with_mocked_responses(function(req) stop("cached schema should avoid requests"),
    cached <- gho_last_updated("X", backend = "xmart", diagnostics = TRUE))
  expect_identical(cached$reason, "timestamp_field_missing")
  expect_identical(cached$http_status, NA_integer_)
})

test_that("an earlier successful lookup cannot mask a later failed lookup", {
  testthat::local_mocked_bindings(
    .xmart_gho_route = function(indicator) {
      .dsi_update_note(http_status = 200L)
      list(path = "DATA_/RELAY_WHS", id = "ID")
    },
    .xmart_fields = function(path) character(), .package = "DSIR")
  out <- gho_last_updated("X", backend = "xmart", diagnostics = TRUE)
  expect_identical(out$reason, "lookup_failed")
  expect_identical(out$stage, "schema")
  expect_identical(out$http_status, NA_integer_)
})

test_that("diagnostics preserve exact xMart identities and timestamp offsets", {
  withr::local_options(DSIR.who_backend = "xmart")
  testthat::local_mocked_bindings(
    .xmart_gho_route = function(indicator) list(path = "DATA_/RELAY_WHS", id = "BB4567BMCV2"),
    .xmart_fields = function(path) "Sys_CommitDateUtc", .package = "DSIR")
  httr2::with_mocked_responses(who_page(
    '{"value":[{"Sys_CommitDateUtc":"2026-05-18T12:07:03.23+02:00"}]}'),
    out <- gho_last_updated("MCV2", diagnostics = TRUE))
  expect_identical(out$reason, "timestamp_available")
  expect_identical(out$timestamp_kind, "xmart_system_commit")
  expect_identical(out$provider_indicator, "BB4567BMCV2")
  expect_identical(out$updated, "2026-05-18T12:07:03.23+02:00")
  expect_identical(out$http_status, 200L)
})

test_that("missing timestamps and invalid responses have distinct reasons", {
  cases <- list(
    list(body = '{"value":[]}', reason = "timestamp_missing", status = "not_available"),
    list(body = '{"value":[{"Date":null}]}', reason = "timestamp_missing", status = "not_available"),
    list(body = '{"value":[{"IND_ID":"X"}]}', reason = "timestamp_field_missing", status = "failed"),
    list(body = '{}', reason = "invalid_response", status = "failed"),
    list(body = '{"value":[{"Date":"2026"}]}', reason = "invalid_timestamp", status = "failed"),
    list(body = '{"broken":{', reason = "invalid_json", status = "failed")
  )
  for (case in cases) {
    httr2::with_mocked_responses(who_page(case$body), {
      out <- suppressWarnings(gho_last_updated("X", backend = "legacy", diagnostics = TRUE))
    })
    expect_identical(out$reason, case$reason)
    expect_identical(out$status, case$status)
    expect_identical(out$http_status, 200L)
  }
})

test_that("HTML responses are not mistaken for missing timestamps", {
  testthat::local_mocked_bindings(
    .xmart_gho_route = function(indicator) list(path = "DATA_/RELAY_WHS", id = "ID"),
    .xmart_fields = function(path) "Sys_CommitDateUtc", .package = "DSIR")
  response <- httr2::response(status_code = 200L,
    headers = list("content-type" = "text/html"), body = charToRaw("<html>Unavailable</html>"))
  httr2::with_mocked_responses(list(response), {
    expect_warning(out <- gho_last_updated("X", backend = "xmart", diagnostics = TRUE),
                   "HTML page instead of JSON")
  })
  expect_identical(out$reason, "unexpected_content")
  expect_identical(out$http_status, 200L)
  expect_identical(out$status, "failed")
})

test_that("legacy directory probes cannot overwrite the original HTTP error", {
  for (listed in c(FALSE, TRUE)) {
    httr2::with_mocked_responses(list(
      who_response('{}', status = 404L),
      who_response(if (listed) '{"value":[{"IndicatorCode":"X"}]}' else '{"value":[]}')
    ), out <- suppressWarnings(gho_last_updated("X", backend = "legacy", diagnostics = TRUE)))
    expect_identical(out$reason, if (listed) "http_error" else "directory_not_listed")
    expect_identical(out$stage, if (listed) "timestamp" else "directory")
    expect_identical(out$http_status, if (listed) 404L else 200L)
    expect_identical(out$status, "failed")
  }
})

test_that("unsupported routes and empty directories are not directory omissions", {
  testthat::local_mocked_bindings(
    .xmart_catalog = function() tibble::tibble(IND_CODE_GHO = character()),
    .dsi_request = function(...) stop("network called"), .package = "DSIR")
  expect_warning(empty <- gho_last_updated("X", backend = "xmart", diagnostics = TRUE), "directory is empty")
  expect_identical(empty$reason, "lookup_failed")
  testthat::local_mocked_bindings(
    .xmart_catalog = function() tibble::tibble(
      IND_CODE_GHO = "X", IND_PER_CODE = "X", DWNL_QUERY = NA_character_,
      IND_PUBLISH_TABLE = "DATA_/UNSUPPORTED"), .package = "DSIR")
  expect_warning(route <- gho_last_updated("X", backend = "xmart", diagnostics = TRUE), "no supported download route")
  expect_identical(route$reason, "unsupported_route")
})

test_that("mixed diagnostic outcomes can be bound and do not leak between calls", {
  httr2::with_mocked_responses(list(
    who_response('{}', status = 500L),
    who_response('{"value":[{"Date":"2026-01-01T00:00:00Z"}]}'),
    who_response('{"value":[]}')
  ), {
    rows <- lapply(c("A", "B", "C"), function(code) {
      suppressWarnings(gho_last_updated(code, backend = "legacy", diagnostics = TRUE))
    })
    out <- do.call(rbind, rows)
  })
  expect_identical(out$reason, c("http_error", "timestamp_available", "timestamp_missing"))
  expect_identical(out$http_status, c(500L, 200L, 200L))
  expect_identical(out$provider_indicator, c("A", "B", "C"))
  expect_s3_class(out$checked_at, "POSIXct")
})
