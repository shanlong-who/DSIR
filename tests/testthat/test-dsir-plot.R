plot_test_raw <- function() {
  tibble::tibble(IndicatorCode = "EXAMPLE", IndicatorName = "Illustrative indicator",
    SpatialDim = rep(c("PHL", "LAO"), each = 4),
    TimeDim = rep(2020:2023, 2), TimeDimType = "YEAR",
    NumericValue = c(12, 11, 10, 9, 15, 14, 13, 12),
    Low = c(10, 9, 8, 7, 13, 12, 11, 10),
    High = c(14, 13, 12, 11, 17, 16, 15, 14),
    Unit = "percent", Dim1 = "SEX_BTSX", Dim1Type = "SEX", Provider = "legacy")
}

test_that("country trends return customizable ggplots with constant metadata units", {
  raw <- plot_test_raw()
  x <- gho_clean(raw)
  p <- plot(x, type = "trend", country = "PHL", interval = TRUE)
  expect_s3_class(p, "ggplot")
  expect_identical(p$data$iso3, rep("PHL", 4))
  expect_identical(p$labels$y, "percent")
  expect_match(p$labels$caption, "legacy")
  expect_match(p$labels$subtitle, "SEX_BTSX")
  expect_no_warning(ggplot2::ggplot_build(p + ggplot2::labs(title = "Custom title")))
  all <- plot(x, type = "trend")
  expect_identical(all$labels$colour, "iso3")
  expect_equal(length(unique(all$data$.dsir_segment)), 2L)
  expect_equal(nrow(ggplot2::ggplot_build(all)$data[[1]]), 8L)
  expect_s3_class(ggplot2::ggplot_build(ggplot2::ggplot(x,
    ggplot2::aes(x = year, y = value_num)) + ggplot2::geom_point()), "ggplot_built")
})

test_that("comparisons use one common year with no implicit latest selection", {
  x <- gho_clean(plot_test_raw())
  expect_error(plot(x, type = "compare"), "one common year")
  p <- plot(x, type = "compare", year = 2023, interval = TRUE)
  expect_s3_class(p$coordinates, "CoordFlip")
  expect_equal(p$data$value_num, c(12, 9))
  expect_equal(unique(p$data$year), 2023L)
  expect_match(p$labels$subtitle, "2023")
  expect_no_warning(ggplot2::ggplot_build(p))
  expect_no_error(plot(x[x$year == 2023, ], type = "compare"))
  expect_error(plot(x, type = "compare", year = c(2022, 2023)), "one common year")
})

test_that("unmapped strata are rejected even without duplicate country years", {
  raw <- plot_test_raw()
  raw$Dim1 <- rep(c("SEX_MLE", "SEX_FMLE"), each = 4)
  x <- gho_clean(raw)
  expect_error(plot(x, type = "compare", year = 2023), "Unresolved.*dim1")
  raw <- rbind(plot_test_raw(), plot_test_raw())
  raw$Dim1 <- rep(c("SEX_MLE", "SEX_FMLE"), each = 8)
  x <- gho_clean(raw)
  expect_error(plot(x, type = "trend"), "Unresolved.*dim1")
  expect_error(plot(x, type = "trend", group = "dim1"), "Multiple countries")
  p <- plot(x, type = "trend", group = "dim1", facet = "iso3")
  expect_no_warning(ggplot2::ggplot_build(p))
  expect_equal(length(unique(p$data$.dsir_segment)), 4L)
  raw$Dim2 <- rep(c("Y0T4", "Y5T9"), each = 8)
  expect_error(plot(gho_clean(raw), type = "trend", group = "dim1", facet = "iso3"), "dim2")
  expect_no_error(plot(gho_clean(raw), type = "trend", country = "PHL", group = "dim1", facet = "dim2"))
})

test_that("SDG omitted varying context requires recleaning, not guessed strata", {
  raw <- tibble::tibble(geoAreaCode = c("608", "418"), timePeriodStart = 2023,
    indicator = list("3.4.1", "3.4.1"), series = "EXAMPLE", value = c("10", "20"),
    seriesDescription = "Illustrative SDG series",
    dimensions = data.frame(Sex = c("FEMALE", "MALE"), Age = "ALLAGE"),
    attributes = data.frame(Units = "PERCENT"))
  compact <- sdg_clean(raw)
  expect_error(plot(compact, type = "compare"), "omitted.*dim_sex")
  expect_error(plot(compact, type = "compare", country = "PHL"), "omitted")
  x <- sdg_clean(raw, keep_dimensions = TRUE)
  expect_error(plot(x, type = "compare"), "Unresolved.*dim_sex")
  p <- plot(x, type = "compare", group = "dim_sex")
  expect_identical(p$labels$y, "PERCENT")
  expect_match(p$labels$subtitle, "ALLAGE")
  expect_no_warning(ggplot2::ggplot_build(p))
  raw$series <- c("ONE", "TWO")
  expect_error(plot(sdg_clean(raw, keep_dimensions = TRUE), type = "compare", group = "dim_sex"), "series")
})

test_that("GHE and xMart named aliases match their recorded core dimensions", {
  raw <- tibble::tibble(iso3 = "PHL", location_name = "Philippines", year = 2023L,
    sex = c("FEMALE", "MALE"), age = "TOTAL", cause_code = "0", cause_name = "All causes",
    measure = "deaths", value = c(100, 200), low = c(80, 180), high = c(120, 220),
    population = 100000, unit = "deaths", level = 0L, cause_group = "0", rankable = FALSE)
  for (detailed in c(FALSE, TRUE)) {
    x <- ghe_clean(raw, keep_dimensions = detailed)
    p <- plot(x, type = "compare", group = if (detailed) "dim_sex" else "dim1")
    expect_identical(p$labels$y, "deaths")
    expect_no_warning(ggplot2::ggplot_build(p))
  }
  raw <- plot_test_raw()
  raw$Dim1 <- rep(c("SEX_MLE", "SEX_FMLE"), each = 4)
  raw$DIM_SEX <- rep(c("MALE", "FEMALE"), each = 4)
  raw$Provider <- "xmart"
  for (detailed in c(FALSE, TRUE)) {
    x <- gho_clean(raw, keep_dimensions = detailed)
    expect_no_error(plot(x, type = "compare", year = 2023,
      group = if (detailed) "dim_sex" else "dim1"))
  }
})

test_that("SDG measurement bases remain visible without implicit scaling", {
  raw <- tibble::tibble(geoAreaCode = c("608", "418"), timePeriodStart = 2023,
    indicator = "EXAMPLE", series = "EXAMPLE", value = c("10", "20"), basePeriod = "2015",
    attributes = data.frame(Units = "NUMBER", `Unit multiplier` = "6", check.names = FALSE))
  p <- plot(sdg_clean(raw), type = "compare")
  expect_identical(p$labels$y, "NUMBER")
  expect_match(p$labels$subtitle, "attr_unit_multiplier: 6")
  expect_match(p$labels$subtitle, "base_period: 2015")
  expect_equal(sort(p$data$value_num), c(10, 20))
  expect_no_warning(ggplot2::ggplot_build(p))
})

test_that("mixed definitions units origins and duplicates never get aggregated", {
  for (field in c("IndicatorCode", "Unit", "Provider", "MeasureField")) {
    raw <- plot_test_raw()
    raw[[field]] <- rep(c("ONE", "TWO"), each = 4)
    if (field == "Provider") raw[[field]] <- rep(c("xmart", "legacy"), each = 4)
    expect_error(plot(gho_clean(raw, keep_metadata = TRUE), type = "trend"),
      "mixed|Conflicting|backend")
  }
  raw <- plot_test_raw()
  raw$Unit[[1]] <- NA_character_
  expect_error(plot(gho_clean(raw), type = "trend"), "omitted")
  raw$Unit <- NULL
  expect_match(plot(gho_clean(raw), type = "trend")$labels$y, "unit not recorded")
  expect_error(plot(gho_clean(rbind(raw, raw[1, ])), type = "trend"), "Duplicate observations")
  raw$TimeDimType <- "MONTH"
  expect_error(plot(gho_clean(raw), type = "trend"), "annual")
  raw$TimeDimType <- "YEAR"
  raw$TimeDim <- as.numeric(raw$TimeDim) + 0.5
  expect_error(plot(gho_clean(raw), type = "trend"), "time precision")
})

test_that("trends break across absent years and missing estimates without inventing rows", {
  raw <- plot_test_raw()[1:4, ]
  raw$TimeDim <- c(2017L, 2018L, 2020L, 2021L)
  p <- plot(gho_clean(raw), type = "trend")
  expect_equal(nrow(p$data), 4L)
  expect_equal(length(unique(p$data$.dsir_segment)), 2L)
  raw$NumericValue[[2]] <- NA_real_
  expect_warning(p <- plot(gho_clean(raw), type = "trend"), "Omitting 1")
  lines <- ggplot2::ggplot_build(p)$data[[1]]
  expect_identical(as.numeric(lines$x), c(2020, 2021))
  expect_equal(nrow(p$data), 3L)
})

test_that("intervals preserve estimates and align groups with missing bounds", {
  raw <- plot_test_raw()[c(1, 1), ]
  raw$Dim1 <- c("SEX_MLE", "SEX_FMLE")
  raw$Low[[1]] <- NA_real_
  expect_warning(p <- plot(gho_clean(raw), type = "compare", group = "dim1", interval = TRUE), "incomplete")
  built <- ggplot2::ggplot_build(p)$data
  expect_equal(nrow(built[[1]]), 1L)
  expect_equal(nrow(built[[2]]), 2L)
  expect_equal(built[[1]]$x, built[[2]]$x[match(built[[1]]$colour, built[[2]]$colour)])
  for (bad in c(100, Inf)) {
    raw$Low <- bad
    expect_error(plot(gho_clean(raw), type = "compare", group = "dim1", interval = TRUE), "bounds")
  }
  raw$Low <- raw$High <- NA_real_
  expect_error(plot(gho_clean(raw), type = "compare", group = "dim1", interval = TRUE), "No complete")
})

test_that("plotting respects field review but allows unrelated derived flags", {
  skip_if_not_installed("dplyr")
  x <- gho_clean(plot_test_raw(), keep_metadata = TRUE)
  expect_no_error(plot(dplyr::mutate(x, flag = value_num > 10), type = "trend"))
  expect_no_error(plot(dplyr::mutate(x, updated = "new note"), type = "trend"))
  for (changed in list(dplyr::mutate(x, value_num = value_num / 100),
                       dplyr::mutate(x, unit = "number"),
                       dplyr::mutate(x, dim1 = "SEX_MLE"),
                       dplyr::select(x, -unit))) {
    expect_s3_class(changed, "dsir_data")
    expect_error(plot(changed, type = "trend"), "needs review")
  }
  plain <- tibble::as_tibble(x)
  expect_no_error(plot(as_dsir_data(plain), type = "trend"))
})

test_that("plot input errors identify unavailable or unsupported selections", {
  x <- gho_clean(plot_test_raw())
  expect_error(plot(x), "Specify")
  expect_error(plot(x, type = "auto"), "arg")
  expect_error(plot(x, type = "trend", year = 2020.5), "integer-valued")
  expect_error(plot(x, type = "trend", year = 1900), "Years absent")
  expect_error(plot(x, type = "trend", country = "ZZZ"), "Country codes absent")
  expect_error(plot(x, type = "trend", group = "absent"), "name one column")
  expect_error(plot(x, type = "trend", interval = NA), "logical")
  expect_error(plot(x, type = "trend", unused = TRUE), "empty")
  expect_error(plot(gho_clean(tibble::tibble()), type = "trend"), "No observations")
  raw <- plot_test_raw()
  raw$SpatialDim <- "WPR"
  expect_error(plot(gho_clean(raw), type = "trend"), "country observations")
})
