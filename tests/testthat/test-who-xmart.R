test_that('xMart is the default provider and configuration is validated', {
  withr::local_options(DSIR.who_backend = NULL, DSIR.who_base_url = NULL)
  expect_equal(.who_config()$backend, 'xmart')
  expect_equal(.who_config()$base, 'https://xmart-api-public.who.int')
  withr::local_options(DSIR.who_backend = 'other')
  expect_error(.who_config(), 'backend')
})

test_that('WHO list filters use compact production-supported syntax', {
  expect_equal(.who_in('DIM_COUNTRY_CODE', c('PHL', 'FRA')),
               "(DIM_COUNTRY_CODE in ('PHL','FRA'))")
  expect_equal(.who_in('IND_ID', "O'Brien"), "(IND_ID eq 'O''Brien')")
  expect_equal(.who_in('DIM_YEAR_CODE', c(2022L, 2023L), TRUE),
               '(DIM_YEAR_CODE in (2022,2023))')
})

test_that('WHO region aliases distinguish WHO groups from similarly named UN groups', {
  geo <- tibble::tibble(GEO_CODE_M49 = c('608', '001', '002', '953', '958'),
    GEO_CODE_ISO_3 = c('PHL', NA, NA, NA, NA),
    GEO_NAME_SHORT = c('Philippines', 'World', 'Africa', 'Africa', 'Western Pacific'),
    GEO_TYPE = c('ADMIN_0', 'GROUP', 'GROUP', 'GROUP', 'GROUP'))
  testthat::local_mocked_bindings(.xmart_geo = function() geo, .package = 'DSIR')
  expect_equal(.xmart_geo_code(c('PHL', 'AFR', 'WPR', 'GLOBAL')), c('608', '953', '958', '001'))
  expect_equal(.xmart_geo_code(c('608', '953', '958', '001', '002'), TRUE), c('PHL', 'AFR', 'WPR', 'GLOBAL', '002'))
  expect_equal(.xmart_spatial_type(c('WHOREGION', 'COUNTRY', 'GLOBAL')), c('REGION', 'COUNTRY', 'GLOBAL'))
})

test_that('WHO pagination uses stable offsets and verifies complete row counts', {
  withr::local_options(DSIR.who_page_size = 2L)
  urls <- character()
  bodies <- c('{"@odata.count":3,"value":[{"Sys_PK":1,"x":10},{"Sys_PK":2,"x":20}]}',
              '{"@odata.count":3,"value":[{"Sys_PK":3,"x":30}]}')
  mock <- function(req) {
    urls <<- c(urls, utils::URLdecode(req$url))
    who_response(bodies[length(urls)])
  }
  httr2::with_mocked_responses(mock, out <- .who_odata('DATA_/RELAY_WHS'))
  expect_equal(out$x, c(10L, 20L, 30L))
  expect_match(urls[1], '$skip=0', fixed = TRUE)
  expect_match(urls[2], '$skip=2', fixed = TRUE)
  expect_match(urls[1], '$orderby=Sys_PK', fixed = TRUE)
  expect_true(attr(out, 'who_provenance')$complete)
})

test_that('WHO download rejects changed counts, empty pages and repeated pages', {
  withr::local_options(DSIR.who_page_size = 2L)
  first <- who_page('{"@odata.count":3,"value":[{"Sys_PK":1},{"Sys_PK":2}]}')
  for (body in c('{"@odata.count":4,"value":[{"Sys_PK":3}]}',
                 '{"@odata.count":3,"value":[]}',
                 '{"@odata.count":3,"value":[{"Sys_PK":1},{"Sys_PK":2}]}')) {
    httr2::with_mocked_responses(c(first, who_page(body)), {
      expect_warning(out <- .who_odata('DATA_/RELAY_WHS'), 'incomplete')
      expect_null(out)
    })
  }
})

test_that('WHO failures are distinct from valid empty selections', {
  httr2::with_mocked_responses(who_page('{"@odata.count":0,"value":[]}'), {
    expect_equal(nrow(.who_odata('DATA_/RELAY_WHS')), 0L)
  })
  for (body in c('{broken', '{"error":"failed"}', '{"value":[]}')) {
    httr2::with_mocked_responses(who_page(body), {
      expect_warning(out <- .who_odata('DATA_/RELAY_WHS'))
      expect_null(out)
    })
  }
  httr2::with_mocked_responses(list(who_response('{}', 404L)), {
    expect_warning(out <- .who_odata('DATA_/RELAY_WHS'), 'request failed')
    expect_null(out)
  })
})

test_that('grouped WHO queries ignore fact counts and paginate full group pages', {
  withr::local_options(DSIR.who_page_size = 2L)
  urls <- character()
  bodies <- c('{"@odata.count":65511072,"value":[{"DIM_YEAR_CODE":2022},{"DIM_YEAR_CODE":2023}]}',
              '{"@odata.count":65511072,"value":[]}')
  httr2::with_mocked_responses(function(req) {
    urls <<- c(urls, utils::URLdecode(req$url)); who_response(bodies[length(urls)])
  }, out <- .who_distinct('DEX_CMS/GHE_FULL', 'DIM_YEAR_CODE'))
  expect_equal(out$DIM_YEAR_CODE, c(2022L, 2023L))
  expect_length(urls, 2L)
  expect_match(urls[2], '$skip=2', fixed = TRUE)
})

test_that('WHO queries prevent oversized downloads and use POST for long filters', {
  withr::local_options(DSIR.who_max_rows = 10)
  httr2::with_mocked_responses(who_page('{"@odata.count":11,"value":[{"Sys_PK":1}]}'), {
    expect_warning(out <- .who_odata('DATA_/RELAY_WHS'), 'exceeds')
    expect_null(out)
  })
  captured <- NULL
  httr2::with_mocked_responses(function(req) {
    captured <<- req; who_response('{"@odata.count":0,"value":[]}')
  }, .who_odata('DATA_/RELAY_WHS', filter = .who_in('IND_ID', paste0('indicator_', seq_len(200)))))
  expect_match(captured$url, '/$query', fixed = TRUE)
  expect_equal(captured$method, 'POST')
  expect_match(captured$body$content_type, 'text/plain', fixed = TRUE)
})

test_that('WHO memory cache is scoped to the origin and never caches failures', {
  calls <- 0L
  withr::local_options(DSIR.who_backend = 'xmart', DSIR.who_base_url = 'https://test.who.int')
  key <- paste0('test:', tempfile())
  fetch <- function() { calls <<- calls + 1L; tibble::tibble(x = calls) }
  expect_equal(.who_cached(key, fetch)$x, 1L)
  expect_equal(.who_cached(key, fetch)$x, 1L)
  withr::local_options(DSIR.who_base_url = 'https://other.who.int')
  expect_equal(.who_cached(key, fetch)$x, 2L)
  failure <- function() { calls <<- calls + 1L; NULL }
  .who_cached('failed', failure); .who_cached('failed', failure)
  expect_equal(calls, 4L)
})

test_that('GHO xMart normalization preserves bounds, codes and named dimensions', {
  context <- list(code = 'X', name = 'Test', unit = 'years', dimensions = c('DIM_SEX', 'DIM_AGE'))
  raw <- tibble::tibble(IND_ID = 'X', DIM_TIME = '2023', DIM_TIME_TYPE = 'YEAR',
                        DIM_GEO_CODE_M49 = '608', DIM_GEO_CODE_TYPE = 'COUNTRY',
                        DIM_SEX = 'FEMALE', DIM_AGE = 'Y40T44', AMOUNT_N = 10,
                        AMOUNT_NL = 8, AMOUNT_NU = 12, VALUE_LABEL = '<10')
  testthat::local_mocked_bindings(.xmart_geo_code = function(code, inverse = FALSE) rep('PHL', length(code)), .package = 'DSIR')
  out <- .xmart_gho_normalize(raw, context)
  expect_equal(out$NumericValue, 10)
  expect_equal(out$Low, 8)
  expect_equal(out$High, 12)
  expect_equal(out$Value, '<10')
  expect_equal(out$Dim1, 'SEX_FMLE')
  expect_equal(out$Dim1Type, 'SEX')
  cleaned <- gho_clean(out, keep_dimensions = TRUE, keep_metadata = TRUE)
  expect_equal(cleaned$dim_sex, 'FEMALE')
  expect_equal(cleaned$dim_age, 'Y40T44')
  expect_equal(cleaned$unit, 'years')
  expect_equal(ncol(gho_clean(out)), 15L)
  raw$COUNT_N <- 2
  expect_warning(out <- .xmart_gho_normalize(raw, context), 'Multiple numeric')
  expect_equal(nrow(out), 0L)
})

test_that('GHO unknown codes never trigger legacy fallback', {
  withr::local_options(DSIR.who_backend = 'xmart')
  testthat::local_mocked_bindings(.xmart_catalog = function() tibble::tibble(IND_CODE_GHO = 'known'),
    .legacy_gho_data = function(...) stop('legacy called'), .package = 'DSIR')
  expect_warning(out <- gho_data('unknown'), 'Unknown GHO')
  expect_equal(nrow(out), 0L)
})

test_that('GHO age namespaces remain compatible while named source codes stay exact', {
  expect_equal(.xmart_age_code('AGEGROUP_YEARS30-69'), 'YEARS30-69')
  expect_equal(.xmart_age_code(c('YEARS30-69', NA_character_), TRUE), c('AGEGROUP_YEARS30-69', NA_character_))
  context <- list(code = 'X', name = 'Test', unit = 'percent', dimensions = c('DIM_SEX', 'DIM_AGE'))
  testthat::local_mocked_bindings(.xmart_geo_code = function(code, inverse = FALSE) rep('PHL', length(code)), .package = 'DSIR')
  raw <- tibble::tibble(DIM_TIME = '2023', DIM_GEO_CODE_M49 = '608', DIM_SEX = 'TOTAL',
                        DIM_AGE = 'YEARS30-69', PERCENT_N = 1)
  out <- .xmart_gho_normalize(raw, context)
  expect_equal(out$Dim2, 'AGEGROUP_YEARS30-69')
  expect_equal(out$Dim2Type, 'AGEGROUP')
  expect_equal(gho_clean(out, TRUE)$dim_age, 'YEARS30-69')
})

test_that('long GHO tables retain row-specific types and derive named dimensions', {
  testthat::local_mocked_bindings(.xmart_geo_code = function(code, inverse = FALSE) rep('PHL', length(code)), .package = 'DSIR')
  raw <- tibble::tibble(DIM_TIME = c('2022', '2023'), DIM_GEO_CODE_M49 = c('608', '608'),
    DIM_1_CODE = c('DIM_SEX', 'DIM_AGE'), DIM_MEMBER_1_CODE = c('FEMALE', 'Y40T44'),
    DIM_2_CODE = c('DIM_AGE', 'DIM_SEX'), DIM_MEMBER_2_CODE = c('Y40T44', 'MALE'),
    VALUE_NUMERIC = c(10, 20), VALUE_NUMERIC_LOWER = c(8, 18), VALUE_NUMERIC_UPPER = c(12, 22))
  out <- .xmart_gho_normalize(raw, list(code = 'X', name = 'Test', unit = 'years', dimensions = character()))
  expect_equal(out$Dim1Type, c('SEX', 'AGEGROUP'))
  expect_equal(out$Dim1, c('SEX_FMLE', 'AGEGROUP_Y40T44'))
  clean <- gho_clean(out, TRUE)
  expect_equal(clean$dim_sex, c('FEMALE', 'MALE'))
  expect_equal(clean$dim_age, c('Y40T44', 'Y40T44'))
  expect_equal(clean$low, c(8, 18))
  expect_equal(clean$high, c(12, 22))
})

test_that('small WHO references fail soft when full or malformed', {
  httr2::with_mocked_responses(who_page('{"value":[{"CODE":"TOTAL","TITLE":"Total"}]}'), {
    expect_equal(.who_reference('DEX_CMS/REF_SEX_COD')$CODE, 'TOTAL')
  })
  httr2::with_mocked_responses(who_page('{"value":[{"CODE":"TOTAL","TITLE":"Total"}]}'), {
    expect_warning(out <- .who_reference('DEX_CMS/REF_SEX_COD', top = 1L), 'incomplete')
    expect_null(out)
  })
  httr2::with_mocked_responses(who_page('{"value":[{"wrong":"value"}]}'), {
    expect_warning(out <- .who_reference('DEX_CMS/REF_SEX_COD'), 'Malformed')
    expect_null(out)
  })
  httr2::with_mocked_responses(who_page('42'), {
    expect_warning(out <- .who_reference('DEX_CMS/REF_SEX_COD'), 'malformed')
    expect_null(out)
  })
})

test_that('nonannual GHO time metadata is retained and coverage does not invent years', {
  testthat::local_mocked_bindings(
    .xmart_geo_code = function(code, inverse = FALSE) rep('PHL', length(code)),
    .xmart_gho_context = function(...) list(path = 'DATA_/RELAY_WHS', filter = ''),
    .package = 'DSIR'
  )
  raw <- tibble::tibble(DIM_TIME = '2023-Q1', DIM_TIME_TYPE = 'QUARTER',
    DIM_GEO_CODE_M49 = '608', AMOUNT_N = 1)
  context <- list(code = 'X', name = 'Test', unit = 'years', dimensions = character())
  clean <- gho_clean(.xmart_gho_normalize(raw, context), keep_metadata = TRUE)
  expect_true(is.na(clean$year))
  expect_equal(clean$time_detail, '2023-Q1')
  expect_equal(clean$time_type, 'QUARTER')
  httr2::with_mocked_responses(who_page('{"@odata.count":1,"value":[{"Sys_PK":1,"DIM_GEO_CODE_M49":"608","DIM_TIME":"2023-Q1"}]}'), {
    out <- .xmart_gho_coverage('X')
    expect_true(is.na(out$year_min))
    expect_true(is.na(out$year_max))
    expect_equal(out$n_obs, 1L)
  })
})

test_that('malformed WHO field and geography lookups fail soft', {
  httr2::with_mocked_responses(who_page('42'), {
    expect_warning(out <- .xmart_fields('DATA_/BAD_SCHEMA'), 'Malformed')
    expect_length(out, 0L)
  })
  withr::local_options(DSIR.who_base_url = 'https://invalid-geo-test.who.int')
  httr2::with_mocked_responses(who_page('{"@odata.count":1,"value":[{"Sys_PK":1,"wrong":"value"}]}'), {
    expect_warning(out <- .xmart_geo(), 'Malformed')
    expect_null(out)
  })
})

test_that('observed long-table population sex and age codes preserve legacy filters', {
  context <- list(code = 'X', id = 'ID', name = 'Test', unit = 'percent',
    path = 'DATA_/RELAY_GHO', fields = c('IND_ID', 'DIM_TIME', 'DIM_GEO_CODE_M49',
      'DIM_1_CODE', 'DIM_MEMBER_1_CODE', 'DIM_2_CODE', 'DIM_MEMBER_2_CODE'),
    dimensions = character())
  testthat::local_mocked_bindings(
    .xmart_geo_code = function(code, inverse = FALSE) rep('PHL', length(code)),
    .xmart_gho_route = function(indicator) context,
    .xmart_fields = function(path) context$fields,
    .xmart_long_types = function(context) tibble::tibble(DIM_1_CODE = 'DIM_POP_SEX', DIM_2_CODE = 'DIM_POP_AGE_GRP'),
    .package = 'DSIR'
  )
  raw <- tibble::tibble(DIM_TIME = '2023', DIM_GEO_CODE_M49 = '608',
    DIM_1_CODE = 'DIM_POP_SEX', DIM_MEMBER_1_CODE = 'FMLE',
    DIM_2_CODE = 'DIM_POP_AGE_GRP', DIM_MEMBER_2_CODE = 'YEARS18-PLUS', VALUE_NUMERIC = 10)
  out <- .xmart_gho_normalize(raw, context)
  expect_equal(out$Dim1, 'SEX_FMLE')
  expect_equal(out$Dim1Type, 'SEX')
  expect_equal(out$Dim2, 'AGEGROUP_YEARS18-PLUS')
  expect_equal(out$Dim2Type, 'AGEGROUP')
  expect_equal(gho_clean(out, TRUE)$dim_pop_sex, 'FMLE')
  filtered <- .xmart_gho_context('X', dim1 = 'SEX_FMLE', dim2 = 'AGEGROUP_YEARS18-PLUS')
  expect_match(filtered$filter, "DIM_1_CODE eq 'DIM_POP_SEX'", fixed = TRUE)
  expect_match(filtered$filter, "DIM_MEMBER_1_CODE eq 'FMLE'", fixed = TRUE)
  expect_match(filtered$filter, 'DIM_2_CODE in (', fixed = TRUE)
  expect_match(filtered$filter, "'DIM_POP_AGE_GRP'", fixed = TRUE)
  expect_match(filtered$filter, "DIM_MEMBER_2_CODE eq 'YEARS18-PLUS'", fixed = TRUE)
  named <- .xmart_gho_context('X', dimensions = list(DIM_POP_SEX = 'FMLE'))
  expect_match(named$filter, "DIM_MEMBER_1_CODE eq 'FMLE'", fixed = TRUE)
  expect_false(grepl('DIM_MEMBER_2_CODE', named$filter, fixed = TRUE))
  expect_error(.xmart_gho_context('X', dimensions = list(DIM_UNKNOWN = 'FMLE')), 'Unknown named')
  expect_error(.xmart_gho_context('X', dimensions = list(DIM_POP_SEX = NULL)), 'non-missing')
})

test_that('long-table discovery respects the six-clause WHO ordering limit', {
  withr::local_options(DSIR.who_base_url = 'https://type-discovery-test.who.int')
  context <- list(path = 'DATA_/RELAY_GHO', id = 'X', fields = paste0('DIM_', 1:12, '_CODE'))
  urls <- character()
  httr2::with_mocked_responses(function(req) {
    urls <<- c(urls, utils::URLdecode(req$url))
    who_response(if (length(urls) == 1L) '{"value":[{"DIM_1_CODE":"DIM_POP_SEX"}]}'
      else '{"value":[{"DIM_7_CODE":"DIM_AGE"}]}')
  }, out <- .xmart_long_types(context))
  expect_length(urls, 2L)
  expect_match(urls[1], '$orderby=DIM_1_CODE,DIM_2_CODE,DIM_3_CODE,DIM_4_CODE,DIM_5_CODE,DIM_6_CODE', fixed = TRUE)
  expect_true('DIM_POP_SEX' %in% out$DIM_1_CODE)
  expect_true('DIM_AGE' %in% out$DIM_7_CODE)
})
