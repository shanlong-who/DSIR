test_that('HTTP 200 HTML retries are bounded and opt-in for WHO xMart', {
  html <- httr2::response(status_code = 200L,
    headers = list('content-type' = 'text/html; charset=utf-8'))
  xhtml <- httr2::response(status_code = 200L,
    headers = list('content-type' = 'application/xhtml+xml'))
  json <- httr2::response(status_code = 200L,
    headers = list('content-type' = 'application/json'))
  no_type <- httr2::response(status_code = 200L)
  default <- .dsi_request('https://example.test/api/X')
  who <- .dsi_request('https://example.test/DATA_/IND_DIRECTORY_WIDE', retry_on_html = TRUE)

  # httr2 mocks bypass its retry loop. Assert the response policy directly.
  expect_false(default$policies$retry_is_transient(html))
  expect_true(who$policies$retry_is_transient(html))
  expect_true(who$policies$retry_is_transient(xhtml))
  expect_false(who$policies$retry_is_transient(json))
  expect_false(who$policies$retry_is_transient(no_type))
  for (status in c(429L, 500L, 502L, 503L, 504L)) {
    expect_true(who$policies$retry_is_transient(httr2::response(status_code = status)))
  }
  expect_false(who$policies$retry_is_transient(httr2::response(status_code = 404L)))
  expect_equal(who$policies$retry_max_tries, 3)
  expect_equal(who$options$timeout_ms, 30000)
})

test_that('GET and long POST xMart queries enable the HTML retry policy', {
  requests <- list()
  httr2::with_mocked_responses(function(req) {
    requests[[length(requests) + 1L]] <<- req
    who_response('{"@odata.count":0,"value":[]}')
  }, {
    .who_query('DATA_/IND_DIRECTORY_WIDE', list('$top' = 1L))
    .who_query('DATA_/RELAY_WHS', list('$filter' = .who_in('IND_ID', paste0('indicator_', seq_len(200)))))
  })
  html <- httr2::response(status_code = 200L, headers = list('content-type' = 'text/html'))
  expect_length(requests, 2L)
  expect_true(requests[[1]]$policies$retry_is_transient(html))
  expect_true(requests[[2]]$policies$retry_is_transient(html))
  expect_equal(requests[[2]]$method, 'POST')
})

test_that('an HTML catalog failure warns clearly and a later call can recover', {
  origin <- 'https://html-recovery-test.who.int'
  withr::local_options(DSIR.who_backend = 'xmart', DSIR.who_base_url = origin)
  key <- paste('xmart', origin, 'gho_directory', sep = '|')
  saved <- .who_cache[[key]]
  withr::defer(.who_cache[[key]] <- saved)
  .who_cache[[key]] <- NULL
  html <- httr2::response(status_code = 200L,
    headers = list('content-type' = 'text/html; charset=utf-8'),
    body = charToRaw('<html><title>Sorry</title><body>{unavailable}</body></html>'))
  httr2::with_mocked_responses(list(html), {
    expect_warning(out <- gho_indicators('mortality'), 'HTML page instead of JSON')
    expect_s3_class(out, 'tbl_df')
    expect_named(out, c('IndicatorCode', 'IndicatorName', 'Language'))
    expect_equal(nrow(out), 0L)
    expect_null(.who_cache[[key]])
  })

  body <- paste0('{"@odata.count":1,"value":[{"IND_ID":"id1","IND_PER_CODE":"X1",',
    '"IND_CODE_GHO":"X1","IND_NAME_FULL":"Mortality test indicator",',
    '"IND_NAME":"Mortality","TERM_LANG":"en","IND_UNIT":"rate",',
    '"IND_PUBLISH_TABLE":"DATA_/RELAY_WHS","DWNL_QUERY":"DATA_/RELAY_WHS"}]}')
  httr2::with_mocked_responses(who_page(body), {
    out <- gho_indicators('mortality')
    expect_equal(out$IndicatorCode, 'X1')
    expect_equal(out$IndicatorName, 'Mortality test indicator')
    expect_equal(out$Language, 'EN')
    expect_equal(nrow(.who_cache[[key]]$value), 1L)
  })
})

test_that('live xMart indicator discovery returns a searchable catalog', {
  skip_on_cran()
  skip_if(Sys.getenv('DSIR_RUN_LIVE_TESTS') != 'true', 'Live API tests require explicit opt-in')
  skip_if_offline()
  withr::local_options(DSIR.who_backend = 'xmart')
  out <- gho_indicators('mortality')
  expect_gt(nrow(out), 0L)
  expect_true(all(grepl('mortality', out$IndicatorName, ignore.case = TRUE)))
  expect_false(anyDuplicated(out$IndicatorCode) > 0L)
})
