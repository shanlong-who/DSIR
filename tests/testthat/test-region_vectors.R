# Each regional ISO3 vector should equal the corresponding slice of
# who_countries$iso3 (sorted), since they are all derived from it.

expect_region_vector <- function(vec, region, expected_length) {
  expect_type(vec, "character")
  expect_length(vec, expected_length)
  expect_true(all(nchar(vec) == 3L))
  expect_true(all(vec == toupper(vec)))
  expect_false(anyDuplicated(vec) > 0L)
  expect_setequal(
    vec,
    who_countries$iso3[who_countries$who_region == region]
  )
  expect_equal(vec, sort(vec))
}

test_that("afro_cty matches the AFR slice of who_countries", {
  expect_region_vector(afro_cty, "AFR", 47L)
})

test_that("amro_cty matches the AMR slice of who_countries", {
  expect_region_vector(amro_cty, "AMR", 35L)
})

test_that("searo_cty matches the SEAR slice of who_countries", {
  expect_region_vector(searo_cty, "SEAR", 10L)
  # Indonesia moved to WPR in May 2025, so SEAR must NOT contain IDN.
  expect_false("IDN" %in% searo_cty)
})

test_that("euro_cty matches the EUR slice of who_countries", {
  expect_region_vector(euro_cty, "EUR", 53L)
})

test_that("emro_cty matches the EMR slice of who_countries", {
  expect_region_vector(emro_cty, "EMR", 21L)
})

test_that("wpro_cty matches the WPR slice of who_countries", {
  expect_region_vector(wpro_cty, "WPR", 28L)
  expect_true("IDN" %in% wpro_cty)
})

test_that("pic_cty is the is_pic subset of WPR", {
  expect_type(pic_cty, "character")
  expect_length(pic_cty, 14L)
  expect_true(all(pic_cty %in% wpro_cty))
  expect_setequal(
    pic_cty,
    who_countries$iso3[who_countries$is_pic]
  )
})
