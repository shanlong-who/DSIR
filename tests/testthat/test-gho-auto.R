# Use real routing, HTTP parsing and dispatch with small provider responses.
auto_catalog <- function(code = 'X', route = 'DATA_/RELAY_TEST') {
  tibble::tibble(IND_CODE_GHO = code, IND_ID = 'XM_ID', IND_PER_CODE = code,
    IND_NAME_FULL = 'xMart name', IND_UNIT = 'percent', DWNL_QUERY = route,
    IND_PUBLISH_TABLE = route, IND_NAME = 'xMart name', TERM_LANG = 'en')
}

auto_fixture <- function(env = parent.frame(), code = 'X') {
  withr::local_options(DSIR.who_backend = NULL, .local_envir = env)
  testthat::local_mocked_bindings(
    .xmart_catalog = function() auto_catalog(code),
    .xmart_fields = function(path) c('Sys_PK', 'IND_ID', 'DIM_TIME',
      'DIM_GEO_CODE_M49', 'DIM_GEO_CODE_TYPE', 'DIM_SEX', 'PERCENT_N', 'Sys_CommitDateUtc'),
    .xmart_geo_code = function(code, inverse = FALSE) {
      if (inverse) rep('PHL', length(code)) else rep('608', length(code))
    }, .package = 'DSIR', .env = env)
}

auto_response <- function(req, available = TRUE, empty_selection = FALSE) {
  url <- utils::URLdecode(req$url)
  if (startsWith(url, 'https://ghoapi.azureedge.net/')) {
    return(who_response(paste0('{"@odata.count":1,"value":[{"Id":1,',
      '"IndicatorCode":"X","IndicatorName":"Legacy name","Language":"EN",',
      '"SpatialDim":"PHL","SpatialDimType":"COUNTRY","TimeDim":2023,',
      '"NumericValue":50,"Date":"2026-01-01T00:00:00Z"}]}')))
  }
  if (grepl('$select=IND_ID&', url, fixed = TRUE)) {
    return(who_response(if (available) '{"@odata.count":1,"value":[{"IND_ID":"XM_ID"}]}'
      else '{"@odata.count":0,"value":[]}'))
  }
  who_response(if (empty_selection) '{"@odata.count":0,"value":[]}' else paste0(
    '{"@odata.count":1,"value":[{"Sys_PK":1,"IND_ID":"XM_ID",',
    '"DIM_TIME":"2023","DIM_GEO_CODE_M49":"608","DIM_GEO_CODE_TYPE":"COUNTRY",',
    '"DIM_SEX":"TOTAL","PERCENT_N":60,"Sys_CommitDateUtc":"2026-02-01T00:00:00Z"}]}'))
}

auto_queries <- function() list(
  data = function(...) gho_data('X', ...),
  count = function(...) gho_count('X', ...),
  has_data = function(...) gho_has_data('X', ...),
  coverage = function(...) gho_coverage('X', ...),
  dimensions = function(...) gho_dimensions('X', ...),
  last_updated = function(...) gho_last_updated('X', ...)
)

test_that('automatic indicator queries share xMart-first selection and provenance', {
  auto_fixture()
  urls <- character()
  httr2::with_mocked_responses(function(req) {
    urls <<- c(urls, utils::URLdecode(req$url))
    auto_response(req)
  }, {
    for (query in auto_queries()) {
      expect_no_warning(out <- query())
      origin <- attr(out, 'who_provenance')
      expect_equal(origin$backend, 'xmart')
      expect_equal(origin$requested_backend, 'auto')
      expect_null(origin$fallback_reason)
    }
  })
  expect_length(urls, 12L)
  expect_true(all(startsWith(urls, 'https://xmart-api-public.who.int/')))
  probes <- urls[grepl('$select=IND_ID&', urls, fixed = TRUE)]
  expect_length(probes, 6L)
  expect_true(all(grepl('$top=1', probes, fixed = TRUE)))
  expect_true(all(grepl("IND_ID eq 'XM_ID'", probes, fixed = TRUE)))
  expect_false(any(grepl('DIM_GEO|DIM_TIME|DIM_SEX', probes)))
  expect_null(getOption('DSIR.who_backend'))
})

test_that('only verified indicator absence permits automatic legacy fallback', {
  auto_fixture()
  for (reason in c('directory_not_listed', 'indicator_empty')) {
    testthat::local_mocked_bindings(.xmart_catalog = function() {
      auto_catalog(if (reason == 'directory_not_listed') 'OTHER' else 'X')
    }, .package = 'DSIR')
    urls <- character()
    httr2::with_mocked_responses(function(req) {
      urls <<- c(urls, req$url)
      auto_response(req, available = FALSE)
    }, {
      for (query in auto_queries()) {
        warnings <- character()
        out <- withCallingHandlers(query(), warning = function(w) {
          warnings <<- c(warnings, conditionMessage(w)); invokeRestart('muffleWarning')
        })
        expect_true(any(grepl('trying legacy', warnings, fixed = TRUE)))
        expect_equal(attr(out, 'who_provenance')$backend, 'legacy')
        expect_equal(attr(out, 'who_provenance')$fallback_reason, reason)
      }
    })
    expect_equal(sum(startsWith(urls, 'https://ghoapi.azureedge.net/')), 6L)
    expect_equal(sum(startsWith(urls, 'https://xmart-api-public.who.int/')),
                 if (reason == 'directory_not_listed') 0L else 6L)
  }
})

test_that('fallback preserves geography and years and cleaning retains actual origin', {
  auto_fixture(code = 'OTHER')
  urls <- character()
  httr2::with_mocked_responses(function(req) {
    urls <<- c(urls, utils::URLdecode(req$url)); auto_response(req)
  }, {
    out <- suppressWarnings(gho_data('X', area = c('PHL', 'JPN'), year_from = 2020,
                                    year_to = 2023))
    expect_identical(out$Provider, 'legacy')
    expect_true(attr(out, 'who_provenance')$complete)
    expect_match(attr(out, 'who_provenance')$query_url, 'ghoapi.azureedge.net', fixed = TRUE)
    clean <- gho_clean(out, keep_metadata = TRUE)
    expect_identical(clean$provider, 'legacy')
    expect_equal(attr(clean, 'who_provenance')$fallback_reason, 'directory_not_listed')
  })
  expect_length(urls, 1L)
  expect_match(urls, "SpatialDimType eq 'COUNTRY'", fixed = TRUE)
  expect_match(urls, "SpatialDim in ('PHL','JPN')", fixed = TRUE)
  expect_match(urls, 'TimeDim ge 2020 and TimeDim le 2023', fixed = TRUE)
})

test_that('filtered empty selections and partial coverage never switch providers', {
  auto_fixture()
  urls <- character()
  httr2::with_mocked_responses(function(req) {
    urls <<- c(urls, req$url); auto_response(req, empty_selection = TRUE)
  }, {
    expect_no_warning(out <- gho_data('X', area = 'PHL', year_from = 2099))
    expect_equal(nrow(out), 0L)
    count <- gho_count('X', area = 'PHL', year_from = 2099)
    exists <- gho_has_data('X', area = 'PHL', year_from = 2099)
    expect_identical(as.integer(count), 0L)
    expect_identical(as.logical(exists), FALSE)
  })
  httr2::with_mocked_responses(function(req) {
    urls <<- c(urls, req$url); auto_response(req)
  }, {
    out <- gho_data('X', area = c('PHL', 'JPN'), year_from = 2000, year_to = 2023)
    expect_equal(nrow(out), 1L)
    expect_equal(out$NumericValue, 60)
    expect_equal(out$Provider, 'xmart')
  })
  expect_false(any(startsWith(urls, 'https://ghoapi.azureedge.net/')))
})

test_that('directory failures and unsupported routes never qualify as absence', {
  auto_fixture()
  testthat::local_mocked_bindings(.dsi_request = function(...) stop('unexpected request'), .package = 'DSIR')
  for (catalog in list(NULL, auto_catalog()[0, ], auto_catalog(route = 'unsupported'))) {
    testthat::local_mocked_bindings(.xmart_catalog = function() catalog, .package = 'DSIR')
    for (query in auto_queries()) {
      out <- suppressWarnings(query())
      expect_equal(attr(out, 'who_provenance')$backend, 'xmart')
      expect_null(attr(out, 'who_provenance')$fallback_reason)
    }
  }
})

test_that('invalid availability evidence never permits fallback', {
  auto_fixture()
  bodies <- c('null', '{}', '{bad', '{"value":[],"@odata.count":-1}',
    '{"value":[],"@odata.count":"0"}', '{"value":[],"@odata.count":0.5}',
    '{"value":[],"@odata.count":1}',
    '{"value":[{"IND_ID":"XM_ID"}],"@odata.count":0}',
    '{"value":[{"IND_ID":"WRONG"}],"@odata.count":1}',
    '{"value":[{}],"@odata.count":1}',
    '{"value":[{"IND_ID":["XM_ID","OTHER"]}],"@odata.count":1}')
  for (body in bodies) {
    calls <- 0L
    httr2::with_mocked_responses(function(req) {
      calls <<- calls + 1L; who_response(body)
    }, {
      expect_warning(out <- gho_data('X'), 'WHO')
      expect_equal(nrow(out), 0L)
      expect_null(attr(out, 'who_provenance')$fallback_reason)
    })
    expect_equal(calls, 1L)
  }
})

test_that('unusable directory results warn without querying another provider', {
  auto_fixture()
  testthat::local_mocked_bindings(.dsi_request = function(...) stop('unexpected request'), .package = 'DSIR')
  testthat::local_mocked_bindings(.xmart_catalog = function() NULL, .package = 'DSIR')
  expect_warning(out <- gho_last_updated('X', diagnostics = TRUE), 'could not be verified')
  expect_equal(out$status, 'failed')
  expect_equal(out$stage, 'directory')
  for (id in list(NA_character_, '', character(), c('A', 'B'))) {
    testthat::local_mocked_bindings(.xmart_gho_route = function(indicator) {
      list(path = 'DATA_/RELAY_TEST', id = id)
    }, .package = 'DSIR')
    expect_warning(out <- gho_count('X'), 'Malformed WHO indicator identifier')
    expect_true(is.na(out))
    expect_equal(attr(out, 'who_provenance')$backend, 'xmart')
  }
})

test_that('transport and HTTP failures at either xMart stage do not fall back', {
  auto_fixture()
  for (stage in c('probe', 'download')) {
    for (failure in c('http', 'transport')) {
      urls <- character()
      httr2::with_mocked_responses(function(req) {
        urls <<- c(urls, req$url)
        probe <- grepl('$select=IND_ID&', utils::URLdecode(req$url), fixed = TRUE)
        if (stage == 'download' && probe) return(auto_response(req))
        if (failure == 'transport') stop('Connection failed')
        who_response('{}', status = 500L)
      }, {
        expect_warning(out <- gho_data('X'), 'WHO request failed')
        expect_equal(nrow(out), 0L)
        expect_null(attr(out, 'who_provenance')$fallback_reason)
      })
      expect_false(any(startsWith(urls, 'https://ghoapi.azureedge.net/')))
      expect_length(urls, if (stage == 'probe') 1L else 2L)
    }
  }
})

test_that('fallback never discards or guesses provider-specific filters', {
  auto_fixture(code = 'OTHER')
  testthat::local_mocked_bindings(.dsi_request = function(...) stop('unexpected request'), .package = 'DSIR')
  filters <- list(list(dimensions = list(DIM_SEX = 'TOTAL')), list(dim1 = 'SEX_BTSX'),
    list(dim2 = 'AGEGROUP_YEARS30-69'), list(dim3 = 'URB'), list(area = '608'))
  for (filter in filters) {
    out <- suppressWarnings(do.call(gho_data, c(list(indicator = 'X'), filter)))
    expect_equal(nrow(out), 0L)
    expect_equal(attr(out, 'who_provenance')$backend, 'xmart')
    expect_null(attr(out, 'who_provenance')$fallback_reason)
  }
  for (dimension in c('Dim1', 'Dim2', 'Dim3', 'DIM_SEX')) {
    out <- suppressWarnings(gho_dimensions('X', dimension))
    expect_length(out, 0L)
    expect_equal(attr(out, 'who_provenance')$backend, 'xmart')
  }
})

test_that('explicit backend selection overrides auto and performs no auto probe', {
  auto_fixture()
  withr::local_options(DSIR.who_backend = 'auto')
  urls <- character()
  httr2::with_mocked_responses(function(req) {
    urls <<- c(urls, utils::URLdecode(req$url)); auto_response(req)
  }, {
    expect_equal(gho_data('X', backend = 'legacy')$Provider, 'legacy')
    expect_equal(gho_data('X', backend = 'xmart')$Provider, 'xmart')
    withr::local_options(DSIR.who_backend = 'legacy')
    expect_equal(gho_data('X', backend = 'auto')$Provider, 'xmart')
    expect_equal(getOption('DSIR.who_backend'), 'legacy')
  })
  expect_equal(sum(grepl('$select=IND_ID&', urls, fixed = TRUE)), 1L)
})

test_that('automatic selection is retried after both failures and legacy fallback', {
  auto_fixture()
  attempt <- 0L
  httr2::with_mocked_responses(function(req) {
    if (grepl('$select=IND_ID&', utils::URLdecode(req$url), fixed = TRUE)) {
      attempt <<- attempt + 1L
      if (attempt == 1L) return(who_response('{}', status = 500L))
      return(auto_response(req, available = attempt != 2L))
    }
    auto_response(req)
  }, {
    expect_equal(nrow(suppressWarnings(gho_data('X'))), 0L)
    expect_equal(suppressWarnings(gho_data('X'))$Provider, 'legacy')
    expect_equal(gho_data('X')$Provider, 'xmart')
  })
  expect_equal(attempt, 3L)
})

test_that('failed legacy fallback remains failed and never starts a loop', {
  auto_fixture(code = 'OTHER')
  calls <- 0L
  httr2::with_mocked_responses(function(req) {
    calls <<- calls + 1L; who_response('{}', status = 500L)
  }, {
    out <- suppressWarnings(gho_count('X'))
    expect_true(is.na(out))
    expect_equal(attr(out, 'who_provenance')$backend, 'legacy')
    expect_equal(attr(out, 'who_provenance')$fallback_reason, 'directory_not_listed')
  })
  expect_equal(calls, 1L)
})

test_that('timestamp diagnostics follow actual provider and missing timestamps do not switch', {
  auto_fixture()
  first_request <- NULL
  httr2::with_mocked_responses(function(req) {
    if (is.null(first_request)) first_request <<- Sys.time()
    auto_response(req, available = FALSE)
  }, {
    out <- suppressWarnings(gho_last_updated('X', diagnostics = TRUE))
    expect_lte(out$checked_at, first_request)
    expect_equal(attr(out$checked_at, 'tzone'), 'UTC')
    expect_equal(out$backend, 'legacy')
    expect_equal(out$timestamp_kind, 'legacy_observation_date')
    expect_equal(out$reason, 'timestamp_available')
    expect_equal(out$provider_indicator, 'X')
    expect_equal(out$provider_route, 'api/X')
  })
  urls <- character()
  httr2::with_mocked_responses(function(req) {
    urls <<- c(urls, req$url)
    auto_response(req, empty_selection = TRUE)
  }, {
    out <- gho_last_updated('X')
    expect_equal(out$status, 'not_available')
    expect_equal(out$backend, 'xmart')
  })
  expect_false(any(startsWith(urls, 'https://ghoapi.azureedge.net/')))
})

test_that('auto validates arguments before querying and catalogs stay on xMart', {
  auto_fixture()
  testthat::local_mocked_bindings(.dsi_request = function(...) stop('unexpected request'), .package = 'DSIR')
  expect_error(gho_data('X', year_from = 2025, year_to = 2020), 'ordered')
  expect_error(gho_data('X', area = NA_character_), 'area')
  expect_error(gho_data('X', dimensions = list(DIM_SEX = NULL)), 'non-missing')
  expect_error(gho_data('X', dim1 = 1), 'dim1')
  expect_error(gho_dimensions('X', NA_character_), 'dimension')
  out <- gho_indicators()
  expect_equal(out$IndicatorName, 'xMart name')
  out <- gho_indicators('missing')
  expect_equal(nrow(out), 0L)
  expect_equal(attr(out, 'who_provenance')$backend, 'xmart')
})
