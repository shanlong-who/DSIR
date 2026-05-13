# Tests for the unified 15-column schema produced by gho_clean() and
# sdg_clean(). Uses constructed input frames so the tests run offline.

unified_cols <- c(
  "source", "id", "indicator", "location", "iso3", "location_name",
  "year", "value", "value_num", "low", "high", "series",
  "dim1", "dim2", "dim3"
)

# ── empty / shape ────────────────────────────────────────────────────

test_that("gho_clean returns the 15-col schema on empty input", {
  out <- gho_clean(tibble::tibble())
  expect_s3_class(out, "tbl_df")
  expect_named(out, unified_cols)
  expect_equal(nrow(out), 0L)
  expect_type(out$year,      "integer")
  expect_type(out$value_num, "double")
  expect_type(out$low,       "double")
  expect_type(out$high,      "double")
  expect_type(out$source,    "character")
})

test_that("sdg_clean returns the 15-col schema on empty input", {
  out <- sdg_clean(tibble::tibble())
  expect_s3_class(out, "tbl_df")
  expect_named(out, unified_cols)
  expect_equal(nrow(out), 0L)
})

test_that("gho_clean errors on non-data-frame input", {
  expect_error(gho_clean(NULL),       "must be a data frame")
  expect_error(gho_clean(list(a=1)),  "must be a data frame")
})

test_that("sdg_clean errors on non-data-frame input", {
  expect_error(sdg_clean(NULL),       "must be a data frame")
  expect_error(sdg_clean(list(a=1)),  "must be a data frame")
})

# ── gho_clean: realistic row ─────────────────────────────────────────

test_that("gho_clean maps GHO columns to the unified schema", {
  raw <- tibble::tibble(
    IndicatorCode = c("WHOSIS_000001", "WHOSIS_000001"),
    IndicatorName = c("Life expectancy at birth (years)",
                      "Life expectancy at birth (years)"),
    SpatialDim    = c("FRA", "DEU"),
    SpatialDimType = c("COUNTRY", "COUNTRY"),
    TimeDim       = c(2019, 2019),
    Dim1          = c("BTSX", "MLE"),
    Dim2          = c(NA, NA),
    Dim3          = c(NA, NA),
    Value         = c("82.5", "78.9"),
    NumericValue  = c(82.5, 78.9),
    Low           = c(NA, NA),
    High          = c(NA, NA)
  )
  out <- gho_clean(raw)

  expect_named(out, unified_cols)
  expect_equal(nrow(out), 2L)
  expect_true(all(out$source == "gho"))
  expect_equal(out$id[1],         "WHOSIS_000001")
  expect_equal(out$indicator[1],  "Life expectancy at birth (years)")
  expect_setequal(out$location,   c("FRA", "DEU"))
  expect_equal(out$iso3,          out$location)  # both are valid ISO3
  expect_setequal(out$location_name, c("France", "Germany"))
  expect_type(out$year,           "integer")
  expect_equal(out$value_num,
               c(78.9, 82.5))                    # sorted by location: DEU, FRA
  expect_true(all(is.na(out$series)))
  expect_setequal(out$dim1,       c("BTSX", "MLE"))
})

test_that("gho_clean sets iso3 to NA for non-Member spatial codes", {
  # Region-level GHO data uses codes like 'EUR', 'AMR', 'GLOBAL'
  raw <- tibble::tibble(
    IndicatorCode = c("X", "X"),
    IndicatorName = c("Y", "Y"),
    SpatialDim    = c("EUR", "GLOBAL"),
    TimeDim       = c(2020, 2020),
    Value         = c("1", "2"),
    NumericValue  = c(1, 2)
  )
  out <- gho_clean(raw)
  expect_true(all(is.na(out$iso3)))
  expect_setequal(out$location, c("EUR", "GLOBAL"))
})

# ── gho_clean: location_name resolution ──────────────────────────────

test_that("gho_clean populates location_name for WHO Member States", {
  raw <- tibble::tibble(
    IndicatorCode = c("FAKE_001", "FAKE_001", "FAKE_001"),
    SpatialDim    = c("PHL", "FRA", "USA"),
    TimeDim       = c(2020L, 2020L, 2020L),
    Value         = c("10", "10", "10"),
    NumericValue  = c(10, 10, 10)
  )
  out <- gho_clean(raw)
  expect_false(any(is.na(out$location_name)))
  expect_true("Philippines" %in% out$location_name)
  expect_true("France"      %in% out$location_name)
})

test_that("gho_clean populates location_name for WHO regions and GLOBAL", {
  raw <- tibble::tibble(
    IndicatorCode = c("FAKE_001", "FAKE_001", "FAKE_001"),
    SpatialDim    = c("WPR", "AFR", "GLOBAL"),
    TimeDim       = c(2020L, 2020L, 2020L),
    Value         = c("10", "10", "10"),
    NumericValue  = c(10, 10, 10)
  )
  out <- gho_clean(raw)
  expect_equal(
    sort(out$location_name),
    sort(c("Africa", "Global", "Western Pacific"))
  )
})

test_that("gho_clean returns NA location_name for unknown spatial codes", {
  raw <- tibble::tibble(
    IndicatorCode = c("FAKE_001", "FAKE_001"),
    SpatialDim    = c("XYZ", "ZZ"),
    TimeDim       = c(2020L, 2020L),
    Value         = c("10", "10"),
    NumericValue  = c(10, 10)
  )
  out <- gho_clean(raw)
  expect_true(all(is.na(out$location_name)))
})

test_that("gho_clean fills missing source columns with typed NA", {
  # "NOT_IN_CATALOG" misses the helper-injected catalog, so `indicator`
  # falls back to NA via catalog-miss rather than via a missing source
  # column (the old IndicatorName route — no longer used).
  raw <- tibble::tibble(
    IndicatorCode = "NOT_IN_CATALOG",
    SpatialDim    = "FRA",
    TimeDim       = 2019L
    # Value, NumericValue, Low, High, Dim1-3 all absent
  )
  out <- gho_clean(raw)
  expect_named(out, unified_cols)
  expect_equal(nrow(out), 1L)
  expect_true(is.na(out$indicator))
  expect_true(is.na(out$value))
  expect_true(is.na(out$value_num))
  expect_true(is.na(out$low))
  expect_true(is.na(out$high))
  expect_type(out$value_num, "double")
  expect_type(out$year,      "integer")
})

# ── gho_clean: indicator column resolved from catalog ────────────────

test_that("gho_clean populates indicator from the GHO catalog", {
  # Helper pre-populates the cache with WHOSIS_000001 → "Life
  # expectancy at birth (years)". gho_clean() should pick that up
  # from IndicatorCode alone, even when the source frame does not
  # carry IndicatorName (which the data endpoint never returns).
  raw <- tibble::tibble(
    IndicatorCode = c("WHOSIS_000001", "WHOSIS_000001"),
    SpatialDim    = c("FRA", "DEU"),
    TimeDim       = c(2019L, 2019L),
    Value         = c("82.5", "81.0"),
    NumericValue  = c(82.5, 81.0)
  )
  out <- gho_clean(raw)
  expect_true(all(out$indicator == "Life expectancy at birth (years)"))
})

test_that(".gho_indicator_catalog() reads from the cache deterministically", {
  old <- .dsi_cache$gho_indicator_catalog
  on.exit(.dsi_cache$gho_indicator_catalog <- old, add = TRUE)

  marker <- tibble::tibble(
    IndicatorCode = "MARKER_XYZ",
    IndicatorName = "test marker",
    Language      = "EN"
  )
  .dsi_cache$gho_indicator_catalog <- marker

  expect_identical(.gho_indicator_catalog(), marker)
  # A second call must not replace the cached value.
  invisible(.gho_indicator_catalog())
  expect_identical(.dsi_cache$gho_indicator_catalog, marker)
})

test_that("gho_clean falls back to NA indicator when the catalog is empty", {
  old <- .dsi_cache$gho_indicator_catalog
  on.exit(.dsi_cache$gho_indicator_catalog <- old, add = TRUE)
  .dsi_cache$gho_indicator_catalog <- tibble::tibble(
    IndicatorCode = character(),
    IndicatorName = character(),
    Language      = character()
  )

  raw <- tibble::tibble(
    IndicatorCode = "WHOSIS_000001",
    SpatialDim    = "FRA",
    TimeDim       = 2019L,
    Value         = "82.5",
    NumericValue  = 82.5
  )
  out <- gho_clean(raw)
  expect_equal(nrow(out), 1L)
  expect_true(is.na(out$indicator))
})

test_that("gho_clean populates indicator from live catalog (integration)", {
  skip_on_cran()
  skip_if_offline()

  old <- .dsi_cache$gho_indicator_catalog
  on.exit(.dsi_cache$gho_indicator_catalog <- old, add = TRUE)
  rm("gho_indicator_catalog", envir = .dsi_cache)

  raw <- gho_data("WHOSIS_000001", area = "FRA")
  skip_if(nrow(raw) == 0L, "GHO returned no rows for WHOSIS_000001/FRA")

  clean <- gho_clean(raw)
  expect_true(any(!is.na(clean$indicator)))
  expect_match(
    clean$indicator[!is.na(clean$indicator)][1],
    "life expectancy",
    ignore.case = TRUE
  )
})

# ── sdg_clean: realistic row ─────────────────────────────────────────

test_that("sdg_clean maps SDG columns to the unified schema", {
  raw <- tibble::tibble(
    goal              = c("3", "3"),
    target            = c("3.4", "3.4"),
    indicator         = list("3.4.1", "3.4.1"),
    series            = c("SH_DTH_NCD", "SH_DTH_NCD"),
    seriesDescription = c("NCD mortality, both sexes",
                          "NCD mortality, both sexes"),
    geoAreaCode       = c("608", "076"),
    geoAreaName       = c("Philippines", "Brazil"),
    timePeriodStart   = c(2019, 2019),
    value             = c("17.3", "16.2"),
    lowerBound        = c("16.1", "15.0"),
    upperBound        = c("18.6", "17.5")
  )
  out <- sdg_clean(raw)

  expect_named(out, unified_cols)
  expect_equal(nrow(out), 2L)
  expect_true(all(out$source == "sdg"))
  expect_equal(out$id[1], "3.4.1")
  expect_equal(out$indicator[1], "NCD mortality, both sexes")
  expect_setequal(out$location, c("608", "076"))
  expect_setequal(out$iso3,     c("PHL", "BRA"))
  expect_setequal(out$location_name, c("Philippines", "Brazil"))
  expect_type(out$year, "integer")
  expect_type(out$value_num, "double")
  expect_type(out$low,       "double")
  expect_type(out$high,      "double")
  expect_true(all(is.na(out$dim1)))
  expect_true(all(is.na(out$dim2)))
  expect_true(all(is.na(out$dim3)))
})

test_that("sdg_clean tolerates non-numeric value entries (<0.1, aggregates)", {
  raw <- tibble::tibble(
    indicator       = list("3.4.1"),
    series          = "SH_DTH_NCD",
    geoAreaCode     = "608",
    geoAreaName     = "Philippines",
    timePeriodStart = 2019,
    value           = "<0.1",
    lowerBound      = NA_character_,
    upperBound      = NA_character_
  )
  out <- sdg_clean(raw)
  expect_equal(out$value,      "<0.1")
  expect_true(is.na(out$value_num))
})

test_that("sdg_clean iso3 is NA for region/world M49 aggregates", {
  raw <- tibble::tibble(
    indicator       = list("3.4.1"),
    geoAreaCode     = c("001", "900"),
    timePeriodStart = c(2019, 2019),
    value           = c("1", "2")
  )
  out <- sdg_clean(raw)
  expect_true(all(is.na(out$iso3)))
})

test_that("sdg_clean prefers who_countries names over SDG API names", {
  # Pass a deliberately different geoAreaName ("Philippine Islands") to
  # verify the cleaner uses who_countries$name_short ("Philippines")
  # instead of the SDG API's raw label for WHO Member States.
  raw <- tibble::tibble(
    indicator       = list("3.4.1"),
    geoAreaCode     = "608",
    geoAreaName     = "Philippine Islands",
    timePeriodStart = 2020L,
    value           = "10"
  )
  out <- sdg_clean(raw)
  expect_equal(
    out$location_name[1],
    who_countries$name_short[who_countries$iso3 == "PHL"]
  )
  expect_false(out$location_name[1] == "Philippine Islands")
})

test_that("sdg_clean falls back to geoAreaName for non-Member-State rows", {
  raw <- tibble::tibble(
    indicator       = list("3.4.1"),
    geoAreaCode     = "001",          # World aggregate
    geoAreaName     = "World",
    timePeriodStart = 2020L,
    value           = "10"
  )
  out <- sdg_clean(raw)
  expect_true(is.na(out$iso3[1]))
  expect_equal(out$location_name[1], "World")
})

test_that("sdg_clean location_name matches gho_clean for the same iso3", {
  # The point of the change: cross-API consistency. The same country
  # must have the same `location_name` whether routed via gho_clean
  # (ISO3) or sdg_clean (M49).
  gho_raw <- tibble::tibble(
    IndicatorCode = "X",
    SpatialDim    = c("PHL", "FRA"),
    TimeDim       = c(2020L, 2020L),
    Value         = c("1", "2"),
    NumericValue  = c(1, 2)
  )
  sdg_raw <- tibble::tibble(
    indicator       = list("3.4.1", "3.4.1"),
    geoAreaCode     = c("608", "250"),      # PHL, FRA
    geoAreaName     = c("Philippines", "France"),
    timePeriodStart = c(2020L, 2020L),
    value           = c("1", "2")
  )
  g <- gho_clean(gho_raw)
  s <- sdg_clean(sdg_raw)
  expect_equal(
    g$location_name[order(g$iso3)],
    s$location_name[order(s$iso3)]
  )
})

test_that("sdg_clean indicator column accepts atomic or list source", {
  # Some endpoints return `indicator` as plain chr; sdg_clean should
  # handle that too.
  raw <- tibble::tibble(
    indicator       = c("3.4.1", "3.4.1"),
    geoAreaCode     = c("608", "076"),
    timePeriodStart = c(2019, 2019),
    value           = c("1", "2")
  )
  out <- sdg_clean(raw)
  expect_equal(unique(out$id), "3.4.1")
})

# ── gho_clean + sdg_clean share schema ───────────────────────────────

test_that("gho_clean and sdg_clean produce identical column types", {
  empty_g <- gho_clean(tibble::tibble())
  empty_s <- sdg_clean(tibble::tibble())
  expect_named(empty_g, names(empty_s))
  expect_equal(vapply(empty_g, typeof, character(1)),
               vapply(empty_s, typeof, character(1)))
})
