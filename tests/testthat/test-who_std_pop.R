test_that("who_std_pop has the expected shape and columns", {
  expect_s3_class(who_std_pop, "tbl_df")
  expect_equal(nrow(who_std_pop), 21L)
  expect_named(who_std_pop,
               c("age_group", "age_start", "weight", "std_million"))
  expect_type(who_std_pop$age_group, "character")
  expect_type(who_std_pop$age_start, "integer")
  expect_type(who_std_pop$weight, "double")
  expect_type(who_std_pop$std_million, "integer")
  expect_false(anyNA(who_std_pop))
})

test_that("who_std_pop age groups run from 0-4 to 100+", {
  expect_equal(who_std_pop$age_group[1], "0-4")
  expect_equal(who_std_pop$age_group[21], "100+")
  expect_equal(who_std_pop$age_start, c(seq(0L, 100L, by = 5L)))
  expect_true(all(diff(who_std_pop$age_start) == 5L))
})

test_that("who_std_pop totals match the published sources", {
  # The published WHO percentages sum to 100.035 (verbatim from Ahmad et
  # al. 2001, Table 4); the SEER standard million sums to exactly 1e6.
  expect_equal(sum(who_std_pop$weight), 100.035)
  expect_equal(sum(who_std_pop$std_million), 1000000L)
})

test_that("who_std_pop carries the published anchor values", {
  w <- setNames(who_std_pop$weight, who_std_pop$age_group)
  expect_equal(unname(w["0-4"]),   8.86)
  expect_equal(unname(w["50-54"]), 5.37)
  expect_equal(unname(w["85-89"]), 0.44)
  expect_equal(unname(w["100+"]),  0.005)

  m <- setNames(who_std_pop$std_million, who_std_pop$age_group)
  expect_equal(unname(m["0-4"]),   88569L)
  expect_equal(unname(m["90-94"]), 1500L)  # SEER's rounding adjustment
  expect_equal(unname(m["100+"]),  50L)
})

test_that("who_std_pop weight and std_million are proportional", {
  # Same relative weights (up to the documented 90-94 rounding), so both
  # columns standardize identically for practical purposes.
  ratio <- who_std_pop$std_million / who_std_pop$weight
  expect_true(max(ratio) / min(ratio) - 1 < 5e-3)
})
