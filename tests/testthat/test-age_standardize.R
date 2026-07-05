test_that("age_standardize computes the direct standardized rate", {
  # Equal age-specific rates: standardized rate equals the common rate
  expect_equal(age_standardize(c(10, 20), c(1000, 2000), c(1, 1)),
               0.01 * 1e5)

  # Hand-computed two-group example
  deaths <- c(10, 40)
  pop    <- c(1000, 2000)
  w      <- c(2, 1)
  dsr    <- (2 / 3) * 0.01 + (1 / 3) * 0.02
  expect_equal(age_standardize(deaths, pop, w), dsr * 1e5)
})

test_that("age_standardize normalises stdpop internally", {
  deaths <- c(20, 15, 40)
  pop    <- c(12000, 11000, 9000)
  w      <- c(0.5, 0.3, 0.2)
  # Percent, standard-million, and proportion forms all agree
  expect_equal(age_standardize(deaths, pop, w * 100),
               age_standardize(deaths, pop, w))
  expect_equal(age_standardize(deaths, pop, w * 1e6),
               age_standardize(deaths, pop, w))
})

test_that("age_standardize respects per", {
  deaths <- c(10, 20)
  pop    <- c(1000, 2000)
  w      <- c(1, 1)
  expect_equal(age_standardize(deaths, pop, w, per = 1),
               age_standardize(deaths, pop, w) / 1e5)
  expect_equal(age_standardize(deaths, pop, w, per = 1000),
               age_standardize(deaths, pop, w) / 100)
})

test_that("age_standardize handles NA via na.rm", {
  deaths <- c(10, NA, 20)
  pop    <- c(1000, 2000, 2000)
  w      <- c(1, 1, 1)
  expect_equal(age_standardize(deaths, pop, w),
               age_standardize(c(10, 20), c(1000, 2000), c(1, 1)))
  expect_equal(age_standardize(deaths, pop, w, na.rm = FALSE), NA_real_)
})

test_that("age_standardize warns and returns NA on empty input", {
  expect_warning(out <- age_standardize(numeric(0), numeric(0), numeric(0)),
                 "[Nn]o age groups")
  expect_equal(out, NA_real_)
  expect_warning(
    out2 <- age_standardize(NA_real_, 100, 1),
    "[Nn]o age groups"
  )
  expect_equal(out2, NA_real_)
})

test_that("age_standardize validates inputs", {
  expect_error(age_standardize("a", 1, 1), "must be numeric")
  expect_error(age_standardize(1, "a", 1), "must be numeric")
  expect_error(age_standardize(1, 1, "a"), "must be numeric")
  expect_error(age_standardize(c(1, 2), 1, 1), "same length")
  expect_error(age_standardize(1, 1, 1, per = -1), "positive")
  expect_error(age_standardize(1, 1, 1, per = c(1, 2)), "positive")
  expect_error(age_standardize(1, 1, 1, na.rm = NA), "single logical")
  expect_error(age_standardize(1, 1, 1, ci = NA), "single logical")
  expect_error(age_standardize(1, 1, 1, conf_level = 1.5), "in \\(0, 1\\)")
  expect_error(age_standardize(-1, 100, 1), "non-negative")
  expect_error(age_standardize(1, 0, 1), "positive")
  expect_error(age_standardize(1, 100, -1), "non-negative")
})

test_that("age_standardize warns on all-zero stdpop", {
  expect_warning(out <- age_standardize(c(1, 2), c(10, 20), c(0, 0)),
                 "zero")
  expect_equal(out, NA_real_)
})

test_that("age_standardize ci returns a Fay-Feuer gamma interval", {
  deaths <- c(20, 15, 40, 90, 220)
  pop    <- c(12000, 11000, 9000, 7000, 3000)
  w      <- c(0.35, 0.25, 0.20, 0.12, 0.08)

  out <- age_standardize(deaths, pop, w, ci = TRUE)
  expect_named(out, c("rate", "lower", "upper"))
  expect_true(out["lower"] < out["rate"])
  expect_true(out["rate"] < out["upper"])
  expect_equal(unname(out["rate"]), age_standardize(deaths, pop, w))

  # Independent recomputation of the Fay-Feuer bounds
  wn      <- w / sum(w)
  dsr     <- sum(wn * deaths / pop)
  dsr_var <- sum(wn^2 * deaths / pop^2)
  wm      <- max(wn / pop)
  lower   <- dsr_var / dsr * qgamma(0.025, shape = dsr^2 / dsr_var)
  upper   <- (dsr_var + wm^2) / (dsr + wm) *
    qgamma(0.975, shape = (dsr + wm)^2 / (dsr_var + wm^2))
  expect_equal(unname(out["lower"]), lower * 1e5)
  expect_equal(unname(out["upper"]), upper * 1e5)
})

test_that("age_standardize ci respects conf_level", {
  deaths <- c(20, 15, 40)
  pop    <- c(12000, 11000, 9000)
  w      <- c(0.5, 0.3, 0.2)
  ci95 <- age_standardize(deaths, pop, w, ci = TRUE)
  ci80 <- age_standardize(deaths, pop, w, ci = TRUE, conf_level = 0.80)
  # A narrower confidence level gives a narrower interval
  expect_true(ci80["lower"] > ci95["lower"])
  expect_true(ci80["upper"] < ci95["upper"])
})

test_that("age_standardize ci is NA with zero events", {
  expect_warning(
    out <- age_standardize(c(0, 0), c(100, 200), c(1, 1), ci = TRUE),
    "undefined"
  )
  expect_equal(unname(out["rate"]), 0)
  expect_equal(unname(out["lower"]), NA_real_)
  expect_equal(unname(out["upper"]), NA_real_)
})

test_that("age_standardize works with who_std_pop weights", {
  # 21 age groups matching who_std_pop; a flat rate schedule must return
  # the flat rate regardless of the standard used.
  rate <- 0.003
  pop  <- rep(10000, 21)
  deaths <- pop * rate
  expect_equal(
    age_standardize(deaths, pop, who_std_pop$std_million),
    rate * 1e5
  )
  expect_equal(
    age_standardize(deaths, pop, who_std_pop$weight),
    age_standardize(deaths, pop, who_std_pop$std_million)
  )
})
