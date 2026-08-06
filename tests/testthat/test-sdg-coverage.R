test_that("sdg_coverage returns the documented 5-column shape", {
  skip_on_cran()
  skip_if_offline()

  out <- sdg_coverage("3.4.1", area = c("156", "608"))
  expect_s3_class(out, "tbl_df")
  expect_named(out, c("location", "series", "year_min", "year_max", "n_obs"))
  expect_type(out$location, "character")
  expect_type(out$series, "character")
  expect_type(out$year_min, "integer")
  expect_type(out$year_max, "integer")
  expect_type(out$n_obs, "integer")
  expect_gt(nrow(out), 0L)
  expect_setequal(out$location, c("156", "608"))
  expect_true(all(out$year_min <= out$year_max))
  expect_true(all(out$n_obs >= 1L))
})

test_that("sdg_coverage exposes multiple series per location for a multi-series indicator", {
  skip_on_cran()
  skip_if_offline()

  # 3.b.1 (vaccine coverage) is published as multiple series:
  # SH_ACS_DTP3, SH_ACS_MCV2, SH_ACS_PCV3, SH_ACS_HPV. So one
  # location should appear with multiple rows.
  out <- sdg_coverage("3.b.1", area = "156")
  series_per_loc <- table(out$location)
  expect_true(any(series_per_loc > 1L))
})

test_that("sdg_coverage is sorted by location then series", {
  skip_on_cran()
  skip_if_offline()

  out <- sdg_coverage("3.b.1", area = c("608", "156"))
  expected <- out[order(out$location, out$series), , drop = FALSE]
  expect_identical(out, expected)
})

# --- Offline mock tests -----------------------------------------------
# Same canned-response pattern as test-sdg-get-mock.R; these guard the
# multi-series fixes without needing the UN endpoint.

mock_json <- function(body, status = 200L) {
  list(httr2::response(
    status_code = status,
    headers     = list(`content-type` = "application/json"),
    body        = charToRaw(body)
  ))
}

test_that("sdg_coverage aggregates a multi-series pull spanning unlike pages", {
  # NEWS 0.9.0: sdg_coverage() on a multi-series indicator used to die
  # inside sdg_data()'s page rbind when the per-series `dimensions`
  # columns differed across pages. End-to-end guard for the fix.
  skip_if_not_installed("httptest2")
  page1 <- paste0(
    '{"data":[',
    '{"series":"SH_ACS_DTP3","geoAreaCode":"156","timePeriodStart":2015,',
    '"value":"97","dimensions":{"Sex":"BOTHSEX"}},',
    '{"series":"SH_ACS_DTP3","geoAreaCode":"156","timePeriodStart":2016,',
    '"value":"99","dimensions":{"Sex":"BOTHSEX"}}',
    '],"totalPages":2}'
  )
  page2 <- paste0(
    '{"data":[',
    '{"series":"SH_ACS_HPV","geoAreaCode":"156","timePeriodStart":2016,',
    '"value":"45","dimensions":{"Sex":"FEMALE","Age":"15Y"}}',
    '],"totalPages":2}'
  )
  httr2::with_mocked_responses(
    c(mock_json(page1), mock_json(page2)),
    {
      out <- sdg_coverage("3.b.1", area = "156")
      expect_named(out, c("location", "series", "year_min", "year_max", "n_obs"))
      expect_equal(nrow(out), 2L)
      dtp3 <- out[out$series == "SH_ACS_DTP3", ]
      expect_equal(dtp3$year_min, 2015L)
      expect_equal(dtp3$year_max, 2016L)
      expect_equal(dtp3$n_obs, 2L)
      hpv <- out[out$series == "SH_ACS_HPV", ]
      expect_equal(hpv$year_min, 2016L)
      expect_equal(hpv$n_obs, 1L)
    }
  )
})

test_that("sdg_coverage keeps a missing series code as NA", {
  # NEWS 0.9.0: per-group location/series are read back from the data,
  # not strsplit out of the grouping key — so a null series stays NA
  # instead of erroring or becoming the string "NA".
  skip_if_not_installed("httptest2")
  page <- paste0(
    '{"data":[',
    '{"series":"SH_ACS_DTP3","geoAreaCode":"156","timePeriodStart":2015,',
    '"value":"97"},',
    '{"series":null,"geoAreaCode":"156","timePeriodStart":2016,',
    '"value":"1"}',
    '],"totalPages":1}'
  )
  httr2::with_mocked_responses(
    mock_json(page),
    {
      out <- sdg_coverage("3.b.1", area = "156")
      expect_equal(nrow(out), 2L)
      expect_setequal(out$location, "156")
      expect_true(any(is.na(out$series)))
      expect_false(any(out$series == "NA", na.rm = TRUE))
    }
  )
})

test_that("sdg_coverage returns an empty 5-col tibble on no match", {
  skip_on_cran()
  skip_if_offline()

  # "999" is not a valid M49 area code.
  out <- suppressWarnings(sdg_coverage("3.4.1", area = "999"))
  expect_s3_class(out, "tbl_df")
  expect_named(out, c("location", "series", "year_min", "year_max", "n_obs"))
  expect_equal(nrow(out), 0L)
  expect_type(out$location, "character")
  expect_type(out$series, "character")
  expect_type(out$year_min, "integer")
  expect_type(out$year_max, "integer")
  expect_type(out$n_obs, "integer")
})
