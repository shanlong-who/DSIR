test_that("sdg_indicators(NULL) returns the full unfiltered list", {
  skip_on_cran()
  skip_if_offline()

  out <- sdg_indicators()
  expect_s3_class(out, "tbl_df")
  expect_true("description" %in% names(out))
  expect_gt(nrow(out), 200L)
})

test_that("sdg_indicators filters on a single term (case-insensitive substring)", {
  skip_on_cran()
  skip_if_offline()

  out <- sdg_indicators("mortality")
  expect_s3_class(out, "tbl_df")
  expect_gt(nrow(out), 0L)
  expect_true(all(grepl("mortality", tolower(out$description), fixed = TRUE)))

  # Same result regardless of input case
  out_upper <- sdg_indicators("MORTALITY")
  expect_identical(out, out_upper)
})

test_that("sdg_indicators applies AND semantics on a whitespace-split string", {
  skip_on_cran()
  skip_if_offline()

  out <- sdg_indicators("mortality cancer")
  expect_s3_class(out, "tbl_df")
  expect_gt(nrow(out), 0L)
  expect_true(all(grepl("mortality", tolower(out$description), fixed = TRUE)))
  expect_true(all(grepl("cancer",    tolower(out$description), fixed = TRUE)))

  # Stricter than the single-term result
  single <- sdg_indicators("mortality")
  expect_lte(nrow(out), nrow(single))
})

test_that("sdg_indicators accepts a character vector as terms (AND)", {
  skip_on_cran()
  skip_if_offline()

  out <- sdg_indicators(c("maternal", "mortality"))
  expect_s3_class(out, "tbl_df")
  expect_gt(nrow(out), 0L)
  expect_true(all(grepl("maternal",
                        tolower(out$description), fixed = TRUE)))
  expect_true(all(grepl("mortality",
                        tolower(out$description), fixed = TRUE)))
})

test_that("sdg_indicators treats whitespace inside a vector element as part of the term", {
  skip_on_cran()
  skip_if_offline()

  # An element with internal whitespace is matched verbatim — not split
  # into separate terms — so this is stricter than the single-term call.
  out <- sdg_indicators(c("mortality rate", "attributed"))
  expect_s3_class(out, "tbl_df")
  expect_gt(nrow(out), 0L)
  expect_true(all(grepl("mortality rate",
                        tolower(out$description), fixed = TRUE)))
  expect_true(all(grepl("attributed",
                        tolower(out$description), fixed = TRUE)))
})

test_that("sdg_indicators returns an empty tibble (correct shape) on no match", {
  skip_on_cran()
  skip_if_offline()

  full <- sdg_indicators()
  out  <- sdg_indicators("zzzzzzzzz-no-such-thing")
  expect_s3_class(out, "tbl_df")
  expect_equal(nrow(out), 0L)
  expect_identical(names(out), names(full))
})

test_that("sdg_indicators handles search terms containing a single quote", {
  skip_on_cran()
  skip_if_offline()

  # Should not error — filter is client-side, fixed = TRUE
  out <- sdg_indicators("women's")
  expect_s3_class(out, "tbl_df")
})

test_that("sdg_indicators validates the search argument", {
  expect_error(sdg_indicators(search = 1L))
  expect_error(sdg_indicators(search = NA_character_))
  expect_error(sdg_indicators(search = ""))
  expect_error(sdg_indicators(search = character()))
})
