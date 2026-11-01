retrieval_response <- function(body, status = 200L) {
  httr2::response(status_code = status, headers = list('content-type' = 'application/json'),
    body = charToRaw(body))
}

expect_acquisition_preserved <- function(clean, raw) {
  fields <- c("schema_version", "source", "kind", "sources", "query", "result")
  expect_identical(dsir_metadata(clean)[fields], dsir_metadata(raw)[fields])
}

test_that("legacy observations and empty selections preserve metadata through cleaning", {
  bodies <- c('{"value":[{"IndicatorCode":"EXAMPLE","IndicatorName":"Example",',
              '"SpatialDim":"PHL","SpatialDimType":"COUNTRY","TimeDim":2020,"TimeDimType":"YEAR","NumericValue":10}]}')
  httr2::with_mocked_responses(list(retrieval_response(paste0(bodies, collapse = ""))), {
    raw <- gho_data("EXAMPLE", area = "PHL", backend = "legacy")
    metadata <- dsir_metadata(raw)
    expect_identical(class(raw), c("tbl_df", "tbl", "data.frame"))
    expect_identical(metadata$source, "gho")
    expect_identical(metadata$kind, "observations")
    expect_identical(metadata$sources$backend, "legacy")
    expect_identical(metadata$sources$endpoint, "https://ghoapi.azureedge.net/api/EXAMPLE")
    expect_match(metadata$sources$retrieved_at, "T.*Z$")
    expect_identical(metadata$query$area, "PHL")
    expect_identical(metadata$query$actual_backend, "legacy")
    expect_identical(metadata$result$status, "success")
    clean <- gho_clean(raw, keep_dimensions = TRUE, keep_metadata = TRUE)
    expect_acquisition_preserved(clean, raw)
    expect_identical(dsir_metadata(clean)$provenance$retrieval, attr(raw, "who_provenance"))
    expect_identical(dsir_metadata(as_dsir_data(clean))$sources, metadata$sources)
    expect_identical(data_snapshot(as_dsir_data(clean))$data, data_snapshot(clean)$data)
  })
  httr2::with_mocked_responses(list(retrieval_response('{"value":[]}')), {
    raw <- gho_data("EXAMPLE", backend = "legacy")
    expect_identical(dsir_metadata(raw)$result$status, "empty")
    expect_true(dsir_metadata(raw)$result$complete)
    expect_acquisition_preserved(gho_clean(raw), raw)
  })
  httr2::with_mocked_responses(list(retrieval_response('{}', 404L)), {
    raw <- suppressWarnings(gho_data("EXAMPLE", backend = "legacy"))
    expect_identical(dsir_metadata(raw)$result$status, "failed")
    expect_false(dsir_metadata(raw)$result$complete)
    expect_true(is.na(dsir_metadata(raw)$sources$retrieved_at))
    expect_identical(dsir_metadata(gho_clean(raw))$result$status, "failed")
  })
})

test_that("catalog searches retain acquisition counts and historical fallback dates", {
  body <- '{"value":[{"IndicatorCode":"X","IndicatorName":"Example","Language":"EN"}]}'
  httr2::with_mocked_responses(list(retrieval_response(body)), {
    out <- gho_indicators(backend = "legacy")
    expect_named(out, c("IndicatorCode", "IndicatorName", "Language"))
    expect_identical(dsir_metadata(out)$sources$retrieval_status, "live")
    expect_equal(dsir_metadata(out)$sources$record_count, 1)
  })
  httr2::with_mocked_responses(list(retrieval_response('{"value":[]}')), {
    out <- gho_indicators("no match", backend = "legacy")
    expect_identical(dsir_metadata(out)$result$status, "empty")
    expect_true(dsir_metadata(out)$result$complete)
  })
  httr2::with_mocked_responses(list(retrieval_response('{}', 404L)), {
    out <- suppressWarnings(gho_indicators("mortality", backend = "legacy"))
    metadata <- dsir_metadata(out)
    expect_identical(metadata$sources$retrieval_status, "bundled_snapshot")
    expect_identical(metadata$sources$retrieved_at,
      .dsi_timestamp_utc(attr(out, "catalog_snapshot")$retrieved))
    expect_gt(metadata$sources$record_count, nrow(out))
    expect_identical(metadata$query$search, "mortality")
    expect_false(metadata$sources$cache_hit)
  })
})

test_that("xMart catalog caching retains retrieval time and complete directory scope", {
  withr::local_options(DSIR.who_base_url = "https://catalog-metadata.test")
  body <- paste0('{"@odata.count":2,"value":[',
    '{"IND_ID":1,"IND_PER_CODE":"A","IND_CODE_GHO":"X","IND_NAME_FULL":"Example",',
    '"IND_NAME":"Example","TERM_LANG":"en","IND_UNIT":"years",',
    '"IND_PUBLISH_TABLE":"DATA_/TEST","DWNL_QUERY":"x"},',
    '{"IND_ID":2,"IND_PER_CODE":"A","IND_CODE_GHO":"Y","IND_NAME_FULL":"Another",',
    '"IND_NAME":"Another","TERM_LANG":"en","IND_UNIT":"years",',
    '"IND_PUBLISH_TABLE":"DATA_/TEST","DWNL_QUERY":"y"}]}')
  calls <- 0L
  httr2::with_mocked_responses(function(req) {
    calls <<- calls + 1L
    retrieval_response(body)
  }, {
    first <- gho_indicators("Example", backend = "xmart")
    second <- gho_indicators("zzzz", backend = "xmart")
  })
  expect_equal(calls, 1L)
  expect_identical(dsir_metadata(first)$sources$retrieved_at, dsir_metadata(second)$sources$retrieved_at)
  expect_false(dsir_metadata(first)$sources$cache_hit)
  expect_true(dsir_metadata(second)$sources$cache_hit)
  expect_equal(dsir_metadata(first)$sources$record_count, 2)
  expect_equal(dsir_metadata(first)$result$rows, 1L)
  expect_identical(dsir_metadata(second)$result$status, "empty")
  expect_identical(dsir_metadata(second)$sources$status, "success")
})

test_that("SDG records full pagination before local filtering and survives S3 conversion", {
  page <- function(i) retrieval_response(paste0(
    '{"data":[{"indicator":["3.4.1"],"series":"S","geoAreaCode":"608",',
    '"timePeriodStart":', 2019 + i, ',"value":"10","release":"R1"}],',
    '"pageNumber":', i, ',"totalPages":2,"totalElements":2}'))
  httr2::with_mocked_responses(list(page(1), page(2)), {
    raw <- sdg_data("3.4.1", area = "PHL", year_from = 2021, series = "S")
  })
  metadata <- dsir_metadata(raw)
  expect_identical(metadata$source, "sdg")
  expect_identical(metadata$sources$backend, "unsdg")
  expect_identical(metadata$sources$api_version, "V5")
  expect_identical(metadata$sources$source_release, "R1")
  expect_equal(metadata$sources$record_count, 2)
  expect_equal(metadata$result$rows, 1L)
  expect_true(metadata$result$complete)
  expect_identical(metadata$query$area, "PHL")
  expect_identical(metadata$query$area_codes, "608")
  expect_equal(metadata$query$year_from, 2021)
  expect_equal(metadata$sources$query[[1]]$pages_received, 2L)
  expect_identical(class(raw), c("tbl_df", "tbl", "data.frame"))
  clean <- sdg_clean(raw, keep_dimensions = TRUE, keep_metadata = TRUE)
  expect_acquisition_preserved(clean, raw)
  object <- as_dsir_data(clean)
  expect_identical(dsir_metadata(object)$sources, metadata$sources)
  expect_identical(summary(object)$sources, metadata$sources)
  expect_output(print(object), "unsdg")
  expect_null(attr(raw, "who_provenance", exact = TRUE))
})

test_that("SDG distinguishes empty failed incomplete and unapplied-filter results", {
  httr2::with_mocked_responses(list(retrieval_response('{"data":[],"totalPages":0,"totalElements":0}')), {
    raw <- suppressWarnings(sdg_data("3.4.1"))
    expect_identical(dsir_metadata(raw)$result$status, "empty")
    expect_true(dsir_metadata(raw)$result$complete)
    expect_acquisition_preserved(sdg_clean(raw), raw)
  })
  first <- retrieval_response('{"data":[{"value":"10"}],"totalPages":2,"totalElements":2}')
  for (response in list(retrieval_response('{}', 404L),
                        retrieval_response('{"data":[],"totalPages":2,"totalElements":2}'))) {
    httr2::with_mocked_responses(list(first, response), {
      raw <- suppressWarnings(sdg_data("3.4.1"))
      expect_true(dsir_metadata(raw)$result$status %in% c("failed", "incomplete"))
      expect_false(dsir_metadata(raw)$result$complete)
      expect_true(is.na(dsir_metadata(raw)$sources$retrieved_at))
      expect_identical(dsir_metadata(sdg_clean(raw))$result, dsir_metadata(raw)$result)
    })
  }
  httr2::with_mocked_responses(list(retrieval_response('{"data":[{"value":"1"}],"totalPages":1}')), {
    raw <- suppressWarnings(sdg_data("3.4.1", year_from = 2020))
    expect_equal(nrow(raw), 1L)
    expect_identical(dsir_metadata(raw)$result$status, "invalid")
    expect_false(dsir_metadata(raw)$result$complete)
  })
  httr2::with_mocked_responses(list(retrieval_response('{"data":[{"value":"1"}]}')), {
    expect_true(is.na(dsir_metadata(sdg_data("3.4.1"))$result$complete))
  })
})

test_that("SDG directories keep nested release labels and their existing failure shapes", {
  body <- paste0('[{"code":"3.4.1","description":"Mortality","series":[',
    '{"code":"S","release":"R1","indicator":["3.4.1","3.4.2"]}]}]')
  httr2::with_mocked_responses(list(retrieval_response(body)), {
    out <- sdg_indicators("zzzz")
    expect_identical(dsir_metadata(out)$result$status, "empty")
    expect_identical(dsir_metadata(out)$sources$source_release, "R1")
    expect_equal(dsir_metadata(out)$sources$record_count, 1)
    expect_identical(dsir_metadata(out)$query$search, "zzzz")
  })
  for (fn in list(sdg_goals, sdg_targets, sdg_areas)) {
    httr2::with_mocked_responses(list(retrieval_response('[{"code":"3"}]')), {
      expect_identical(dsir_metadata(fn())$source, "sdg")
    })
    httr2::with_mocked_responses(list(retrieval_response('{}', 404L)), {
      expect_null(suppressWarnings(fn()))
    })
  }
})

test_that("GHE metadata distinguishes provider rows from long measures and records cause scope", {
  fields <- c('Sys_PK', 'DIM_COUNTRY_CODE', 'DIM_YEAR_CODE', 'DIM_SEX_CODE',
    'DIM_AGEGROUP_CODE', 'DIM_GHECAUSE_CODE', 'DIM_GHECAUSE_TITLE',
    'ATTR_POPULATION_NUMERIC', 'FLAG_LEVEL', 'DIM_CAUSE_GROUP', 'FLAG_RANKABLE',
    'VAL_DTHS_COUNT_NUMERIC', 'VAL_DTHS_RATE100K_NUMERIC')
  testthat::local_mocked_bindings(.xmart_fields = function(path) fields,
    .ghe_filter = function(...) "DIM_COUNTRY_CODE eq 'PHL' and DIM_YEAR_CODE eq 2023",
    .ghe_latest = function() 2023L, .ghe_reference_area = function() 'AFG', .package = 'DSIR')
  withr::local_options(DSIR.who_base_url = 'https://ghe-metadata.test')
  body <- paste0('{"@odata.count":1,"value":[{"Sys_PK":1,',
    '"DIM_COUNTRY_CODE":"PHL","DIM_YEAR_CODE":2023,"DIM_SEX_CODE":"TOTAL",',
    '"DIM_AGEGROUP_CODE":"TOTAL","DIM_GHECAUSE_CODE":0,"DIM_GHECAUSE_TITLE":"All",',
    '"ATTR_POPULATION_NUMERIC":100000,"FLAG_LEVEL":0,"DIM_CAUSE_GROUP":"0",',
    '"FLAG_RANKABLE":0,"FLAG_SINGLE_CAUSE":false,',
    '"VAL_DTHS_COUNT_NUMERIC":100,"VAL_DTHS_RATE100K_NUMERIC":100}]}')
  httr2::with_mocked_responses(list(retrieval_response(body)), {
    raw <- ghe_data('PHL', year = 2023, measure = c('deaths', 'death_rate'))
    metadata <- dsir_metadata(raw)
    expect_equal(metadata$sources$record_count, 1)
    expect_equal(metadata$result$rows, 2L)
    expect_true(metadata$result$complete)
    expect_acquisition_preserved(ghe_clean(raw), raw)
    expect_identical(dsir_metadata(ghe_clean(raw))$provenance$retrieval, attr(raw, 'who_provenance'))
  })
  httr2::with_mocked_responses(list(retrieval_response(body)), {
    causes <- ghe_causes('zzzz')
    metadata <- dsir_metadata(causes)
    expect_identical(metadata$result$status, 'empty')
    expect_identical(metadata$query$area, 'AFG')
    expect_identical(metadata$query$year, 2023L)
    expect_identical(metadata$query$age, 'TOTAL')
    expect_equal(metadata$sources$record_count, 1)
  })
  httr2::with_mocked_responses(list(retrieval_response('{"@odata.count":0,"value":[]}')), {
    raw <- ghe_data('PHL', year = 2023)
    expect_identical(dsir_metadata(raw)$result$status, 'empty')
    expect_acquisition_preserved(ghe_clean(raw), raw)
    expect_identical(dsir_metadata(ghe_clean(raw))$provenance$retrieval, attr(raw, 'who_provenance'))
  })
})

test_that("GHE measure schemas keep actual retrieval time when served from cache", {
  withr::local_options(DSIR.who_base_url = 'https://ghe-schema-metadata.test')
  calls <- 0L
  httr2::with_mocked_responses(function(req) {
    calls <<- calls + 1L
    retrieval_response('{"value":[{"VAL_DTHS_COUNT_NUMERIC":1}]}')
  }, {
    first <- ghe_dimensions('measure')
    second <- ghe_dimensions('measure')
  })
  expect_equal(calls, 1L)
  expect_identical(first$code, 'deaths')
  expect_false(dsir_metadata(first)$sources$cache_hit)
  expect_true(dsir_metadata(second)$sources$cache_hit)
  expect_identical(dsir_metadata(first)$sources$retrieved_at, dsir_metadata(second)$sources$retrieved_at)
  expect_match(dsir_metadata(first)$query$definitions, 'DSIR adapter')
})

test_that("plain user tables acquire no invented retrieval record when cleaned", {
  raw <- tibble::tibble(geoAreaCode = '608', timePeriodStart = 2020, value = '1')
  metadata <- dsir_metadata(sdg_clean(raw))
  expect_null(metadata$sources)
  expect_length(metadata$provenance$retrieval, 0L)
  expect_match(metadata$cleaning$cleaned_at, 'T.*Z$')
})

test_that("xMart observations record valid emptiness separately from failed requests", {
  context <- list(path = 'DATA_/RELAY_WHS', code = 'X', name = 'Example', unit = 'percent',
    filter = "IND_ID eq 'X'", dimensions = 'DIM_SEX')
  testthat::local_mocked_bindings(.xmart_gho_context = function(...) context,
    .xmart_geo_code = function(code, inverse = FALSE) rep('PHL', length(code)), .package = 'DSIR')
  body <- paste0('{"@odata.count":1,"value":[{"Sys_PK":1,"IND_ID":"X",',
    '"DIM_TIME":"2020","DIM_GEO_CODE_M49":"608","DIM_SEX":"TOTAL","PERCENT_N":10}]}')
  httr2::with_mocked_responses(list(retrieval_response(body)), {
    raw <- gho_data('X', backend = 'xmart')
    metadata <- dsir_metadata(raw)
    expect_identical(metadata$result$status, 'success')
    expect_identical(metadata$sources$query[[1]]$filter, context$filter)
    expect_equal(metadata$sources$record_count, 1)
    expect_acquisition_preserved(gho_clean(raw), raw)
  })
  httr2::with_mocked_responses(list(retrieval_response('{"@odata.count":0,"value":[]}')), {
    raw <- gho_data('X', backend = 'xmart')
    expect_identical(dsir_metadata(raw)$result$status, 'empty')
    expect_true(dsir_metadata(raw)$result$complete)
    expect_acquisition_preserved(gho_clean(raw), raw)
  })
  httr2::with_mocked_responses(list(retrieval_response('{}', 404L)), {
    raw <- suppressWarnings(gho_data('X', backend = 'xmart'))
    expect_identical(dsir_metadata(raw)$result$status, 'failed')
    expect_true(is.na(dsir_metadata(raw)$sources$retrieved_at))
    expect_identical(dsir_metadata(raw)$sources$endpoint,
      'https://xmart-api-public.who.int/DATA_/RELAY_WHS')
  })
})

test_that("cached GHE years retain reference origin and empty references stay typed", {
  withr::local_options(DSIR.who_base_url = 'https://ghe-years-metadata.test')
  httr2::with_mocked_responses(list(retrieval_response('{"value":[{"CODE":"2023","TITLE":"2023"}]}')), {
    first <- ghe_dimensions('year')
    second <- ghe_dimensions('year')
    expect_identical(first$code, '2023')
    expect_match(dsir_metadata(first)$sources$endpoint, 'REF_YEAR_COD$')
    expect_identical(dsir_metadata(first)$sources$retrieved_at, dsir_metadata(second)$sources$retrieved_at)
    expect_true(dsir_metadata(second)$sources$cache_hit)
  })
  withr::local_options(DSIR.who_base_url = 'https://ghe-years-empty.test')
  httr2::with_mocked_responses(list(retrieval_response('{"value":[]}')), {
    out <- ghe_dimensions('year')
    expect_type(out$code, 'character')
    expect_identical(dsir_metadata(out)$result$status, 'empty')
  })
})

test_that("SDG metadata alone never certifies an unexpected JSON object", {
  httr2::with_mocked_responses(list(retrieval_response('{"error":"unavailable"}')), {
    out <- sdg_indicators()
    expect_identical(dsir_metadata(out)$result$status, 'unverified')
    expect_true(is.na(dsir_metadata(out)$result$complete))
  })
})
