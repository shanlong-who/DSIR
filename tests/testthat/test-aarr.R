# Unit tests for aarr(). All offline — pure computation.

test_that("aarr recovers the exact rate from a perfect exponential decline", {
  years  <- 2000:2015
  values <- 100 * (1 - 0.024) ^ (years - 2000)
  # On perfectly exponential data both methods are exact, which locks
  # the formula (1 - exp(b), NOT -b) and the sign convention forever.
  expect_equal(aarr(years, values), 0.024, tolerance = 1e-10)
  expect_equal(aarr(years, values, method = "endpoint"), 0.024,
               tolerance = 1e-10)
})

test_that("aarr regression matches a hand-computed OLS slope on noisy data", {
  years  <- c(2000, 2005, 2010, 2015)
  values <- c(120, 100, 70, 55)
  b <- stats::coef(stats::lm(log(values) ~ years))[["years"]]
  expect_equal(aarr(years, values), 1 - exp(b))
})

test_that("aarr endpoint uses earliest/latest year regardless of input order", {
  years  <- c(2010, 2000, 2005)
  values <- c(80, 100, 95)
  expect_equal(aarr(years, values, method = "endpoint"),
               1 - (80 / 100) ^ (1 / 10))
})

test_that("an increasing indicator yields a negative aarr", {
  years  <- 2010:2020
  values <- 50 * 1.01 ^ (years - 2010)
  expect_equal(aarr(years, values), 1 - 1.01, tolerance = 1e-10)
  expect_lt(aarr(years, values, method = "endpoint"), 0)
})

test_that("aarr handles missing values per na.rm", {
  years  <- c(2000, 2005, 2010, 2015)
  values <- c(100, NA, 70, 55)
  expect_equal(aarr(years, values),
               aarr(years[-2], values[-2]))
  expect_identical(aarr(years, values, na.rm = FALSE), NA_real_)

  # NA in year is removed pairwise too
  years_na <- c(2000, NA, 2010, 2015)
  expect_equal(aarr(years_na, c(100, 90, 70, 55)),
               aarr(c(2000, 2010, 2015), c(100, 70, 55)))
})

test_that("aarr warns and returns NA on non-finite inputs", {
  # Inf passes both the NA filter and the value <= 0 check; without an
  # explicit guard it would abort inside stats::lm() with an opaque
  # error — fatal in grouped summarise() over many countries.
  expect_warning(out <- aarr(2000:2002, c(100, Inf, 80)), "Non-finite")
  expect_identical(out, NA_real_)
  expect_warning(out <- aarr(c(2000, Inf), c(100, 80)), "Non-finite")
  expect_identical(out, NA_real_)
  expect_warning(
    out <- aarr(2000:2002, c(100, Inf, 80), method = "endpoint"),
    "Non-finite"
  )
  expect_identical(out, NA_real_)
})

test_that("aarr warns and returns NA for zero or negative values", {
  expect_warning(out <- aarr(2000:2002, c(10, 0, 5)), "undefined")
  expect_identical(out, NA_real_)
  expect_warning(out <- aarr(2000:2002, c(10, -1, 5)), "undefined")
  expect_identical(out, NA_real_)
})

test_that("aarr warns and returns NA with fewer than two distinct years", {
  expect_warning(out <- aarr(2020, 55), "two distinct years")
  expect_identical(out, NA_real_)
  expect_warning(out <- aarr(c(2020, 2020), c(55, 60)), "two distinct years")
  expect_identical(out, NA_real_)
  # Empty after NA removal
  expect_warning(out <- aarr(c(NA_real_, NA_real_), c(1, 2)),
                 "two distinct years")
  expect_identical(out, NA_real_)
})

test_that("aarr warns on duplicated years but still computes", {
  # Two strata accidentally pooled: the classic unfiltered-dim1 mistake.
  years  <- c(2000, 2000, 2010, 2010)
  values <- c(90, 110, 60, 80)
  expect_warning(out <- aarr(years, values), "Duplicated years")
  expect_type(out, "double")
  expect_false(is.na(out))

  # Endpoint method averages the values at each endpoint year
  expect_warning(
    out_ep <- aarr(years, values, method = "endpoint"),
    "Duplicated years"
  )
  expect_equal(out_ep, 1 - (70 / 100) ^ (1 / 10))
})

test_that("aarr validates its inputs", {
  expect_error(aarr("2000", 1), "numeric")
  expect_error(aarr(2000:2001, "a"), "numeric")
  expect_error(aarr(2000:2002, c(1, 2)), "length")
  expect_error(aarr(2000:2001, c(1, 2), na.rm = NA), "logical")
  expect_error(aarr(2000:2001, c(1, 2), method = "banana"))
})
