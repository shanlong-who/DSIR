test_that("who_countries has the expected shape and columns", {
  expect_s3_class(who_countries, "tbl_df")
  expect_equal(nrow(who_countries), 194L)
  expect_named(who_countries,
               c("iso3", "iso2", "m49_code",
                 "name_official", "name_short",
                 "who_region", "is_pic"))
})

test_that("who_countries identifiers are well-formed", {
  expect_true(all(nchar(who_countries$iso3) == 3L))
  expect_true(all(who_countries$iso3 == toupper(who_countries$iso3)))
  expect_true(all(nchar(who_countries$iso2) == 2L))
  expect_true(all(nchar(who_countries$m49_code) == 3L))
  # m49_code is stored as 3-char zero-padded character.
  expect_type(who_countries$m49_code, "character")
})

test_that("who_countries has no missing identifiers", {
  expect_false(anyNA(who_countries$iso3))
  expect_false(anyNA(who_countries$iso2))
  expect_false(anyNA(who_countries$m49_code))
  expect_false(anyNA(who_countries$name_official))
  expect_false(anyNA(who_countries$name_short))
  expect_false(anyNA(who_countries$who_region))
  expect_false(anyNA(who_countries$is_pic))
})

test_that("who_countries identifiers are unique", {
  expect_equal(anyDuplicated(who_countries$iso3),     0L)
  expect_equal(anyDuplicated(who_countries$iso2),     0L)
  expect_equal(anyDuplicated(who_countries$m49_code), 0L)
})

test_that("who_countries who_region values are from the WHO set", {
  expect_setequal(unique(who_countries$who_region),
                  c("AFR", "AMR", "SEAR", "EUR", "EMR", "WPR"))
})

test_that("who_countries is_pic is logical and only TRUE in WPR", {
  expect_type(who_countries$is_pic, "logical")
  expect_equal(sum(who_countries$is_pic), 14L)
  pic_rows <- who_countries[who_countries$is_pic, ]
  expect_true(all(pic_rows$who_region == "WPR"))
})

test_that("who_countries regional row counts match documentation", {
  tab <- table(who_countries$who_region)
  expect_equal(unname(tab["AFR"]),  47L)
  expect_equal(unname(tab["AMR"]),  35L)
  expect_equal(unname(tab["SEAR"]), 10L)
  expect_equal(unname(tab["EUR"]),  53L)
  expect_equal(unname(tab["EMR"]),  21L)
  expect_equal(unname(tab["WPR"]),  28L)
})

test_that("who_countries reflects WHO EB156 reassignment of Indonesia to WPR", {
  idn <- who_countries[who_countries$iso3 == "IDN", ]
  expect_equal(idn$who_region, "WPR")
})
