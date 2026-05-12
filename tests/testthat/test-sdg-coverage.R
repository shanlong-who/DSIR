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
