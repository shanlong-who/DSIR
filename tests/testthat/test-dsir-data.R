dsir_test_clean <- function(output = "dsir_data") {
  raw <- tibble::tibble(
    IndicatorCode = "EXAMPLE", IndicatorName = "Example indicator",
    SpatialDim = c("PHL", "PHL", "LAO", "LAO"),
    TimeDim = c(2020L, 2020L, 2021L, 2021L),
    Value = c("10", "12", "20", "22"), NumericValue = c(10, 12, 20, 22),
    Low = c(8, 10, 18, 20), High = c(12, 14, 22, 24),
    Dim1 = rep(c("SEX_MLE", "SEX_FMLE"), 2), Dim1Type = "SEX", Unit = "percent"
  )
  attr(raw, "who_provenance") <- list(backend = "legacy", complete = TRUE, rows = 4L,
    retrieved = "2026-10-30 00:00:00", query_url = "https://example.test/EXAMPLE")
  gho_clean(raw, keep_dimensions = TRUE, keep_metadata = TRUE, output = output)
}

test_that("explicit conversion preserves columns and separates historical provenance", {
  clean <- dsir_test_clean(output = "tibble")
  origin <- attr(clean, "who_provenance")
  x <- as_dsir_data(clean)
  expect_identical(class(x), c("dsir_data", "tbl_df", "tbl", "data.frame"))
  expect_identical(names(x), names(clean))
  for (field in names(clean)) expect_identical(x[[field]], clean[[field]])
  expect_identical(dsir_metadata(x)$provenance$retrieval, origin)
  expect_null(attr(x, "who_provenance", exact = TRUE))
  expect_identical(as_dsir_data(x), x)
  expect_identical(dsir_metadata(x)$processing$semantics, "as_supplied")
  expect_error(as_dsir_data(tibble::tibble(x = 1)), "Missing cleaned-schema")
  expect_error(as_dsir_data(1), "data frame")
  bad <- clean
  bad$year <- as.character(bad$year)
  expect_error(as_dsir_data(bad), "types")
  expect_identical(dsir_metadata(clean)$layout, "cleaning")
  expect_error(dsir_metadata(tibble::as_tibble(x)), "no supported")
})

test_that("cleaners default to S3 while bind_indicators returns an ordinary tibble", {
  expect_s3_class(dsir_test_clean(), "dsir_data")
  s <- sdg_clean(tibble::tibble(geoAreaCode = "608", timePeriodStart = 2020,
                               indicator = list("3.4.1"), value = "10"))
  g <- ghe_clean(.ghe_empty(), keep_dimensions = TRUE)
  expect_s3_class(s, "dsir_data")
  expect_s3_class(g, "dsir_data")
  expect_s3_class(as_dsir_data(s), "dsir_data")
  expect_s3_class(as_dsir_data(g), "dsir_data")
  expect_length(dsir_metadata(as_dsir_data(s))$provenance$retrieval, 0L)
  bound <- bind_indicators(as_dsir_data(dsir_test_clean()), as_dsir_data(s))
  expect_false(inherits(bound, "dsir_data"))
  expect_null(attr(bound, "dsir_metadata", exact = TRUE))
  expect_true(all(c("unit", "dim1_type", "provider") %in% names(bound)))
})

test_that("row operations report current coverage without changing extraction history", {
  skip_if_not_installed("dplyr", "1.1.0")
  x <- as_dsir_data(dsir_test_clean())
  origin <- dsir_metadata(x)$provenance
  out <- dplyr::filter(x, iso3 == "PHL")
  expect_s3_class(out, "dsir_data")
  expect_identical(dsir_metadata(out)$current$countries, "PHL")
  expect_identical(dsir_metadata(out)$current$rows, 2L)
  expect_identical(dsir_metadata(out)$input$rows, 4L)
  expect_identical(dsir_metadata(out)$provenance, origin)
  expect_identical(dsir_metadata(out)$processing$row_scope, "subset")
  ordered <- dplyr::arrange(x, dplyr::desc(year))
  expect_s3_class(ordered, "dsir_data")
  expect_identical(dsir_metadata(ordered)$processing$semantics, "as_supplied")
  expect_identical(ordered$year, sort(x$year, decreasing = TRUE))
  expect_identical(dsir_metadata(x[1, ])$current$rows, 1L)
  expect_identical(dsir_metadata(x[c(1, 1, 1, 1), ])$processing$row_scope, "subset")
})

test_that("mutate preserves valid data and marks derived fields without borrowing units", {
  skip_if_not_installed("dplyr", "1.1.0")
  x <- as_dsir_data(dsir_test_clean())
  out <- dplyr::mutate(x, flag.high = value_num > 15, value.log = log(value_num))
  expect_s3_class(out, "dsir_data")
  metadata <- dsir_metadata(out)
  expect_identical(metadata$processing$state, "derived")
  expect_identical(metadata$processing$semantics, "as_supplied")
  expect_true(all(metadata$fields$origin[metadata$fields$column %in% c("flag.high", "value.log")] == "derived"))
  expect_identical(out$unit, x$unit)
  expect_identical(out$value_num, x$value_num)
  expect_identical(metadata$provenance, dsir_metadata(x)$provenance)
  expect_identical(dsir_metadata(dplyr::mutate(x, value_num = value_num))$processing,
                   dsir_metadata(x)$processing)
  by <- dplyr::mutate(x, group.mean = mean(value_num), .by = iso3)
  expect_s3_class(by, "dsir_data")
  expect_equal(by$group.mean[by$iso3 == "PHL"], rep(11, 2))
})

test_that("changing source values flags units bounds labels and identities for review", {
  skip_if_not_installed("dplyr", "1.1.0")
  x <- as_dsir_data(dsir_test_clean())
  out <- dplyr::mutate(x, value_num = value_num / 100)
  expect_s3_class(out, "dsir_data")
  processing <- dsir_metadata(out)$processing
  expect_identical(processing$semantics, "needs_review")
  expect_identical(processing$modified_columns, "value_num")
  expect_true(all(c("value", "value_num", "low", "high", "unit") %in% processing$review_columns))
  expect_identical(out$low, x$low)
  expect_identical(out$value, x$value)
  expect_identical(dsir_metadata(out)$provenance, dsir_metadata(x)$provenance)
  out <- dplyr::mutate(x, dim1 = "SEX_UNKNOWN")
  expect_identical(dsir_metadata(out)$processing$semantics, "needs_review")
  expect_true("dim1_type" %in% dsir_metadata(out)$processing$review_columns)
  expect_identical(dsir_metadata(dplyr::filter(out, iso3 == "PHL"))$processing$semantics, "needs_review")
})

test_that("selection and replacement enforce the same schema and metadata contract", {
  skip_if_not_installed("dplyr", "1.1.0")
  x <- as_dsir_data(dsir_test_clean())
  expect_s3_class(dplyr::select(x, dplyr::everything()), "dsir_data")
  expect_s3_class(dplyr::relocate(x, year), "dsir_data")
  for (out in list(dplyr::select(x, iso3, value_num),
                   dplyr::rename(x, country = iso3),
                   dplyr::mutate(x, year = as.character(year)),
                   dplyr::mutate(x, value_num = NULL))) {
    expect_s3_class(out, "tbl_df")
    expect_false(inherits(out, "dsir_data"))
    expect_null(attr(out, "dsir_metadata", exact = TRUE))
  }
  out <- dplyr::select(x, -unit)
  expect_s3_class(out, "dsir_data")
  expect_identical(dsir_metadata(out)$processing$semantics, "needs_review")
  expect_true("unit" %in% dsir_metadata(out)$processing$removed_columns)
  for (method in c("dollar", "double", "single", "nested")) {
    out <- x
    if (method == "dollar") out$value_num <- out$value_num / 100
    if (method == "double") out[["value_num"]] <- out$value_num / 100
    if (method == "single") out[1, "value_num"] <- 100
    if (method == "nested") out$value_num[1] <- 100
    expect_s3_class(out, "dsir_data")
    expect_identical(dsir_metadata(out)$processing$semantics, "needs_review")
  }
})

test_that("joins grouping and binding cannot attribute new data to the first input", {
  skip_if_not_installed("dplyr", "1.1.0")
  x <- as_dsir_data(dsir_test_clean())
  plain <- tibble::as_tibble(x)
  lookup <- tibble::tibble(iso3 = c("PHL", "LAO"), external = 1:2)
  for (out in list(dplyr::left_join(x, lookup, by = "iso3"),
                   dplyr::bind_rows(x, x), dplyr::bind_rows(x, plain),
                   dplyr::bind_rows(plain, x), vctrs::vec_rbind(x, x),
                   rbind(x, x), cbind(x, auxiliary = 1),
                   dplyr::summarise(x, average = mean(value_num), .by = iso3),
                   dplyr::group_by(x, iso3), dplyr::rowwise(x),
                   tibble::as_tibble(x), as.data.frame(x))) {
    expect_false(inherits(out, "dsir_data"))
    expect_null(attr(out, "dsir_metadata", exact = TRUE))
    expect_null(attr(out, "who_provenance", exact = TRUE))
  }
})

test_that("summary and printing use current rows and work for empty data offline", {
  x <- as_dsir_data(dsir_test_clean())
  testthat::local_mocked_bindings(.dsi_request = function(...) stop("No network"), .package = "DSIR")
  out <- summary(x[1, ])
  expect_s3_class(out, "summary_dsir_data")
  expect_identical(out$current$rows, 1L)
  expect_identical(out$current$countries, x$iso3[1])
  expect_identical(out$current$years, x$year[1])
  expect_identical(out$provenance, dsir_metadata(x)$provenance)
  expect_output(print(x), "<dsir_data>")
  expect_output(print(out), "Current coverage")
  empty <- as_dsir_data(.dsi_empty_clean())
  expect_identical(summary(empty)$current$rows, 0L)
  expect_length(summary(empty)$current$years, 0L)
  expect_true(all(summary(empty)$missing$n_missing == 0L))
  expect_output(print(summary(empty)), "0 rows")
  x$value_num <- c(NA_real_, Inf, NaN, 1)
  expect_identical(summary(x)$numeric, list(n_missing = 2L, n_nonfinite = 1L))
})

test_that("RDS keeps metadata and methods without resetting processing state", {
  x <- as_dsir_data(dsir_test_clean())
  x$value_num <- x$value_num / 100
  file <- withr::local_tempfile(fileext = ".rds")
  saveRDS(x, file)
  out <- readRDS(file)
  expect_identical(out, x)
  expect_identical(dsir_metadata(as_dsir_data(out))$processing$semantics, "needs_review")
})

test_that("snapshots distinguish unchanged input from transformed DSIR data", {
  clean <- dsir_test_clean(output = "tibble")
  clean$spatial_type <- "COUNTRY"
  clean$time_type <- "YEAR"
  x <- as_dsir_data(clean)
  original <- data_snapshot(clean)
  converted <- data_snapshot(x)
  expect_identical(converted$data, original$data)
  expect_identical(converted$provenance, original$provenance)
  expect_error(data_snapshot(x[1, ]), "explicit.*scope")
  x$value_num <- x$value_num / 100
  expect_error(data_snapshot(x), "metadata needs review")
})
