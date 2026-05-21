# Offline regression tests for .sdg_get(), sdg_data(), and the SDG list
# endpoints. Uses httr2 mocked responses so these run on CRAN and on
# machines without internet. Each test guards an explicit fix described
# in NEWS.md.

skip_if_not_installed("httptest2")  # Suggests dependency

mock_json <- function(body, status = 200L) {
  list(httr2::response(
    status_code = status,
    headers     = list(`content-type` = "application/json"),
    body        = charToRaw(body)
  ))
}

test_that(".sdg_get returns NULL with a warning on HTTP failure", {
  httr2::with_mocked_responses(
    mock_json('{"error":"boom"}', status = 404L),
    {
      expect_warning(
        out <- DSIR:::.sdg_get("https://example.test/v1/sdg/Goal/List"),
        "SDG request failed"
      )
      expect_null(out)
    }
  )
})

test_that("sdg_goals returns NULL when the service is unreachable", {
  httr2::with_mocked_responses(
    mock_json('{"error":"boom"}', status = 404L),
    {
      out <- suppressWarnings(sdg_goals())
      expect_null(out)
    }
  )
})

test_that("sdg_data assembles rows across multiple pages without errors", {
  # NEWS 0.7.0: per-page row.names previously clashed when do.call(rbind)
  # ran across pages ("duplicate 'row.names' are not allowed"). To
  # actually trip the collision in a regression test, each mock page
  # must contain >1 row so that auto-generated row names overlap
  # ("1","2" on both pages).
  make_row <- function(year) {
    paste0(
      '{"goal":"3","target":"3.4","indicator":["3.4.1"],',
      '"series":"SH_DTH_NCD","geoAreaCode":"608","geoAreaName":"PHL",',
      '"timePeriodStart":', year, ',"value":"17.3"}'
    )
  }
  page1 <- paste0('{"data":[', paste(make_row(2017), make_row(2018), sep = ","),
                  '],"totalPages":2}')
  page2 <- paste0('{"data":[', paste(make_row(2019), make_row(2020), sep = ","),
                  '],"totalPages":2}')
  httr2::with_mocked_responses(
    c(mock_json(page1), mock_json(page2)),
    {
      out <- sdg_data("3.4.1", area = "608")
      expect_s3_class(out, "tbl_df")
      expect_equal(nrow(out), 4L)
      expect_setequal(out$timePeriodStart, c(2017, 2018, 2019, 2020))
    }
  )
})

# Helper for the URL-capturing tests below. `mock` is a function rather
# than a list because we need to inspect each outgoing request before
# returning the canned response.
capture_url_mock <- function(body) {
  captured <- character()
  fn <- function(req) {
    captured[[length(captured) + 1L]] <<- req$url
    httr2::response(
      status_code = 200L,
      headers     = list(`content-type` = "application/json"),
      body        = charToRaw(body)
    )
  }
  list(fn = fn, urls = function() captured)
}

test_that("sdg_data sends multi-value indicator as repeated keys, not comma-joined", {
  # NEWS 0.6.0: previously joined as `indicator=A,B`, which the SDG API
  # silently drops. Must serialise as repeated `indicator=A&indicator=B`.
  m <- capture_url_mock('{"data": [], "totalPages": 1}')
  httr2::with_mocked_responses(m$fn, {
    suppressWarnings(sdg_data(c("3.4.1", "3.4.2"), area = "608"))
  })
  urls <- m$urls()
  expect_gte(length(urls), 1L)
  expect_match(urls[1], "indicator=3.4.1", fixed = TRUE)
  expect_match(urls[1], "indicator=3.4.2", fixed = TRUE)
  expect_false(grepl("indicator=3.4.1,3.4.2", urls[1], fixed = TRUE))
})

test_that("sdg_data sends multi-value area as repeated areaCode keys", {
  m <- capture_url_mock('{"data": [], "totalPages": 1}')
  httr2::with_mocked_responses(m$fn, {
    suppressWarnings(sdg_data("3.4.1", area = c("608", "076")))
  })
  urls <- m$urls()
  expect_gte(length(urls), 1L)
  expect_match(urls[1], "areaCode=608", fixed = TRUE)
  expect_match(urls[1], "areaCode=076", fixed = TRUE)
  expect_false(grepl("areaCode=608,076", urls[1], fixed = TRUE))
})

test_that("sdg_data applies year filter client-side", {
  # NEWS 0.6.0: timePeriodStart / timePeriodEnd cause HTTP 500 on the
  # real API for some combinations, so year filtering must run on the
  # client. Verify (a) no year params in the outgoing URL, (b) rows
  # outside the requested range are stripped from the result.
  page <- paste0(
    '{"data":[',
    '{"indicator":["3.4.1"],"geoAreaCode":"608","timePeriodStart":2005,"value":"1"},',
    '{"indicator":["3.4.1"],"geoAreaCode":"608","timePeriodStart":2015,"value":"2"},',
    '{"indicator":["3.4.1"],"geoAreaCode":"608","timePeriodStart":2020,"value":"3"}',
    '],"totalPages":1}'
  )
  m <- capture_url_mock(page)
  httr2::with_mocked_responses(m$fn, {
    out <<- sdg_data("3.4.1", area = "608", year_from = 2010, year_to = 2017)
  })
  urls <- m$urls()
  expect_gte(length(urls), 1L)
  expect_false(grepl("timePeriodStart", urls[1], fixed = TRUE))
  expect_false(grepl("timePeriodEnd",   urls[1], fixed = TRUE))
  expect_equal(nrow(out), 1L)
  expect_equal(out$timePeriodStart, 2015)
})

test_that(".sdg_get returns NULL with a warning on a malformed JSON body", {
  # NEWS 0.7.0: the UN SDG endpoint occasionally returns a truncated
  # response body; resp_body_json() surfaces that as a parse error.
  # The body-parse tryCatch must downgrade it to a warning + NULL so a
  # flaky endpoint cannot break an R CMD check example run.
  httr2::with_mocked_responses(
    mock_json('{"data": [{"series":"SH_DTH_NCD"'),  # truncated, unparseable
    {
      expect_warning(
        out <- DSIR:::.sdg_get("https://example.test/v1/sdg/Goal/List"),
        "could not be parsed as JSON"
      )
      expect_null(out)
    }
  )
})
