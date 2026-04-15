test_that("wpro_cty is a non-empty character vector of ISO3 codes", {
  expect_type(wpro_cty, "character")
  expect_gt(length(wpro_cty), 0)
  expect_true(all(nchar(wpro_cty) == 3))
  expect_true(all(wpro_cty == toupper(wpro_cty)))
})
