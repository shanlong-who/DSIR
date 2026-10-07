test_that('GHO backend arguments override session options without changing them', {
  withr::local_options(DSIR.who_backend = NULL)
  urls <- character()
  mock <- function(req) {
    urls <<- c(urls, req$url)
    who_response('{"value":[{"IndicatorCode":"X","IndicatorName":"Legacy","Language":"EN"}]}')
  }
  testthat::local_mocked_bindings(
    .xmart_catalog = function() tibble::tibble(IND_CODE_GHO = 'X',
      IND_NAME_FULL = 'xMart', IND_NAME = 'xMart', TERM_LANG = 'en'),
    .package = 'DSIR'
  )
  httr2::with_mocked_responses(mock, {
    expect_equal(gho_indicators()$IndicatorName, 'Legacy')
    expect_null(getOption('DSIR.who_backend'))
    expect_equal(gho_indicators(backend = 'xmart')$IndicatorName, 'xMart')
    expect_null(getOption('DSIR.who_backend'))
    withr::local_options(DSIR.who_backend = 'xmart')
    expect_equal(gho_indicators()$IndicatorName, 'xMart')
    expect_equal(gho_indicators(backend = 'legacy')$IndicatorName, 'Legacy')
    expect_equal(getOption('DSIR.who_backend'), 'xmart')
    withr::local_options(DSIR.who_backend = 'invalid')
    expect_error(gho_indicators(), 'DSIR.who_backend')
    expect_equal(gho_indicators(backend = 'legacy')$IndicatorName, 'Legacy')
    expect_equal(getOption('DSIR.who_backend'), 'invalid')
  })
  expect_length(urls, 3L)
  expect_true(all(startsWith(urls, 'https://ghoapi.azureedge.net/api/Indicator')))
})

test_that('all GHO queries select the requested provider with consistent filters', {
  withr::local_options(DSIR.who_backend = 'legacy')
  context <- list(path = 'DATA_/RELAY_WHS', code = 'X', id = 'X',
    name = 'Test', unit = 'percent', filter = "IND_ID eq 'X'",
    dimensions = 'DIM_SEX', fields = c('IND_ID', 'DIM_TIME',
      'DIM_GEO_CODE_M49', 'DIM_GEO_CODE_TYPE', 'DIM_SEX', 'PERCENT_N'))
  testthat::local_mocked_bindings(
    .xmart_gho_context = function(...) context,
    .xmart_geo_code = function(code, inverse = FALSE) rep('PHL', length(code)),
    .package = 'DSIR'
  )
  urls <- character()
  mock <- function(req) {
    urls <<- c(urls, req$url)
    who_response(paste0('{"@odata.count":1,"value":[{"Sys_PK":1,',
      '"IND_ID":"X","DIM_TIME":"2023","DIM_GEO_CODE_M49":"608",',
      '"DIM_GEO_CODE_TYPE":"COUNTRY","DIM_SEX":"TOTAL","PERCENT_N":10}]}'))
  }
  httr2::with_mocked_responses(mock, {
    out <- gho_data('X', backend = 'xmart')
    expect_equal(out$NumericValue, 10)
    expect_equal(out$Provider, 'xmart')
    expect_equal(attr(out, 'who_provenance')$backend, 'xmart')
    expect_true(gho_has_data('X', backend = 'xmart'))
    expect_identical(gho_count('X', backend = 'xmart'), 1L)
    expect_equal(gho_coverage('X', backend = 'xmart')$year_min, 2023L)
    expect_equal(gho_dimensions('X', 'DIM_SEX', backend = 'xmart'), 'TOTAL')
  })
  expect_length(urls, 5L)
  expect_true(all(startsWith(urls, 'https://xmart-api-public.who.int/')))
  expect_true(all(grepl("IND_ID eq 'X'", utils::URLdecode(urls), fixed = TRUE)))
  expect_equal(getOption('DSIR.who_backend'), 'legacy')

  urls <- character()
  mock <- function(req) {
    urls <<- c(urls, req$url)
    who_response(paste0('{"@odata.count":1,"value":[{"Id":1,"IndicatorCode":"X",',
      '"SpatialDim":"PHL","TimeDim":2023,"NumericValue":10,"Dim1":"SEX_BTSX"}]}'))
  }
  withr::local_options(DSIR.who_backend = 'xmart')
  httr2::with_mocked_responses(mock, {
    out <- gho_data('X', dim1 = 'SEX_BTSX', backend = 'legacy')
    expect_equal(out$Provider, 'legacy')
    expect_equal(attr(out, 'who_provenance')$backend, 'legacy')
    expect_true(attr(out, 'who_provenance')$complete)
    expect_true(gho_has_data('X', dim1 = 'SEX_BTSX', backend = 'legacy'))
    expect_identical(gho_count('X', dim1 = 'SEX_BTSX', backend = 'legacy'), 1L)
    expect_equal(unname(gho_coverage('X', dim1 = 'SEX_BTSX', backend = 'legacy')$year_min), 2023L)
    expect_equal(gho_dimensions('X', 'Dim1', backend = 'legacy'), 'SEX_BTSX')
  })
  expect_length(urls, 5L)
  expect_true(all(startsWith(urls, 'https://ghoapi.azureedge.net/api/X')))
  expect_true(all(grepl("Dim1 in ('SEX_BTSX')", utils::URLdecode(urls[1:4]), fixed = TRUE)))
  expect_equal(getOption('DSIR.who_backend'), 'xmart')
})

test_that('invalid backend arguments fail before any request and preserve options', {
  withr::local_options(DSIR.who_backend = 'legacy')
  testthat::local_mocked_bindings(.dsi_request = function(...) stop('network called'), .package = 'DSIR')
  queries <- list(
    list(fun = gho_indicators, args = list()),
    list(fun = gho_data, args = list('X')),
    list(fun = gho_has_data, args = list('X')),
    list(fun = gho_count, args = list('X')),
    list(fun = gho_coverage, args = list('X')),
    list(fun = gho_dimensions, args = list('X'))
  )
  for (query in queries) {
    for (backend in list('auto', 'XMart', '', NA_character_, character(), c('legacy', 'xmart'), 1L)) {
      expect_error(do.call(query$fun, c(query$args, list(backend = backend))), 'backend')
    }
  }
  expect_error(gho_data('X', dimensions = list(DIM_SEX = 'TOTAL')), 'xMart backend')
  expect_equal(getOption('DSIR.who_backend'), 'legacy')
})

test_that('cleaning resolves labels with recorded providers after options change', {
  withr::local_options(DSIR.who_backend = 'xmart')
  saved_catalog <- .dsi_cache$gho_indicator_catalog
  saved_key <- .dsi_cache$gho_catalog_key
  withr::defer({
    .dsi_cache$gho_indicator_catalog <- saved_catalog
    .dsi_cache$gho_catalog_key <- saved_key
  })
  .dsi_cache$gho_indicator_catalog <- NULL
  testthat::local_mocked_bindings(
    .legacy_gho_indicators = function(search = NULL) tibble::tibble(
      IndicatorCode = 'X', IndicatorName = 'Legacy label', Language = 'EN'),
    .xmart_gho_indicators = function(search = NULL) tibble::tibble(
      IndicatorCode = 'X', IndicatorName = 'xMart label', Language = 'EN'),
    .package = 'DSIR'
  )
  raw <- tibble::tibble(IndicatorCode = c('X', 'X'), SpatialDim = 'PHL',
    TimeDim = c(2023L, 2020L), NumericValue = c(11, 10), Provider = c('legacy', 'xmart'))
  attr(raw, 'who_provenance') <- list(backend = 'legacy')
  core <- gho_clean(raw)
  detailed <- gho_clean(raw, keep_metadata = TRUE)
  expect_equal(ncol(core), 15L)
  expect_identical(detailed[names(core)], core)
  expect_equal(detailed$indicator, c('xMart label', 'Legacy label'))
  expect_equal(detailed$provider, c('xmart', 'legacy'))
  expect_equal(detailed$value_num, c(10, 11))
  expect_equal(getOption('DSIR.who_backend'), 'xmart')
  withr::local_options(DSIR.who_backend = 'invalid')
  expect_equal(gho_clean(raw)$indicator, core$indicator)

  # Recorded attribute provenance is also supported for older saved pulls.
  legacy <- raw[1, setdiff(names(raw), 'Provider')]
  attr(legacy, 'who_provenance') <- list(backend = 'legacy')
  expect_equal(gho_clean(legacy, keep_metadata = TRUE)$provider, 'legacy')
  expect_equal(gho_clean(legacy)$indicator, 'Legacy label')
})

test_that('provider columns survive binding and unknown input is not relabelled', {
  withr::local_options(DSIR.who_backend = 'xmart')
  raw <- tibble::tibble(IndicatorCode = 'X', IndicatorName = 'Test',
    SpatialDim = 'PHL', TimeDim = 2023L, NumericValue = 1)
  unknown <- gho_clean(raw, keep_metadata = TRUE)
  expect_identical(unknown$provider, NA_character_)
  raw$Provider <- 'legacy'
  legacy <- gho_clean(raw, keep_metadata = TRUE)
  raw$Provider <- 'xmart'
  xmart <- gho_clean(raw, keep_metadata = TRUE)
  sdg <- sdg_clean(tibble::tibble(geoAreaCode = '608', timePeriodStart = 2023L))
  combined <- bind_indicators(legacy, xmart, unknown, sdg)
  expect_equal(combined$provider, c('legacy', 'xmart', NA_character_, NA_character_))
  expect_equal(combined$source, c('gho', 'gho', 'gho', 'sdg'))
  expect_type(gho_clean(tibble::tibble(), keep_metadata = TRUE)$provider, 'character')
  raw <- raw[0, ]
  attr(raw, 'who_provenance') <- list(backend = 'xmart', complete = TRUE, rows = 0L)
  expect_identical(attr(gho_clean(raw), 'who_provenance'), attr(raw, 'who_provenance'))
})

test_that('valid empty GHO selections are informational and retain scalar contracts', {
  context <- list(path = 'DATA_/RELAY_WHS', code = 'X', filter = '')
  testthat::local_mocked_bindings(.xmart_gho_context = function(...) context, .package = 'DSIR')
  for (backend in c('legacy', 'xmart')) {
    httr2::with_mocked_responses(function(req) who_response('{"@odata.count":0,"value":[]}'), {
      expect_message(out <- gho_data('X', backend = backend), 'No GHO observations match')
      expect_equal(nrow(out), 0L)
      expect_message(exists <- gho_has_data('X', backend = backend), 'No GHO observations match')
      expect_identical(exists, FALSE)
      expect_message(count <- gho_count('X', backend = backend), 'No GHO observations match')
      expect_identical(count, 0L)
      expect_message(coverage <- gho_coverage('X', backend = backend), 'No GHO observations match')
      expect_equal(nrow(coverage), 0L)
    })
  }
})

test_that('legacy 404 classification requires a successful directory check', {
  for (query in list(gho_data, gho_has_data, gho_count, gho_dimensions, gho_coverage)) {
    urls <- character()
    mock <- function(req) {
      urls <<- c(urls, utils::URLdecode(req$url))
      if (grepl('/api/Indicator?', req$url, fixed = TRUE)) return(who_response('{"value":[]}'))
      who_response('{}', 404L)
    }
    httr2::with_mocked_responses(mock, {
      expect_warning(out <- query('MISSING', backend = 'legacy'), 'absent from the legacy directory')
    })
    expect_length(urls, 2L)
    expect_match(urls[2], "IndicatorCode eq 'MISSING'", fixed = TRUE)
    if (identical(query, gho_has_data)) expect_identical(out, NA)
    if (identical(query, gho_count)) expect_identical(out, NA_integer_)
  }

  for (body in c('{"value":[{"IndicatorCode":"X"}]}', '{"value":null}')) {
    mock <- function(req) {
      if (grepl('/api/Indicator?', req$url, fixed = TRUE)) return(who_response(body))
      who_response('{}', 404L)
    }
    warnings <- character()
    httr2::with_mocked_responses(mock, withCallingHandlers(
      gho_data('X', backend = 'legacy'), warning = function(w) {
        warnings <<- c(warnings, conditionMessage(w)); invokeRestart('muffleWarning')
      }
    ))
    expect_true(any(grepl('GHO request failed', warnings, fixed = TRUE)))
    expect_false(any(grepl('absent from the legacy directory', warnings, fixed = TRUE)))
  }
})

test_that('malformed legacy responses are failures rather than empty selections', {
  for (body in c('42', '{"error":"unavailable"}', '{"value":null}', '{"value":[1,2]}')) {
    httr2::with_mocked_responses(who_page(body), {
      expect_warning(out <- gho_data('X', backend = 'legacy'), 'Malformed GHO response')
      expect_equal(nrow(out), 0L)
    })
  }
  for (body in c('{}', '{"@odata.count":-1}', '{"@odata.count":"0"}', '{"@odata.count":1.5}')) {
    httr2::with_mocked_responses(who_page(body), {
      expect_warning(count <- gho_count('X', backend = 'legacy'), 'valid integer row count')
      expect_identical(count, NA_integer_)
    })
  }
})

test_that('GHO request failures never fall back or report a valid empty selection', {
  testthat::local_mocked_bindings(
    .legacy_gho_data = function(...) stop('legacy fallback called'),
    .xmart_gho_context = function(...) list(path = 'DATA_/RELAY_WHS', filter = ''),
    .package = 'DSIR'
  )
  messages <- character()
  httr2::with_mocked_responses(list(who_response('{}', 404L)), withCallingHandlers({
    expect_warning(out <- gho_data('X', backend = 'xmart'), 'WHO request failed')
    expect_equal(nrow(out), 0L)
  }, message = function(m) { messages <<- c(messages, conditionMessage(m)) }))
  expect_false(any(grepl('No GHO observations match', messages, fixed = TRUE)))
})

test_that('GHE uses xMart while GHO is configured for legacy', {
  withr::local_options(DSIR.who_backend = 'legacy')
  testthat::local_mocked_bindings(
    .ghe_filter = function(...) "DIM_COUNTRY_CODE eq 'PHL' and DIM_YEAR_CODE eq 2023",
    ghe_dimensions = function(dimension = 'measure') {
      definitions <- .ghe_measures()
      definitions[definitions$code == 'deaths', ]
    },
    .xmart_fields = function(path) c('Sys_PK', 'DIM_COUNTRY_CODE', 'DIM_YEAR_CODE',
      'DIM_SEX_CODE', 'DIM_AGEGROUP_CODE', 'DIM_GHECAUSE_CODE', 'DIM_GHECAUSE_TITLE',
      'ATTR_POPULATION_NUMERIC', 'FLAG_LEVEL', 'DIM_CAUSE_GROUP', 'FLAG_RANKABLE',
      'VAL_DTHS_COUNT_NUMERIC'),
    .package = 'DSIR'
  )
  url <- NULL
  httr2::with_mocked_responses(function(req) {
    url <<- req$url
    who_response(paste0('{"@odata.count":1,"value":[{"Sys_PK":1,"DIM_COUNTRY_CODE":"PHL",',
      '"DIM_YEAR_CODE":2023,"DIM_SEX_CODE":"TOTAL","DIM_AGEGROUP_CODE":"TOTAL",',
      '"DIM_GHECAUSE_CODE":0,"DIM_GHECAUSE_TITLE":"All causes",',
      '"ATTR_POPULATION_NUMERIC":100000,"FLAG_LEVEL":0,"DIM_CAUSE_GROUP":1,',
      '"FLAG_RANKABLE":0,"VAL_DTHS_COUNT_NUMERIC":100}]}'))
  }, out <- ghe_data('PHL', year = 2023, measure = 'deaths'))
  expect_match(url, 'https://xmart-api-public.who.int/DEX_CMS/GHE_FULL', fixed = TRUE)
  expect_equal(attr(out, 'who_provenance')$backend, 'xmart')
  expect_equal(getOption('DSIR.who_backend'), 'legacy')
})
