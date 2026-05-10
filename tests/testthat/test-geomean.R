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
  expect_error(geomean(factor(c("a", "b"))), "must be numeric")
})

test_that("geomean coerces logical input", {
  # TRUE = 1, FALSE = 0; geomean of (1, 0) = 0 due to zero
  expect_equal(geomean(c(TRUE, FALSE)), 0)
  # All TRUE = all 1s; geomean = 1
  expect_equal(geomean(c(TRUE, TRUE, TRUE)), 1)
  # NA_logical coerced to NA_real_, removed by na.rm
  expect_equal(geomean(c(TRUE, NA, TRUE)), 1)
})

test_that("geomean handles all-NA input", {
  expect_equal(geomean(c(NA_real_, NA_real_)), NA_real_)
  expect_equal(geomean(c(NA, NA)), NA_real_)  # logical NA, coerced
})

test_that("geomean validates na.rm", {
  expect_error(geomean(c(1, 2), na.rm = NA), "single logical")
  expect_error(geomean(c(1, 2), na.rm = c(TRUE, FALSE)), "single logical")
})

test_that("geomean computes weighted geometric mean", {
  expect_equal(geomean(c(1, 4, 16), w = c(1, 1, 1)), 4)
  expect_equal(geomean(c(1, 100), w = c(1, 0)), 1)
})

test_that("geomean validates weight inputs", {
  expect_error(geomean(c(1, 2), w = c(1, -1)))
  expect_error(geomean(c(1, 2), w = c(1, 2, 3)))
})

test_that("geomean handles NA in weights", {
  expect_equal(
    geomean(c(1, 2, 4), w = c(1, NA, 1)),
    sqrt(1 * 4)
  )
})