test_that("m49_to_iso3 maps known codes correctly", {
  expect_equal(m49_to_iso3(c("608", "250", "392")),
               c("PHL", "FRA", "JPN"))
})

test_that("m49_to_iso3 accepts zero-padded and bare forms", {
  # Brazil's M49 is 076; bare 76 should match the same row.
  expect_equal(m49_to_iso3("076"), "BRA")
  expect_equal(m49_to_iso3("76"),  "BRA")
})

test_that("m49_to_iso3 returns NA for aggregates and non-Member areas", {
  # 900/001 are SDG-style world aggregates; never in who_countries.
  expect_true(is.na(m49_to_iso3("900")))
  expect_true(is.na(m49_to_iso3("001")))
})

test_that("m49_to_iso3 preserves vector length and position", {
  res <- m49_to_iso3(c("608", "900", "250"))
  expect_length(res, 3L)
  expect_equal(res, c("PHL", NA_character_, "FRA"))
})

test_that("m49_to_iso3 handles non-numeric and NA input gracefully", {
  # as.integer() warns on non-numeric input — m49_to_iso3 swallows that
  # and returns NA.
  expect_true(is.na(m49_to_iso3("ABC")))
  expect_true(is.na(m49_to_iso3(NA_character_)))
})

test_that("m49_to_iso3 handles empty input", {
  out <- m49_to_iso3(character(0))
  expect_length(out, 0L)
  expect_type(out, "character")
})

test_that("m49_to_iso3 errors on non-character input", {
  expect_error(m49_to_iso3(608),  "must be a character")
  expect_error(m49_to_iso3(TRUE), "must be a character")
  expect_error(m49_to_iso3(NULL), "must be a character")
})

test_that("iso3_to_m49 and m49_to_iso3 round-trip on Member States", {
  iso <- c("PHL", "FRA", "JPN", "BRA", "USA")
  expect_equal(m49_to_iso3(iso3_to_m49(iso)), iso)
})
