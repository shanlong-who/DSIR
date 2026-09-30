# Offline tests for preserving and selecting named SDG strata.
dimension_response <- function(body) {
  httr2::response(
    status_code = 200L,
    headers = list(`content-type` = "application/json"),
    body = charToRaw(body)
  )
}

dimension_raw <- function() {
  tibble::tibble(
    indicator = list("3.8.2", "3.8.2", "3.8.2"),
    series = "SH_OOP_XPD_EARNNET40",
    geoAreaCode = c("608", "250", "608"),
    timePeriodStart = c(2023L, 2020L, 2000L),
    value = c("30.99", "<0.1", "33.47"),
    dimensions = data.frame(
      Age = c("ALLAGE", "60+", "ALLAGE"),
      Location = c("ALLAREA", "URBAN", "ALLAREA"),
      Sex = c("BOTHSEX", "FEMALE", "BOTHSEX"),
      `Reporting Type` = "G",
      Quantile = c("_T", "Q1", "_T"),
      Type_of_household = c("_T", "HH_ONLYOLDER", "_T"),
      check.names = FALSE
    )
  )
}

test_that("SDG named dimensions remain aligned after cleaning and sorting", {
  raw <- dimension_raw()
  compact <- sdg_clean(raw)
  out <- sdg_clean(raw, keep_dimensions = TRUE)

  expect_equal(ncol(compact), 15L)
  expect_identical(out[names(compact)], compact)
  expect_named(out, c(
    names(compact), "dim_age", "dim_location", "dim_sex",
    "dim_reporting_type", "dim_quantile", "dim_type_of_household"
  ))
  expect_equal(out$year, c(2020L, 2000L, 2023L))
  expect_equal(out$dim_sex, c("FEMALE", "BOTHSEX", "BOTHSEX"))
  expect_equal(out$dim_quantile, c("Q1", "_T", "_T"))
  expect_equal(out$dim_age, c("60+", "ALLAGE", "ALLAGE"))
  expect_true(all(is.na(out$dim1)))
  expect_equal(out$value, c("<0.1", "33.47", "30.99"))
  expect_true(is.na(out$value_num[[1]]))
})

test_that("cleaning handles missing and list-form SDG dimension records", {
  raw <- dimension_raw()
  raw$dimensions <- list(list(Sex = "FEMALE"), NULL,
                         list(Sex = "MALE", Age = NULL))
  out <- sdg_clean(raw, keep_dimensions = TRUE)
  expect_equal(nrow(out), 3L)
  expect_equal(out$dim_sex, c(NA_character_, "MALE", "FEMALE"))
  expect_identical(out$dim_age, rep(NA_character_, 3))

  raw$dimensions <- NULL
  expect_identical(sdg_clean(raw, keep_dimensions = TRUE), sdg_clean(raw))
})

test_that("zero-row SDG subsets retain known dimension names and types", {
  raw <- dimension_raw()[integer(0), ]
  out <- sdg_clean(raw, keep_dimensions = TRUE)
  expect_equal(nrow(out), 0L)
  expect_equal(ncol(out), 21L)
  expect_type(out$dim_age, "character")
  expect_type(out$year, "integer")
  expect_identical(sdg_clean(tibble::tibble(), keep_dimensions = TRUE),
                   sdg_clean(tibble::tibble()))
})

test_that("invalid dimension retention options and ambiguous names fail clearly", {
  raw <- dimension_raw()
  for (bad in list(NA, "yes", 1, c(TRUE, FALSE), NULL)) {
    expect_error(sdg_clean(raw, keep_dimensions = bad), "single logical")
  }
  raw$dimensions <- data.frame(`A B` = rep("x", 3), `A-B` = rep("y", 3),
                               check.names = FALSE)
  expect_error(sdg_clean(raw, keep_dimensions = TRUE), "not unique")
})

test_that("bind_indicators retains optional dimensions and fills missing fields", {
  raw <- dimension_raw()
  sdg <- sdg_clean(raw, keep_dimensions = TRUE)
  gho <- gho_clean(tibble::tibble(
    SpatialDim = "PHL", TimeDim = 2023L, Dim1 = "COMPONENT_TOTAL"
  ))
  out <- bind_indicators(gho = gho, sdg = sdg)
  expect_equal(nrow(out), 4L)
  expect_equal(out$source, c("gho", "sdg", "sdg", "sdg"))
  expect_equal(out$dim_quantile, c(NA_character_, "Q1", "_T", "_T"))
  expect_equal(out$dim1, c("COMPONENT_TOTAL", rep(NA_character_, 3)))
  expect_identical(names(out)[seq_len(15)], names(gho))

  raw$dimensions <- data.frame(Education = rep("TOTAL", 3))
  other <- sdg_clean(raw, keep_dimensions = TRUE)
  combined <- bind_indicators(sdg, other)
  expect_equal(combined$dim_education, c(rep(NA_character_, 3), rep("TOTAL", 3)))
  expect_equal(combined$dim_quantile, c("Q1", "_T", "_T", rep(NA_character_, 3)))
  expect_identical(names(bind_indicators(gho, sdg[integer(0), ])), names(out))
})

test_that("series and dimension filters run after all pages are downloaded", {
  page1 <- dimension_response(paste0(
    '{"data":[',
    '{"series":"OTHER","timePeriodStart":2023,"value":"99",',
    '"dimensions":{"Sex":"BOTHSEX","Quantile":"_T"}},',
    '{"series":"TARGET","timePeriodStart":2000,"value":"1",',
    '"dimensions":{"Sex":"BOTHSEX","Quantile":"_T"}}',
    '],"totalPages":2}'
  ))
  page2 <- dimension_response(paste0(
    '{"data":[',
    '{"series":"TARGET","timePeriodStart":2023,"value":"2",',
    '"dimensions":{"Sex":"BOTHSEX","Quantile":"_T","Age":"ALLAGE"}},',
    '{"series":"TARGET","timePeriodStart":2023,"value":"3",',
    '"dimensions":{"Sex":"FEMALE","Quantile":"Q1","Age":"60+"}}',
    '],"totalPages":2}'
  ))
  urls <- character()
  pages <- list(page1, page2)
  mock <- function(req) {
    urls <<- c(urls, req$url)
    pages[[length(urls)]]
  }
  out <- httr2::with_mocked_responses(mock, {
    sdg_data("3.8.2", area = "PHL", year_from = 2010,
             series = "TARGET",
             dimensions = list(Sex = c("BOTHSEX", "FEMALE"), Quantile = "_T"))
  })
  expect_length(urls, 2L)
  expect_false(any(grepl("Sex|Quantile|TARGET|timePeriodStart", urls)))
  expect_equal(out$value, "2")
  clean <- sdg_clean(out, keep_dimensions = TRUE)
  expect_equal(clean$dim_age, "ALLAGE")
  expect_equal(clean$dim_quantile, "_T")
})

test_that("missing requested dimensions never return unfiltered observations", {
  page <- dimension_response(paste0(
    '{"data":[{"series":"TARGET","value":"1",',
    '"dimensions":{"Sex":"BOTHSEX"}}],"totalPages":1}'
  ))
  httr2::with_mocked_responses(list(page), {
    expect_warning(out <- sdg_data("3.8.2", dimensions = list(Quantile = "_T")),
                   "not present")
    expect_equal(nrow(out), 0L)
  })
  httr2::with_mocked_responses(list(page), {
    out <- sdg_data("3.8.2", dimensions = list(Sex = "FEMALE"))
    expect_equal(nrow(out), 0L)
    expect_type(sdg_clean(out, keep_dimensions = TRUE)$dim_sex, "character")
  })
})

test_that("unknown and absent values do not acquire implicit total codes", {
  raw <- dimension_raw()
  raw$dimensions$Quantile <- c(NA_character_, "Q1", "_T")
  out <- DSIR:::.sdg_filter_observations(raw, NULL, list(Quantile = "_T"))
  expect_equal(out$timePeriodStart, 2000L)
  expect_equal(nrow(DSIR:::.sdg_filter_observations(raw, "MISSING", NULL)), 0L)
  raw$series <- NULL
  expect_warning(out <- DSIR:::.sdg_filter_observations(raw, "TARGET", NULL),
                 "series.*missing")
  expect_equal(nrow(out), 0L)
})

test_that("invalid filters fail before any network request", {
  for (bad in list("BOTHSEX", list("BOTHSEX"), list(Sex = character()),
                   list(Sex = NA_character_), list(Sex = ""),
                   list(Sex = "MALE", Sex = "FEMALE"))) {
    expect_error(sdg_data("3.8.2", dimensions = bad), "named list")
  }
  for (bad in list(1, character(), NA_character_, "")) {
    expect_error(sdg_data("3.8.2", series = bad), "character vector")
  }
})
