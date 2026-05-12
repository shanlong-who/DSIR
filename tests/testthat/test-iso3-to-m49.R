test_that("iso3_to_m49 maps known codes correctly", {
  result <- iso3_to_m49(c("PHL", "FRA", "JPN"))
  expect_equal(length(result), 3L)
  expect_false(any(is.na(result)))
  expect_type(result, "character")
})

test_that("iso3_to_m49 returns NA for non-Members and unknown codes", {
  expect_true(is.na(iso3_to_m49("PRI")))   # Associate Member
  expect_true(is.na(iso3_to_m49("XYZ")))   # never assigned
})

test_that("iso3_to_m49 is case-insensitive", {
  expect_equal(iso3_to_m49("phl"), iso3_to_m49("PHL"))
  expect_equal(iso3_to_m49("Fra"), iso3_to_m49("FRA"))
})

test_that("iso3_to_m49 preserves position (NAs in place, length matches)", {
  result <- iso3_to_m49(c("PHL", "XYZ", "FRA"))
  expect_equal(length(result), 3L)
  expect_false(is.na(result[1]))
  expect_true(is.na(result[2]))
  expect_false(is.na(result[3]))
})

test_that("iso3_to_m49 handles empty input", {
  result <- iso3_to_m49(character(0))
  expect_equal(length(result), 0L)
  expect_type(result, "character")
})

test_that("iso3_to_m49 errors on non-character input", {
  expect_error(iso3_to_m49(123),  "must be a character")
  expect_error(iso3_to_m49(NULL), "must be a character")
  expect_error(iso3_to_m49(TRUE), "must be a character")
})
