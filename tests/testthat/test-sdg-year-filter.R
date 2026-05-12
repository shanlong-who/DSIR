# Year filtering for `sdg_data()` is implemented client-side as a
# workaround for a UN SDG API bug: sending `timePeriodStart` /
# `timePeriodEnd` as server-side parameters caused HTTP 500 and ~30x
# slowdowns on at least 3.2.1 / area = "608". The previously-broken
# call must now complete quickly and return rows; the filter
# semantics must still match the documented inclusive range.

test_that("year_from works on the previously broken case (3.2.1, 608)", {
  skip_on_cran()
  skip_if_offline()

  t <- system.time({
    out <- sdg_data("3.2.1", area = "608", year_from = 2010)
  })

  expect_s3_class(out, "tbl_df")
  expect_gt(nrow(out), 0L)
  expect_lt(as.numeric(t["elapsed"]), 30)

  yr <- suppressWarnings(as.integer(out$timePeriodStart))
  expect_true(all(yr >= 2010L, na.rm = TRUE))
})

test_that("year_from + year_to bracket the result inclusively", {
  skip_on_cran()
  skip_if_offline()

  out <- sdg_data("3.2.1", area = "608",
                  year_from = 2015, year_to = 2018)
  expect_s3_class(out, "tbl_df")
  expect_gt(nrow(out), 0L)

  yr <- suppressWarnings(as.integer(out$timePeriodStart))
  expect_true(all(yr >= 2015L & yr <= 2018L, na.rm = TRUE))
})

test_that("no year filter returns the full result", {
  skip_on_cran()
  skip_if_offline()

  full       <- sdg_data("3.2.1", area = "608")
  from_2010  <- sdg_data("3.2.1", area = "608", year_from = 2010)

  expect_s3_class(full, "tbl_df")
  expect_gt(nrow(full), 0L)

  # The from_2010 result must be the >= 2010 subset of the full result.
  yr_full <- suppressWarnings(as.integer(full$timePeriodStart))
  manual  <- full[!is.na(yr_full) & yr_full >= 2010L, , drop = FALSE]
  expect_equal(nrow(from_2010), nrow(manual))
})

test_that("sdg_coverage inherits the year-filter fix", {
  skip_on_cran()
  skip_if_offline()

  t <- system.time({
    out <- sdg_coverage("3.2.1", area = "608", year_from = 2010)
  })

  expect_s3_class(out, "tbl_df")
  expect_named(out, c("location", "series", "year_min", "year_max", "n_obs"))
  expect_gt(nrow(out), 0L)
  expect_lt(as.numeric(t["elapsed"]), 30)
  expect_true(all(out$year_min >= 2010L))
})
