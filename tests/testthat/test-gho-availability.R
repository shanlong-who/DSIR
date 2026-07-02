test_that("gho_has_data returns TRUE when data exist for the filter", {
  skip_on_cran()
  skip_if_offline()

  expect_true(gho_has_data("WHOSIS_000001", area = "FRA"))
})

test_that("gho_has_data returns FALSE when the server returns no rows", {
  skip_on_cran()
  skip_if_offline()

  # "ZZZ" is a reserved ISO3 code never assigned to a country, so the
  # GHO server returns an empty result (200 OK, value = []).
  expect_false(gho_has_data("WHOSIS_000001", area = "ZZZ"))
})

test_that("gho_has_data returns NA on request failure", {
  skip_on_cran()
  skip_if_offline()

  # A non-existent indicator code triggers HTTP 404 from the GHO server,
  # which we treat as a request failure -> NA.
  res <- suppressWarnings(gho_has_data("THIS_INDICATOR_DOES_NOT_EXIST_XYZ"))
  expect_true(is.na(res))
})

test_that("gho_has_data infers country when area given without spatial_type", {
  skip_on_cran()
  skip_if_offline()

  expect_message(
    gho_has_data("WHOSIS_000001", area = "FRA"),
    regexp = "country"
  )
})

test_that("gho_count returns an integer for valid filters", {
  skip_on_cran()
  skip_if_offline()

  n <- gho_count("WHOSIS_000001", area = "FRA")
  expect_type(n, "integer")
  expect_length(n, 1L)
  expect_gt(n, 0L)
})

test_that("gho_count returns 0L when no rows match", {
  skip_on_cran()
  skip_if_offline()

  expect_identical(gho_count("WHOSIS_000001", area = "ZZZ"), 0L)
})

test_that("the GHO server accepts Dim1 'in' filters (dim1 argument)", {
  skip_on_cran()
  skip_if_offline()

  # NCDMORT3070 carries a sex breakdown in Dim1 (SEX_BTSX / SEX_MLE /
  # SEX_FMLE). The offline tests only assert URL construction; this
  # guards against the server rejecting or ignoring the filter, which
  # the fail-soft design would otherwise hide as NA / 0.
  expect_true(gho_has_data("NCDMORT3070", spatial_type = "country",
                           area = "PHL", dim1 = "SEX_BTSX"))

  n_btsx <- gho_count("NCDMORT3070", spatial_type = "country",
                      area = "PHL", dim1 = "SEX_BTSX")
  n_all  <- gho_count("NCDMORT3070", spatial_type = "country",
                      area = "PHL")
  expect_gt(n_btsx, 0L)
  expect_lt(n_btsx, n_all)
})

test_that("gho_coverage returns the documented 4-column shape", {
  skip_on_cran()
  skip_if_offline()

  out <- gho_coverage("WHOSIS_000001", area = c("FRA", "DEU", "JPN"))
  expect_s3_class(out, "tbl_df")
  expect_named(out, c("location", "year_min", "year_max", "n_obs"))
  expect_equal(nrow(out), 3L)
  expect_setequal(out$location, c("FRA", "DEU", "JPN"))
  expect_type(out$year_min, "integer")
  expect_type(out$year_max, "integer")
  expect_type(out$n_obs, "integer")
  expect_true(all(out$year_min <= out$year_max))
  expect_true(all(out$n_obs >= 1L))
  # Sorted by location
  expect_equal(out$location, sort(out$location))
})

test_that("gho_coverage returns an empty tibble with correct columns on no match", {
  skip_on_cran()
  skip_if_offline()

  out <- gho_coverage("WHOSIS_000001", area = "ZZZ")
  expect_s3_class(out, "tbl_df")
  expect_named(out, c("location", "year_min", "year_max", "n_obs"))
  expect_equal(nrow(out), 0L)
})
