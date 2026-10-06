ghe_mock_fields <- c('Sys_PK', 'DIM_COUNTRY_CODE', 'DIM_YEAR_CODE', 'DIM_SEX_CODE',
                    'DIM_AGEGROUP_CODE', 'DIM_GHECAUSE_CODE', 'DIM_GHECAUSE_TITLE',
                    'ATTR_POPULATION_NUMERIC', 'FLAG_LEVEL', 'DIM_CAUSE_GROUP', 'FLAG_RANKABLE',
                    'VAL_DTHS_COUNT_NUMERIC', 'VAL_DTHS_COUNT_LOW', 'VAL_DTHS_COUNT_HIGH',
                    'VAL_DTHS_RATE100K_NUMERIC')
ghe_mock_body <- paste0('{"@odata.count":1,"value":[{"Sys_PK":1,',
  '"DIM_COUNTRY_CODE":"PHL","DIM_YEAR_CODE":2023,"DIM_SEX_CODE":"TOTAL",',
  '"DIM_AGEGROUP_CODE":"TOTAL","DIM_GHECAUSE_CODE":0,"DIM_GHECAUSE_TITLE":"All Causes",',
  '"ATTR_POPULATION_NUMERIC":100000,"FLAG_LEVEL":0,"DIM_CAUSE_GROUP":1,"FLAG_RANKABLE":0,',
  '"VAL_DTHS_COUNT_NUMERIC":100,"VAL_DTHS_COUNT_LOW":80,"VAL_DTHS_COUNT_HIGH":120,',
  '"VAL_DTHS_RATE100K_NUMERIC":100}]}')
ghe_mock_codes <- function(dimension = 'measure') {
  if (dimension == 'measure') {
    x <- .ghe_measures(); return(x[x$code %in% c('deaths', 'death_rate'), ])
  }
  code <- switch(dimension, area = 'PHL', year = '2023', sex = c('TOTAL', 'FEMALE', 'MALE'), age = c('TOTAL', 'Y40T44'))
  tibble::tibble(code = code, label = code)
}

test_that('GHE filters and measures produce interpretable long observations', {
  testthat::local_mocked_bindings(ghe_dimensions = ghe_mock_codes,
    ghe_causes = function(search = NULL) tibble::tibble(cause_code = '0'),
    .xmart_fields = function(path) ghe_mock_fields, .package = 'DSIR')
  url <- NULL
  httr2::with_mocked_responses(function(req) {
    url <<- utils::URLdecode(req$url); who_response(ghe_mock_body)
  }, out <- ghe_data('PHL', year = 2023, sex = 'TOTAL', age = 'TOTAL', cause = 0))
  expect_equal(nrow(out), 2L)
  expect_setequal(out$measure, c('deaths', 'death_rate'))
  expect_match(url, "DIM_COUNTRY_CODE eq 'PHL'", fixed = TRUE)
  expect_match(url, 'DIM_YEAR_CODE eq 2023', fixed = TRUE)
  expect_match(url, 'VAL_DTHS_COUNT_HIGH', fixed = TRUE)
  expect_equal(out$low[out$measure == 'deaths'], 80)
  expect_equal(out$high[out$measure == 'deaths'], 120)
  expect_true(is.na(out$low[out$measure == 'death_rate']))
  expect_equal(out$value[out$measure == 'death_rate'], out$value[out$measure == 'deaths'] / out$population[1] * 1e5)
  expect_equal(ncol(ghe_clean(out)), 15L)
  clean <- ghe_clean(out, keep_dimensions = TRUE)
  expect_equal(clean$dim_age, rep('TOTAL', 2))
  expect_setequal(clean$series, c('deaths', 'death_rate'))
  expect_equal(nrow(bind_indicators(clean, .dsi_empty_clean())), 2L)
})

test_that('GHE rejects unknown codes and conflicting ranges without removing filters', {
  testthat::local_mocked_bindings(ghe_dimensions = ghe_mock_codes,
    ghe_causes = function(search = NULL) tibble::tibble(cause_code = '0'), .package = 'DSIR')
  expect_error(ghe_data(), 'selection')
  expect_error(ghe_data('PHL', measure = 'DTHSS'), 'Unknown GHE measure')
  expect_error(ghe_data('PHL', year = 2023, year_from = 2020), 'either')
  expect_error(ghe_data('PHL', year_from = 2023, year_to = 2020), 'ordered')
  expect_error(ghe_data('PHL', year = 2023.5), 'integer')
  for (selection in list(list(area = 'PH'), list(area = 'phl'), list(area = 'PHL', sex = 'BOTH'),
                        list(area = 'PHL', cause = 'diabetes'), list(area = 'PHL', age = 'all'))) {
    expect_warning(out <- do.call(ghe_data, selection), 'Unknown GHE')
    expect_equal(nrow(out), 0L)
    expect_named(out, names(.ghe_empty()))
  }
})

test_that('GHE coverage counts source observations and respects all selected filters', {
  testthat::local_mocked_bindings(ghe_dimensions = ghe_mock_codes,
    ghe_causes = function(search = NULL) tibble::tibble(cause_code = '0'), .package = 'DSIR')
  captured <- NULL
  httr2::with_mocked_responses(function(req) {
    captured <<- utils::URLdecode(req$url)
    who_response('{"@odata.count":2,"value":[{"Sys_PK":1,"DIM_COUNTRY_CODE":"PHL","DIM_YEAR_CODE":2022},{"Sys_PK":2,"DIM_COUNTRY_CODE":"PHL","DIM_YEAR_CODE":2023}]}')
  }, out <- ghe_coverage('PHL', year_from = 2022, year_to = 2023, sex = 'TOTAL', age = 'TOTAL', cause = 0))
  expect_equal(out$year_min, 2022L)
  expect_equal(out$year_max, 2023L)
  expect_equal(out$n_years, 2L)
  expect_equal(out$n_obs, 2L)
  expect_match(captured, "DIM_SEX_CODE eq 'TOTAL'", fixed = TRUE)
  expect_match(captured, "DIM_AGEGROUP_CODE eq 'TOTAL'", fixed = TRUE)
  expect_match(captured, 'DIM_GHECAUSE_CODE eq 0', fixed = TRUE)
  expect_match(captured, 'DIM_YEAR_CODE ge 2022', fixed = TRUE)
})

test_that('GHE empty cleaning preserves core types and named context', {
  out <- ghe_clean(.ghe_empty(), TRUE)
  expect_type(out$year, 'integer')
  expect_type(out$value_num, 'double')
  expect_type(out$iso3, 'character')
  expect_equal(nrow(out), 0L)
  expect_true(all(c('dim_sex', 'dim_age', 'unit') %in% names(out)))
  expect_error(ghe_clean(data.frame(x = 1)), 'ghe_data')
})

test_that('GHE live smoke uses explicit opt-in and checks structure only', {
  skip_on_cran()
  skip_if(Sys.getenv('DSIR_RUN_LIVE_TESTS') != 'true', 'Set DSIR_RUN_LIVE_TESTS=true to run live WHO smoke checks')
  skip_if_offline()
  out <- ghe_data('PHL', year = 2023, age = 'TOTAL', sex = 'TOTAL', cause = 0, measure = 'deaths')
  expect_gt(nrow(out), 0L)
  expect_true(all(out$year == 2023 & out$iso3 == 'PHL'))
  expect_true(all(out$value >= 0))
  expect_true(attr(out, 'who_provenance')$complete)
})
