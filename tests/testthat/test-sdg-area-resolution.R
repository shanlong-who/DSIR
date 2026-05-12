# Most of these test the internal .resolve_area() directly so they run
# offline. One integration test at the bottom confirms end-to-end ISO3
# → SDG plumbing via the live API.

test_that("M49 codes pass through unchanged", {
  expect_equal(DSIR:::.resolve_area("608"), "608")
  expect_equal(DSIR:::.resolve_area(c("608", "250")), c("608", "250"))
  # Zero-padded forms also pass through (Brazil, Afghanistan, …)
  expect_equal(DSIR:::.resolve_area("076"), "076")
})

test_that("ISO3 codes are converted to M49", {
  result <- DSIR:::.resolve_area("PHL")
  expect_length(result, 1L)
  expect_match(result, "^[0-9]+$")
})

test_that("Case-insensitive ISO3 input works", {
  expect_equal(DSIR:::.resolve_area("phl"), DSIR:::.resolve_area("PHL"))
  expect_equal(DSIR:::.resolve_area("Fra"), DSIR:::.resolve_area("FRA"))
})

test_that("Mixed ISO3 and M49 errors", {
  expect_error(DSIR:::.resolve_area(c("PHL", "608")), "mixes")
})

test_that("Invalid format errors", {
  expect_error(DSIR:::.resolve_area("ZZ"),    "Invalid")
  expect_error(DSIR:::.resolve_area("PHLX"),  "Invalid")
  expect_error(DSIR:::.resolve_area("PHL-1"), "Invalid")
})

test_that("Unknown ISO3 warns and drops", {
  expect_warning(
    result <- DSIR:::.resolve_area(c("PHL", "XYZ")),
    "did not match"
  )
  expect_length(result, 1L)
})

test_that("All-unknown ISO3 errors", {
  expect_error(
    suppressWarnings(DSIR:::.resolve_area("XYZ")),
    "No valid area codes"
  )
})

test_that("NULL passes through", {
  expect_null(DSIR:::.resolve_area(NULL))
})

test_that("Empty character vector passes through", {
  result <- DSIR:::.resolve_area(character(0))
  expect_type(result, "character")
  expect_length(result, 0L)
})

test_that("Non-character input errors", {
  expect_error(DSIR:::.resolve_area(123),  "must be a character")
  expect_error(DSIR:::.resolve_area(TRUE), "must be a character")
})

test_that("sdg_data accepts ISO3 directly (network test)", {
  skip_on_cran()
  skip_if_offline()

  result <- sdg_data("3.4.1", area = "PHL")
  expect_s3_class(result, "tbl_df")
  expect_gt(nrow(result), 0L)
  # The server-side area code should be the M49 equivalent
  expect_true(all(result$geoAreaCode == iso3_to_m49("PHL")))
})
