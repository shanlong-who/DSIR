pagination_response <- function(body, status = 200L) {
  httr2::response(status_code = status,
                  headers = list(`content-type` = "application/json"),
                  body = charToRaw(body))
}

pagination_page <- function(page, total_rows = 2, total_pages = 2) {
  pagination_response(paste0(
    '{"data":[{"series":"S","geoAreaCode":"608",',
    '"timePeriodStart":', 2019 + page, ',"value":"1"}],',
    '"pageNumber":', page, ',"totalPages":', total_pages,
    ',"totalElements":', total_rows, '}'
  ))
}

test_that("SDG counts are checked before local filters", {
  httr2::with_mocked_responses(list(pagination_page(1), pagination_page(2)), {
    out <- sdg_data("3.8.2", area = "PHL", year_from = 2021)
    expect_equal(nrow(out), 1L)
    expect_equal(out$timePeriodStart, 2021)
  })
})

test_that("an empty later SDG page never returns the earlier partial data", {
  empty <- pagination_response('{"data":[],"totalPages":2,"totalElements":2}')
  httr2::with_mocked_responses(list(pagination_page(1), empty), {
    expect_warning(out <- sdg_data("3.8.2"), class = "dsir_incomplete_data")
    expect_equal(nrow(out), 0L)
  })
})

test_that("too few rows and changing pagination declarations fail soft", {
  cases <- list(
    list(pagination_page(1, 3), pagination_page(2, 3)),
    list(pagination_page(1), pagination_page(2, 3)),
    list(pagination_page(1), pagination_page(2, 2, 3)),
    list(pagination_page(1), pagination_page(1))
  )
  for (pages in cases) {
    httr2::with_mocked_responses(pages, {
      expect_warning(out <- sdg_data("3.8.2"), class = "dsir_incomplete_data")
      expect_equal(nrow(out), 0L)
    })
  }
})

test_that("invalid pagination envelopes warn rather than error or loop", {
  bodies <- c(
    '{}',
    '{"data":[1,2],"totalPages":1}',
    '{"data":[],"totalPages":-1}',
    '{"data":[],"totalPages":"two"}',
    '{"data":[],"totalPages":1.5}',
    '{"data":[],"totalElements":[1,2]}',
    '{"data":[],"totalPages":2}',
    '{"data":[{"value":"1"}],"totalElements":0}',
    '{"data":[{"value":"1"}],"totalPages":0}',
    '{"data":[{"value":"1"}],"totalElements":2}'
  )
  for (body in bodies) {
    httr2::with_mocked_responses(list(pagination_response(body)), {
      expect_warning(out <- sdg_data("3.8.2"), class = "dsir_incomplete_data")
      expect_equal(nrow(out), 0L)
    })
  }
})

test_that("a declared empty SDG result remains a legitimate no-data result", {
  page <- pagination_response('{"data":[],"totalPages":0,"totalElements":0}')
  httr2::with_mocked_responses(list(page), {
    expect_warning(out <- sdg_data("3.8.2"), "No data returned")
    expect_equal(nrow(out), 0L)
  })
})

test_that("incompatible SDG page schemas fail soft", {
  second <- pagination_response(paste0(
    '{"data":[{"series":"S","geoAreaCode":"608",',
    '"timePeriodStart":2021,"value":2}],"totalPages":2,"totalElements":2}'
  ))
  httr2::with_mocked_responses(list(pagination_page(1), second), {
    expect_warning(out <- sdg_data("3.8.2"), "pages could not be combined")
    expect_equal(nrow(out), 0L)
  })
})

test_that("a later HTTP failure discards SDG partial data", {
  pages <- list(pagination_page(1), pagination_response("{}", 404L))
  httr2::with_mocked_responses(pages, {
    expect_warning(out <- sdg_data("3.8.2"), "SDG request failed")
    expect_equal(nrow(out), 0L)
  })
})

test_that("sdg_coverage retains request and incomplete-download warnings", {
  httr2::with_mocked_responses(list(pagination_response("{}", 404L)), {
    expect_warning(out <- sdg_coverage("3.8.2"), "SDG request failed")
    expect_named(out, c("location", "series", "year_min", "year_max", "n_obs"))
    expect_equal(nrow(out), 0L)
  })
  pages <- list(pagination_page(1), pagination_response('{"data":[],"totalPages":2}'))
  httr2::with_mocked_responses(pages, {
    expect_warning(out <- sdg_coverage("3.8.2"), class = "dsir_incomplete_data")
    expect_equal(nrow(out), 0L)
  })
})

test_that("sdg_coverage applies series and dimension filters", {
  page <- pagination_response(paste0(
    '{"data":[',
    '{"series":"A","geoAreaCode":"608","timePeriodStart":2020,',
    '"dimensions":{"Sex":"MALE"}},',
    '{"series":"A","geoAreaCode":"608","timePeriodStart":2021,',
    '"dimensions":{"Sex":"FEMALE"}},',
    '{"series":"B","geoAreaCode":"608","timePeriodStart":2022,',
    '"dimensions":{"Sex":"FEMALE"}}],"totalPages":1,"totalElements":3}'
  ))
  httr2::with_mocked_responses(list(page), {
    out <- sdg_coverage("3.8.2", series = "A", dimensions = list(Sex = "FEMALE"))
    expect_equal(out$series, "A")
    expect_equal(out$n_obs, 1L)
    expect_equal(out$year_min, 2021L)
  })
})

test_that("sdg_coverage warns when observations lack required fields", {
  page <- pagination_response('{"data":[{"value":"1"}],"totalPages":1}')
  httr2::with_mocked_responses(list(page), {
    expect_warning(out <- sdg_coverage("3.8.2"), "missing column")
    expect_equal(nrow(out), 0L)
  })
})
