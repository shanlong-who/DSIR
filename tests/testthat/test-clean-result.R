test_that("all cleaners offer S3 and plain outputs without changing the core schema", {
  for (cleaner in list(gho_clean, sdg_clean, ghe_clean)) {
    object <- cleaner(tibble::tibble())
    plain <- cleaner(tibble::tibble(), output = "tibble")
    expect_identical(class(object), c("dsir_data", "tbl_df", "tbl", "data.frame"))
    expect_identical(class(plain), c("tbl_df", "tbl", "data.frame"))
    expect_named(object, names(.dsi_clean_schema()))
    expect_identical(lapply(object, typeof), lapply(plain, typeof))
    expect_identical(dsir_metadata(plain)$layout, "cleaning")
    expect_identical(dsir_metadata(object)$cleaning$input_rows, 0L)
    expect_identical(dsir_metadata(as_dsir_data(plain))$cleaning, dsir_metadata(plain)$cleaning)
    expect_error(cleaner(tibble::tibble(), output = "invalid"), "arg")
  }
})

test_that("cleaning records retention and units without copying raw observations", {
  raw <- tibble::tibble(geoAreaCode = c("608", "418"), timePeriodStart = c(2020, 2021),
    indicator = "3.4.1", series = "EXAMPLE", value = c("10", "20"),
    dimensions = data.frame(Sex = c("FEMALE", "MALE"), Age = "ALLAGE"),
    attributes = data.frame(Units = "PERCENT"))
  raw <- .dsi_record(raw, "sdg", "unsdg", "https://example.test/data",
    retrieved_at = "2020-01-01T00:00:00Z", complete = TRUE)
  compact <- sdg_clean(raw)
  plain <- sdg_clean(raw, output = "tibble")
  metadata <- dsir_metadata(compact)
  expect_identical(metadata$sources, dsir_metadata(raw)$sources)
  expect_identical(dsir_metadata(plain)$sources, metadata$sources)
  expect_identical(metadata$cleaning$function_name, "sdg_clean")
  expect_match(metadata$cleaning$cleaned_at, "T.*Z$")
  expect_false(identical(metadata$cleaning$cleaned_at, metadata$sources$retrieved_at))
  expect_identical(metadata$cleaning$package_version, as.character(utils::packageVersion("DSIR")))
  fields <- metadata$cleaning$fields
  expect_true(is.na(fields$retained_as[fields$column == "dim_sex"]))
  expect_equal(fields$distinct[fields$column == "dim_sex"], 2L)
  expect_true(is.na(fields$constant[fields$column == "dim_sex"]))
  expect_equal(fields$constant[fields$column == "dim_age"], "ALLAGE")
  expect_equal(fields$constant[fields$column == "attr_units"], "PERCENT")
  expect_false(any(c("dim_sex", "attr_units", "metadata") %in% names(compact)))
  expect_output(print(compact), "Cleaned: sdg_clean")
  expect_identical(summary(compact)$cleaning, metadata$cleaning)
  detailed <- sdg_clean(raw, keep_dimensions = TRUE, keep_metadata = TRUE)
  fields <- dsir_metadata(detailed)$cleaning$fields
  expect_equal(fields$retained_as[fields$column == "dim_sex"], "dim_sex")
  expect_equal(fields$retained_as[fields$column == "attr_units"], "attr_units")
  file <- tempfile(fileext = ".rds")
  saveRDS(compact, file)
  expect_identical(readRDS(file), compact)
})

test_that("current coverage changes independently of immutable cleaning records", {
  skip_if_not_installed("dplyr")
  raw <- tibble::tibble(geoAreaCode = c("608", "418"), timePeriodStart = c(2020, 2021),
                        value = c("10", "20"))
  x <- sdg_clean(raw)
  selected <- dplyr::filter(x, iso3 == "PHL")
  changed <- dplyr::mutate(selected, value_num = value_num / 100)
  expect_identical(dsir_metadata(changed)$cleaning, dsir_metadata(x)$cleaning)
  expect_identical(dsir_metadata(changed)$current$rows, 1L)
  expect_identical(dsir_metadata(changed)$processing$semantics, "needs_review")
  expect_true("value_num" %in% dsir_metadata(changed)$processing$review_columns)
})
