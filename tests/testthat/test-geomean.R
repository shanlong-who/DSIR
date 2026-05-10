test_that("geomean computes correctly on positive values", {
  expect_equal(geomean(c(1, 4, 16)), 4)
  expect_equal(geomean(c(2, 8)), 4)
  expect_equal(geomean(c(0.6, 0.8, 0.95)),
               exp(mean(log(c(0.6, 0.8, 0.95)))))
})

test_that("geomean handles NA via na.rm", {
  expect_equal(geomean(c(1, NA, 4)), 2)
  expect_equal(geomean(c(1, NA, 4), na.rm = FALSE), NA_real_)
  expect_equal(geomean(c(NA, NA)), NA_real_)
})

test_that("geomean handles zeros and negatives", {
  expect_equal(geomean(c(1, 0, 4)), 0)
  expect_warning(out <- geomean(c(-1, 2)), "[Nn]egative")
  expect_true(is.nan(out))
})

test_that("geomean handles empty input", {
  expect_equal(geomean(numeric(0)), NA_real_)
})

test_that("geomean rejects non-numeric input", {
  expect_error(geomean("a"), "must be numeric")
  expect_error(geomean(c(TRUE, FALSE)), "must be numeric")
})

test_that("geomean validates na.rm", {
  expect_error(geomean(c(1, 2), na.rm = NA), "single logical")
  expect_error(geomean(c(1, 2), na.rm = c(TRUE, FALSE)), "single logical")
})
