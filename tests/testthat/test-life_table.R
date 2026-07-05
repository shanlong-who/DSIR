# A typical abridged both-sexes mortality schedule used across tests.
lt_age <- c(0, 1, seq(5, 85, by = 5))
lt_mx  <- c(0.0200, 0.0010, 0.0004, 0.0003, 0.0005, 0.0007, 0.0009,
            0.0012, 0.0016, 0.0022, 0.0032, 0.0048, 0.0075, 0.0120,
            0.0190, 0.0310, 0.0520, 0.0860, 0.1500)

test_that("life_table returns a well-formed table", {
  lt <- life_table(lt_age, lt_mx)
  expect_s3_class(lt, "tbl_df")
  expect_named(lt, c("age", "n", "mx", "ax", "qx", "lx", "dx",
                     "Lx", "Tx", "ex"))
  expect_equal(nrow(lt), length(lt_age))
  expect_equal(lt$age, lt_age)
  expect_equal(lt$mx, lt_mx)
  expect_equal(lt$n, c(diff(lt_age), Inf))
})

test_that("life_table satisfies the standard identities", {
  lt <- life_table(lt_age, lt_mx)

  # lx starts at the radix and never increases
  expect_equal(lt$lx[1], 1e5)
  expect_true(all(diff(lt$lx) <= 0))

  # dx are the lx decrements; the open interval absorbs the remainder
  expect_equal(lt$dx[-nrow(lt)], -diff(lt$lx))
  expect_equal(lt$dx[nrow(lt)], lt$lx[nrow(lt)])
  expect_equal(sum(lt$dx), 1e5)

  # Tx is the reverse cumulative sum of Lx, and ex = Tx / lx
  expect_equal(lt$Tx, rev(cumsum(rev(lt$Lx))))
  expect_equal(lt$ex, lt$Tx / lt$lx)

  # e0 is also total person-years over the radix
  expect_equal(lt$ex[1], sum(lt$Lx) / 1e5)

  # Open interval: qx = 1 and ex = 1 / mx under the default ax
  k <- nrow(lt)
  expect_equal(lt$qx[k], 1)
  expect_equal(lt$ex[k], 1 / lt$mx[k])

  # e0 is plausible for this schedule
  expect_true(lt$ex[1] > 60 && lt$ex[1] < 85)
})

test_that("life_table qx follows the mx-to-qx conversion", {
  lt <- life_table(lt_age, lt_mx)
  n  <- c(diff(lt_age), Inf)
  closed <- seq_len(nrow(lt) - 1L)
  expect_equal(
    lt$qx[closed],
    n[closed] * lt_mx[closed] / (1 + (n[closed] - lt$ax[closed]) * lt_mx[closed])
  )
})

test_that("life_table uses Coale-Demeny West infant/child ax by sex", {
  m0 <- lt_mx[1]  # 0.02 < 0.107, so the low-mortality formulas apply
  lt_m <- life_table(lt_age, lt_mx, sex = "male")
  lt_f <- life_table(lt_age, lt_mx, sex = "female")
  lt_t <- life_table(lt_age, lt_mx)

  expect_equal(lt_m$ax[1], 0.045 + 2.684 * m0)
  expect_equal(lt_f$ax[1], 0.053 + 2.800 * m0)
  expect_equal(lt_t$ax[1], (lt_m$ax[1] + lt_f$ax[1]) / 2)

  expect_equal(lt_m$ax[2], 1.651 - 2.816 * m0)
  expect_equal(lt_f$ax[2], 1.522 - 1.518 * m0)

  # Other closed intervals use the midpoint
  expect_equal(lt_t$ax[3], 2.5)

  # The sex choice must actually flow through to e0
  expect_false(identical(lt_m$ex[1], lt_f$ex[1]))
})

test_that("life_table applies the high-mortality Coale-Demeny branch", {
  mx_high <- lt_mx
  mx_high[1] <- 0.12  # m0 >= 0.107
  lt <- life_table(lt_age, mx_high, sex = "male")
  expect_equal(lt$ax[1], 0.330)
  expect_equal(lt$ax[2], 1.352)
})

test_that("life_table accepts a user ax override with NA fallback", {
  ax <- rep(NA_real_, length(lt_age))
  ax[3] <- 1.9
  lt  <- life_table(lt_age, lt_mx, ax = ax)
  lt0 <- life_table(lt_age, lt_mx)
  expect_equal(lt$ax[3], 1.9)
  expect_equal(lt$ax[-3], lt0$ax[-3])
})

test_that("life_table radix scales lx linearly", {
  lt1 <- life_table(lt_age, lt_mx, radix = 1)
  lt5 <- life_table(lt_age, lt_mx)
  expect_equal(lt1$lx * 1e5, lt5$lx)
  expect_equal(lt1$ex, lt5$ex)  # expectancy is radix-invariant
  expect_equal(lt1$lx[1], 1)
})

test_that("life_table works for single-year and partial tables", {
  # Single-year ages with a constant hazard and midpoint ax
  m  <- 0.01
  lt <- life_table(0:10, rep(m, 11), ax = rep(0.5, 11))
  expect_equal(unique(round(lt$qx[-11], 10)),
               round(m / (1 + 0.5 * m), 10))

  # A table starting above age 0 (remaining life expectancy at 60)
  lt60 <- life_table(seq(60, 85, by = 5), tail(lt_mx, 6))
  expect_equal(lt60$lx[1], 1e5)
  full <- life_table(lt_age, lt_mx)
  # Same mx schedule from 60 up, so ex at 60 agrees with the full table
  expect_equal(lt60$ex[1], full$ex[full$age == 60])
})

test_that("life_table caps qx at 1 with a warning", {
  mx_bad <- lt_mx
  mx_bad[10] <- 5  # implies qx > 1 in a 5-year group
  expect_warning(lt <- life_table(lt_age, mx_bad), "capped")
  expect_true(all(lt$qx <= 1))
  # Survivorship is extinguished at the capped group...
  expect_equal(lt$lx[11], 0)
  # ...and ex is NA once lx reaches 0
  expect_true(all(is.na(lt$ex[lt$lx == 0])))
  expect_false(anyNA(lt$ex[lt$lx > 0]))
})

test_that("life_table warns when the open-interval mx is zero", {
  mx0 <- lt_mx
  mx0[length(mx0)] <- 0
  expect_warning(lt <- life_table(lt_age, mx0), "open interval")
  expect_true(all(is.na(lt$ex)))
})

test_that("life_table validates inputs", {
  expect_error(life_table("a", 1:2), "must be numeric")
  expect_error(life_table(c(0, 5), "a"), "must be numeric")
  expect_error(life_table(c(0, 5), c(0.1, 0.2, 0.3)), "same length")
  expect_error(life_table(0, 0.1), "two age groups")
  expect_error(life_table(c(0, 5, 5), c(0.1, 0.2, 0.3)),
               "strictly increasing")
  expect_error(life_table(c(0, NA), c(0.1, 0.2)), "missing")
  expect_error(life_table(c(0, 5), c(0.1, NA)), "missing")
  expect_error(life_table(c(0, 5), c(0.1, Inf)), "missing or non-finite")
  expect_error(life_table(c(0, 5), c(-0.1, 0.2)), "non-negative")
  expect_error(life_table(c(0, 5), c(0.1, 0.2), radix = 0), "positive")
  expect_error(life_table(c(0, 5), c(0.1, 0.2), ax = c(0.5)),
               "same length")
  expect_error(life_table(c(0, 5), c(0.1, 0.2), sex = "x"))
})
