skip_if_not_installed("sf")

map_test_boundaries <- function(keys = c("LAO", "VNM")) {
  geometry <- lapply(seq_along(keys), function(i) sf::st_polygon(list(matrix(
    c(i, 0, i + 1, 0, i + 1, 1, i, 1, i, 0), ncol = 2, byrow = TRUE))))
  sf::st_sf(iso3 = keys, geometry = sf::st_sfc(geometry, crs = 4326))
}

map_test_clean <- function() {
  gho_clean(tibble::tibble(IndicatorCode = "EXAMPLE", IndicatorName = "Illustrative indicator",
    SpatialDim = c("LAO", "VNM"), TimeDim = 2023L, NumericValue = c(10, 20),
    Unit = "percent", Dim1 = "SEX_BTSX", Dim1Type = "SEX"))
}

map_test_response <- function(body, status = 200L) {
  httr2::response(status_code = status, headers = list("content-type" = "application/json"), body = charToRaw(body))
}

map_test_item <- function() map_test_response(paste0(
  '{"id":"39663258d2b44dcaa28af952ed40760b","access":"public",',
  '"modified":1704067200000,"licenseInfo":"Use without modification."}'))

map_test_ids <- function() map_test_response('{"objectIdFieldName":"OBJECTID","objectIds":[1]}')

map_test_feature <- function(code = "LAO", geometry = '{"type":"Polygon","coordinates":[[[0,0],[1,0],[1,1],[0,1],[0,0]]]}', id = 1) {
  paste0('{"type":"FeatureCollection","features":[{"type":"Feature","properties":',
    '{"OBJECTID":', id, ',"ISO_3_CODE":"', code, '"},"geometry":', geometry, '}]}')
}

map_test_streaming <- function(env = parent.frame()) {
  # httr2 mocks bypass the disk writer used by real req_perform(path = ...).
  perform <- httr2::req_perform
  testthat::local_mocked_bindings(req_perform = function(req, path = NULL, ...) {
    response <- perform(req, ...)
    if (!is.null(path)) writeBin(httr2::resp_body_raw(response), path)
    response
  }, .package = "httr2", .env = env)
}

map_test_with_responses <- function(responses, code) {
  index <- 0L
  mock <- function(req) {
    index <<- index + 1L
    response <- if (is.function(responses)) responses(req) else {
      if (index <= length(responses)) responses[[index]] else NULL
    }
    if (is.null(response)) stop("Unexpected request: offline map fixtures exhausted.")
    response
  }
  httr2::with_mocked_responses(mock, code)
}

test_that("ordinary tables use exact boundary joins and return standard ggplots", {
  values <- data.frame(id = c(2, 1), code = c("B", "A"), rate = c(20, 10), unit = "percent")
  boundaries <- map_test_boundaries(c("A", "B", NA_character_))
  p <- dsir_map(values, value = "rate", country = "code", boundaries = boundaries, boundary_key = "iso3")
  expect_s3_class(p, "ggplot")
  expect_s3_class(p$data, "sf")
  expect_identical(p$data$code, values$code)
  expect_equal(p$data$rate, values$rate)
  expect_identical(sf::st_geometry(p$data), sf::st_geometry(boundaries[c(2, 1), ]))
  expect_no_warning(ggplot2::ggplot_build(p + ggplot2::labs(title = "Custom map")))
  metadata <- dsir_metadata(p)
  expect_identical(metadata$layout, "map")
  expect_identical(metadata$boundaries$origin, "user_supplied")
  expect_null(metadata$boundaries$sources)
  expect_identical(metadata$selection$keys, values$code)
  expect_identical(metadata$selection$value_column, "rate")
  expect_match(metadata$created_at, "T.*Z$")
  expect_identical(dsir_metadata(p + ggplot2::labs(title = "Custom map")), metadata)
})

test_that("sf tables supply their own polygons without a download", {
  data <- map_test_boundaries()
  data$value_num <- c(10, NA_real_)
  data$year <- 2023L
  testthat::local_mocked_bindings(.dsi_request = function(...) stop("Unexpected network"), .package = "DSIR")
  p <- dsir_map(data, download = "never")
  expect_s3_class(p, "ggplot")
  expect_no_warning(ggplot2::ggplot_build(p))
  expect_equal(dsir_metadata(p)$selection$missing_values, 1L)
  expect_match(p$labels$caption, "Grey: missing")
  expect_identical(sf::st_geometry(p$data), sf::st_geometry(data))
  expect_error(dsir_map(data, boundaries = data), "Supply geometry")
})

test_that("DSIR maps retain source semantics and block stale or unresolved fields", {
  x <- map_test_clean()
  boundaries <- map_test_boundaries()
  p <- dsir_map(x, boundaries = boundaries)
  expect_equal(p$scales$get_scales("fill")$name, "percent")
  expect_identical(dsir_metadata(p)$data$cleaning, dsir_metadata(x)$cleaning)
  expect_equal(dsir_metadata(p)$selection$year, 2023L)
  expect_match(p$labels$subtitle, "SEX_BTSX")
  x$value_num <- x$value_num / 100
  expect_s3_class(x, "dsir_data")
  expect_error(dsir_map(x, boundaries = boundaries), "needs review")
  x <- map_test_clean()
  x$rate <- x$value_num / 100
  expect_error(dsir_map(x, value = "rate", boundaries = boundaries), "derived measures")
  raw <- tibble::tibble(indicator = "EXAMPLE", series = "S", geoAreaCode = c("418", "704"),
    timePeriodStart = 2023L, value = c("10", "20"), dimensions = data.frame(Sex = c("FEMALE", "MALE")))
  expect_error(dsir_map(sdg_clean(raw), boundaries = boundaries), "omitted")
  expect_error(dsir_map(sdg_clean(raw, keep_dimensions = TRUE), boundaries = boundaries), "Unresolved")
})

test_that("map selection checks year units keys and numeric values before downloading", {
  testthat::local_mocked_bindings(.dsi_request = function(...) stop("Unexpected network"), .package = "DSIR")
  data <- data.frame(iso3 = c("LAO", "VNM"), value_num = c(10, 20), year = c(2022L, 2023L), unit = "percent")
  boundaries <- map_test_boundaries()
  expect_error(dsir_map(data), "one common")
  p <- dsir_map(data, year = 2023, boundaries = boundaries)
  expect_identical(p$data$iso3, "VNM")
  expect_error(dsir_map(data, year = 1900), "No observations")
  expect_error(dsir_map(data, year = c(2022, 2023)), "single")
  data$year <- 2023L
  data$unit <- c("percent", "number")
  expect_error(dsir_map(data), "unit")
  data$unit <- "percent"
  data$iso3 <- "LAO"
  expect_error(dsir_map(data), "Duplicate analysis")
  data$iso3 <- c("LAO", NA)
  expect_error(dsir_map(data), "keys")
  data$iso3 <- c("LAO", "VNM")
  data$value_num <- c(10, Inf)
  expect_error(dsir_map(data), "Infinite")
  data$value_num <- c("10", "20")
  expect_error(dsir_map(data), "numeric")
  expect_error(dsir_map(data[FALSE, ]), "No observations")
})

test_that("incomplete or invalid supplied boundaries fail without repair", {
  data <- data.frame(iso3 = c("LAO", "VNM"), value_num = c(10, 20))
  boundaries <- map_test_boundaries()
  expect_error(dsir_map(data, boundaries = boundaries[1, ]), "missing.*VNM")
  expect_error(dsir_map(data, boundaries = rbind(boundaries, boundaries[1, ])), "Duplicate boundary")
  empty <- boundaries
  sf::st_geometry(empty)[[2]] <- sf::st_polygon()
  expect_error(dsir_map(data, boundaries = empty), "Empty.*VNM")
  invalid <- boundaries
  sf::st_geometry(invalid)[[2]] <- sf::st_polygon(list(matrix(
    c(0, 0, 1, 1, 0, 1, 1, 0, 0, 0), ncol = 2, byrow = TRUE)))
  expect_error(dsir_map(data, boundaries = invalid), "Invalid.*VNM")
  unknown <- sf::st_set_crs(boundaries, NA)
  expect_error(dsir_map(data, boundaries = unknown), "coordinate reference")
  points <- sf::st_sf(iso3 = data$iso3, geometry = sf::st_sfc(sf::st_point(c(0, 0)), sf::st_point(c(1, 1)), crs = 4326))
  expect_error(dsir_map(data, boundaries = points), "polygons")
})

test_that("no requests occur without explicit permission in noninteractive sessions", {
  testthat::local_mocked_bindings(.dsi_map_interactive = function() FALSE,
    .dsi_request = function(...) stop("Unexpected network"), .package = "DSIR")
  data <- data.frame(iso3 = "LAO", value_num = 10)
  cache <- tempfile("map-cache-")
  expect_error(dsir_map(data, cache_dir = cache), "not permitted")
  expect_error(dsir_map(data, cache_dir = cache, download = "never"), "not permitted")
  expect_false(dir.exists(cache))
  expect_error(dsir_map(data, cache_dir = NA), "directory path")
  data$iso3 <- "LAO' OR 1=1"
  expect_error(dsir_map(data, download = "allow", cache_dir = cache), "ISO3")
})

test_that("per-country downloads are validated then reused offline with original dates", {
  map_test_streaming()
  cache <- tempfile("map-cache-")
  data <- data.frame(iso3 = "LAO", value_num = 10)
  requested <- character()
  responses <- list(map_test_item(), map_test_ids(), map_test_response(map_test_feature()))
  map_test_with_responses(function(req) {
    requested <<- c(requested, utils::URLdecode(req$url))
    responses[[length(requested)]]
  }, p <- dsir_map(data, download = "allow", cache_dir = cache))
  expect_length(requested, 3L)
  expect_match(requested[[2]], "returnIdsOnly=true", fixed = TRUE)
  expect_match(requested[[3]], "ISO_3_CODE = 'LAO'", fixed = TRUE)
  expect_match(requested[[3]], "objectIds=1", fixed = TRUE)
  expect_false(grepl("token=", requested[[3]], fixed = TRUE))
  first <- dsir_metadata(p)$boundaries$sources
  expect_false(first$cache_hit)
  expect_match(first$retrieved_at, "T.*Z$")
  expect_identical(first$item_modified_at, "2024-01-01T00:00:00Z")
  expect_match(first$download_md5, "^[a-f0-9]{32}$")
  testthat::local_mocked_bindings(.dsi_request = function(...) stop("Unexpected network"), .package = "DSIR")
  cached <- dsir_map(data, download = "never", cache_dir = cache)
  second <- dsir_metadata(cached)$boundaries$sources
  expect_true(second$cache_hit)
  expect_identical(first$retrieved_at, second$retrieved_at)
  expect_identical(sf::st_geometry(p$data), sf::st_geometry(cached$data))
  expect_no_warning(ggplot2::ggplot_build(cached))
})

test_that("interactive approval is requested once and refusal never starts a request", {
  map_test_streaming()
  calls <- 0L
  testthat::local_mocked_bindings(.dsi_map_interactive = function() TRUE,
    .dsi_map_confirm = function(message) { calls <<- calls + 1L; FALSE }, .package = "DSIR")
  data <- data.frame(iso3 = "LAO", value_num = 10)
  cache <- tempfile("map-cache-")
  expect_error(dsir_map(data, cache_dir = cache), "not permitted")
  expect_equal(calls, 1L)
  testthat::local_mocked_bindings(.dsi_map_confirm = function(message) { calls <<- calls + 1L; TRUE }, .package = "DSIR")
  map_test_with_responses(list(map_test_item(), map_test_ids(), map_test_response(map_test_feature())), {
    dsir_map(data, cache_dir = cache)
    dsir_map(data, cache_dir = cache)
  })
  expect_equal(calls, 2L)
})

test_that("the Philippine empty-geometry regression cannot create a successful cache", {
  map_test_streaming()
  cache <- tempfile("map-cache-")
  map_test_with_responses(list(map_test_item(), map_test_ids(), map_test_response(map_test_feature("PHL", "null"))), {
    expect_error(dsir_map(data.frame(iso3 = "PHL", value_num = 10), download = "allow", cache_dir = cache), "[Ee]mpty.*PHL")
  })
  expect_length(list.files(cache, recursive = TRUE), 0L)
})

test_that("failed refreshes keep valid caches and corrupted caches cannot be used silently", {
  map_test_streaming()
  cache <- tempfile("map-cache-")
  data <- data.frame(iso3 = "LAO", value_num = 10)
  map_test_with_responses(list(map_test_item(), map_test_ids(), map_test_response(map_test_feature())),
    dsir_map(data, download = "allow", cache_dir = cache))
  file <- list.files(cache, full.names = TRUE, recursive = TRUE)
  original <- tools::md5sum(file)
  map_test_with_responses(list(map_test_item(), map_test_ids(), map_test_response(map_test_feature(geometry = "null"))), {
    expect_error(dsir_map(data, download = "allow", cache_dir = cache, refresh = TRUE), "[Ee]mpty.*LAO")
  })
  expect_identical(tools::md5sum(file), original)
  expect_true(dsir_metadata(dsir_map(data, download = "never", cache_dir = cache))$boundaries$sources$cache_hit)
  saveRDS(list(bad = TRUE), file)
  expect_warning(expect_error(dsir_map(data, download = "never", cache_dir = cache), "not permitted"), "invalid WHO boundary cache")
})

test_that("ArcGIS failures and changed IDs cannot certify a complete download", {
  map_test_streaming()
  cache <- tempfile("map-cache-")
  data <- data.frame(iso3 = "LAO", value_num = 10)
  map_test_with_responses(list(map_test_response('{"error":{"code":403,"message":"denied {request}"}}')), {
    expect_warning(expect_error(dsir_map(data, download = "allow", cache_dir = cache), "metadata"), "denied \\{request\\}")
  })
  map_test_with_responses(list(map_test_item(), map_test_response('{"objectIdFieldName":"OBJECTID","objectIds":[1,2]}')), {
    expect_error(dsir_map(data, download = "allow", cache_dir = cache), "exactly one")
  })
  map_test_with_responses(list(map_test_item(), map_test_ids(), map_test_response(map_test_feature(id = 2))), {
    expect_error(dsir_map(data, download = "allow", cache_dir = cache), "identifiers changed")
  })
  expect_length(list.files(cache, recursive = TRUE), 0L)
})

test_that("successful refresh replaces a cache only after checking the new geometry", {
  map_test_streaming()
  cache <- tempfile("map-cache-")
  data <- data.frame(iso3 = "LAO", value_num = 10)
  map_test_with_responses(list(map_test_item(), map_test_ids(), map_test_response(map_test_feature())),
    first <- dsir_map(data, download = "allow", cache_dir = cache))
  revised <- '{"type":"Polygon","coordinates":[[[0,0],[2,0],[2,1],[0,1],[0,0]]]}'
  map_test_with_responses(list(map_test_item(), map_test_ids(), map_test_response(map_test_feature(geometry = revised))),
    second <- dsir_map(data, download = "allow", cache_dir = cache, refresh = TRUE))
  expect_false(identical(dsir_metadata(first)$boundaries$sources$download_md5,
    dsir_metadata(second)$boundaries$sources$download_md5))
  expect_false(dsir_metadata(second)$boundaries$sources$cache_hit)
  testthat::local_mocked_bindings(.dsi_request = function(...) stop("Unexpected network"), .package = "DSIR")
  cached <- dsir_map(data, download = "never", cache_dir = cache)
  expect_identical(sf::st_geometry(cached$data), sf::st_geometry(second$data))
  expect_true(dsir_metadata(cached)$boundaries$sources$cache_hit)
})
