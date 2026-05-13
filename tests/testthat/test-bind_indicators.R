# Tests for bind_indicators(). Inputs are constructed via gho_clean() /
# sdg_clean() on small fake frames so the tests run offline.

make_gho <- function() {
  gho_clean(tibble::tibble(
    IndicatorCode = "WHOSIS_000001",
    IndicatorName = "Life expectancy",
    SpatialDim    = "FRA",
    TimeDim       = 2019L,
    Value         = "82.5",
    NumericValue  = 82.5
  ))
}

make_sdg <- function() {
  sdg_clean(tibble::tibble(
    indicator       = list("3.4.1"),
    series          = "SH_DTH_NCD",
    seriesDescription = "NCD mortality",
    geoAreaCode     = "608",
    geoAreaName     = "Philippines",
    timePeriodStart = 2019,
    value           = "17.3"
  ))
}

unified_cols <- c(
  "source", "id", "indicator", "location", "iso3", "location_name",
  "year", "value", "value_num", "low", "high", "series",
  "dim1", "dim2", "dim3"
)

test_that("bind_indicators returns the unified 15-column schema", {
  out <- bind_indicators(make_gho(), make_sdg())
  expect_s3_class(out, "tbl_df")
  expect_named(out, unified_cols)
  expect_equal(nrow(out), 2L)
})

test_that("bind_indicators preserves source column", {
  out <- bind_indicators(make_gho(), make_sdg())
  expect_setequal(out$source, c("gho", "sdg"))
})

test_that("bind_indicators preserves input order", {
  out <- bind_indicators(make_gho(), make_sdg())
  expect_equal(out$source, c("gho", "sdg"))
  out2 <- bind_indicators(make_sdg(), make_gho())
  expect_equal(out2$source, c("sdg", "gho"))
})

test_that("bind_indicators accepts a single input", {
  out <- bind_indicators(make_gho())
  expect_equal(nrow(out), 1L)
  expect_equal(out$source, "gho")
})

test_that("bind_indicators ignores NULL arguments", {
  out <- bind_indicators(make_gho(), NULL, make_sdg(), NULL)
  expect_equal(nrow(out), 2L)
  expect_equal(out$source, c("gho", "sdg"))
})

test_that("bind_indicators returns empty schema on no inputs", {
  out <- bind_indicators()
  expect_named(out, unified_cols)
  expect_equal(nrow(out), 0L)
  expect_type(out$year,      "integer")
  expect_type(out$value_num, "double")

  out_null <- bind_indicators(NULL, NULL)
  expect_equal(nrow(out_null), 0L)
})

test_that("bind_indicators rejects non-data-frame input", {
  expect_error(bind_indicators(make_gho(), "not a df"),
               "must be a data frame")
  expect_error(bind_indicators(list(a = 1)),
               "must be a data frame")
})

test_that("bind_indicators rejects unclean input (missing schema cols)", {
  bad <- tibble::tibble(foo = 1, bar = 2)
  expect_error(bind_indicators(make_gho(), bad),
               "missing required column")
})

test_that("bind_indicators tolerates column re-ordering in inputs", {
  reordered <- make_gho()[, rev(names(make_gho()))]
  out <- bind_indicators(reordered, make_sdg())
  expect_named(out, unified_cols)
  expect_equal(nrow(out), 2L)
})
