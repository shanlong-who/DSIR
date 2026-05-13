test_that("iso3_to_region returns short codes", {
  expect_equal(iso3_to_region("PHL"), "WPR")
  expect_equal(iso3_to_region("IDN"), "WPR")  # post-EB156, May 2025
  expect_equal(iso3_to_region(c("FRA", "USA", "JPN")), c("EUR", "AMR", "WPR"))
})

test_that("iso3_to_region returns long names for all six regions", {
  # One country per region — ensures the short → long map has full coverage.
  expect_equal(iso3_to_region("ZAF", long = TRUE), "Africa")
  expect_equal(iso3_to_region("USA", long = TRUE), "Americas")
  expect_equal(iso3_to_region("IND", long = TRUE), "South-East Asia")
  expect_equal(iso3_to_region("FRA", long = TRUE), "Europe")
  expect_equal(iso3_to_region("EGY", long = TRUE), "Eastern Mediterranean")
  expect_equal(iso3_to_region("PHL", long = TRUE), "Western Pacific")
})

test_that("iso3_to_region returns NA for non-Member codes", {
  expect_true(is.na(iso3_to_region("XXX")))
  expect_true(is.na(iso3_to_region("PRI")))  # Associate Member
})

test_that("iso3_to_region preserves vector length and order", {
  res <- iso3_to_region(c("PHL", "XXX", "FRA"))
  expect_length(res, 3)
  expect_equal(res, c("WPR", NA_character_, "EUR"))
})

test_that("iso3_to_region rejects bad input", {
  expect_error(iso3_to_region(123), "must be a character vector")
  expect_error(iso3_to_region("PHL", long = "yes"), "single logical")
})
