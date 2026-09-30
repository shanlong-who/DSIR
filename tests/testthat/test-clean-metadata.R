test_that("SDG metadata and all notes stay aligned with their observations", {
  raw <- tibble::tibble(
    indicator = list(c("3.8.2", "1.2.3"), "3.8.2"),
    goal = list(c("3", "1"), "3"), target = list(c("3.8", "1.2"), "3.8"),
    geoAreaCode = c("608", "250"), timePeriodStart = c(2023L, 2020L),
    source = c("Survey {2023}", "Survey B"),
    footnotes = list(c("First note", "Second note | with separator"), "Other note"),
    time_detail = c("2023 survey", "2020 survey"),
    timeCoverage = c("2022-2023", "2020"), basePeriod = c("2017", "2017"),
    valueType = "Float", geoInfoUrl = c("https://example.test/PHL", NA),
    attributes = data.frame(Units = c("PERCENT", "NUMBER"), Nature = c("C", "G")),
    dimensions = data.frame(Sex = c("BOTHSEX", "FEMALE"))
  )
  core <- sdg_clean(raw)
  out <- sdg_clean(raw, keep_dimensions = TRUE, keep_metadata = TRUE)
  expect_identical(out[names(core)], core)
  expect_equal(out$attr_units, c("NUMBER", "PERCENT"))
  expect_equal(out$attr_nature, c("G", "C"))
  expect_equal(out$dim_sex, c("FEMALE", "BOTHSEX"))
  expect_equal(out$data_source, c("Survey B", "Survey {2023}"))
  expect_identical(out$footnotes[[2]], raw$footnotes[[1]])
  expect_identical(out$indicator_codes[[2]], c("3.8.2", "1.2.3"))
  expect_identical(out$goal_codes[[2]], c("3", "1"))
  expect_identical(out$target_codes[[2]], c("3.8", "1.2"))
  expect_equal(out$time_coverage, c("2020", "2022-2023"))
  expect_equal(out$base_period, c("2017", "2017"))
  expect_equal(out$geo_info_url[[2]], "https://example.test/PHL")
  expect_false("dim_sex" %in% names(sdg_clean(raw, keep_metadata = TRUE)))
})

test_that("GHO dimension types come from each row and never from code prefixes", {
  raw <- tibble::tibble(
    SpatialDim = "PHL", TimeDim = c(2023L, 2000L, 2020L),
    Dim1 = c("SAME_CODE", "SAME_CODE", "SEX_FMLE"),
    Dim1Type = c("WEALTHQUINTILE", "DEMOGRAPHIC", NA_character_),
    Dim2 = c(NA, "SEX_FMLE", NA), Dim2Type = c(NA, "SEX", NA)
  )
  core <- gho_clean(raw)
  out <- gho_clean(raw, keep_dimensions = TRUE)
  expect_identical(out[names(core)], core)
  expect_equal(out$year, c(2000L, 2020L, 2023L))
  expect_equal(out$dim1_type, c("DEMOGRAPHIC", NA_character_, "WEALTHQUINTILE"))
  expect_equal(out$dim2_type, c("SEX", NA_character_, NA_character_))
  expect_true(all(is.na(out$dim3_type)))
  expect_equal(ncol(core), 15L)
  expect_equal(ncol(out), 18L)
})

test_that("GHO metadata retains original source identifiers, times, and comments", {
  raw <- tibble::tibble(
    Id = c(2, 1), SpatialDim = "PHL", SpatialDimType = "COUNTRY",
    TimeDim = c(2023L, 2000L), TimeDimType = "YEAR",
    DataSourceDim = c("DATASOURCE_NEW", "DATASOURCE_OLD"),
    DataSourceDimType = "DATASOURCE", Comments = c("Note new", "Note old"),
    Date = c("2025-11-19T16:33:34+01:00", "2025-10-01T00:00:00Z"),
    ParentLocationCode = "WPR", ParentLocation = "Western Pacific",
    TimeDimensionValue = c("2023", "2000"),
    TimeDimensionBegin = c("2023-01-01", "2000-01-01"),
    TimeDimensionEnd = c("2023-12-31", "2000-12-31")
  )
  out <- gho_clean(raw, keep_metadata = TRUE)
  expect_equal(out$observation_id, c("1", "2"))
  expect_equal(out$data_source, c("DATASOURCE_OLD", "DATASOURCE_NEW"))
  expect_equal(out$data_source_type, rep("DATASOURCE", 2))
  expect_identical(out$footnotes, list("Note old", "Note new"))
  expect_equal(out$updated, rev(raw$Date))
  expect_equal(out$spatial_type, rep("COUNTRY", 2))
  expect_equal(out$time_type, rep("YEAR", 2))
  expect_equal(out$time_start, rev(raw$TimeDimensionBegin))
  expect_equal(out$time_end, rev(raw$TimeDimensionEnd))
  expect_equal(out$parent_location, rep("WPR", 2))
  expect_false("dim1_type" %in% names(out))
})

test_that("metadata handles absent, null, and list-form attributes", {
  raw <- tibble::tibble(geoAreaCode = c("608", "608"))
  raw$attributes <- list(list(Units = "PERCENT", Nature = NULL), NULL)
  out <- sdg_clean(raw, keep_metadata = TRUE)
  expect_equal(out$attr_units, c("PERCENT", NA_character_))
  expect_identical(out$attr_nature, rep(NA_character_, 2))
  expect_true(all(is.na(out$data_source)))
  expect_identical(out$footnotes, list(character(), character()))
  raw$attributes <- c(NA, NA)
  expect_no_error(sdg_clean(raw, keep_metadata = TRUE))
})

test_that("metadata stays typed on empty input and can be bound across sources", {
  s <- sdg_clean(tibble::tibble(), keep_dimensions = TRUE, keep_metadata = TRUE)
  g <- gho_clean(tibble::tibble(), keep_dimensions = TRUE, keep_metadata = TRUE)
  expect_equal(nrow(s), 0L)
  expect_type(s$footnotes, "list")
  expect_type(g$dim1_type, "character")
  expect_type(g$data_source, "character")
  expect_type(g$footnotes, "list")

  sdg <- sdg_clean(tibble::tibble(
    geoAreaCode = "608", source = "Survey",
    footnotes = list(c("One", "Two")), attributes = data.frame(Units = "PERCENT")
  ), keep_metadata = TRUE)
  gho <- gho_clean(tibble::tibble(
    SpatialDim = "PHL", Comments = "GHO note", Dim1Type = "WEALTHQUINTILE"
  ), keep_dimensions = TRUE, keep_metadata = TRUE)
  out <- bind_indicators(gho, sdg)
  expect_identical(out$footnotes, list("GHO note", c("One", "Two")))
  expect_equal(out$attr_units, c(NA_character_, "PERCENT"))
  expect_equal(out$dim1_type, c("WEALTHQUINTILE", NA_character_))
  expect_no_error(bind_indicators(g, s))
})

test_that("metadata flags are validated even on empty inputs", {
  expect_error(sdg_clean(tibble::tibble(), keep_metadata = NA), "single logical")
  expect_error(gho_clean(tibble::tibble(), keep_metadata = "yes"), "single logical")
  expect_error(gho_clean(tibble::tibble(), keep_dimensions = 1), "single logical")
})
