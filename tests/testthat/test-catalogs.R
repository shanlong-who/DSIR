test_that("bundled catalogs retain backend-specific keys and source counts", {
  expect_s3_class(gho_catalog, "tbl_df")
  expect_named(gho_catalog, c("IndicatorCode", "IndicatorName", "Language", "backend"))
  expect_setequal(gho_catalog$backend, c("legacy", "xmart"))
  expect_equal(anyDuplicated(gho_catalog[c("backend", "IndicatorCode", "Language")]), 0L)
  expect_gt(sum(duplicated(gho_catalog$IndicatorCode)), 0L)
  expect_gt(nrow(sdg_catalog), 200L)
  expect_equal(anyDuplicated(sdg_catalog$code), 0L)
  expect_true(is.list(sdg_catalog$series))
  expect_setequal(ghe_catalog$kind, c("cause", "measure"))
  expect_equal(anyDuplicated(ghe_catalog[c("kind", "code")]), 0L)
  expect_true(all(is.na(ghe_catalog$unit[ghe_catalog$kind == "cause"])))
  expect_true(all(!is.na(ghe_catalog$unit[ghe_catalog$kind == "measure"])))
  for (data in list(gho_catalog, sdg_catalog, ghe_catalog)) {
    metadata <- dsir_metadata(data)
    expect_identical(metadata$schema_version, 1L)
    expect_identical(metadata$layout, "catalog")
    expect_identical(metadata$record_count, nrow(data))
    expect_identical(sum(metadata$sources$record_count), nrow(data))
    expect_true(all(metadata$sources$retrieval_status %in% c("live", "bundled_snapshot")))
    expect_true(all(grepl("Z$", metadata$sources$retrieved_at)))
    expect_true(nzchar(metadata$catalog_version))
    expect_true(nzchar(metadata$package_version))
  }
})

test_that("historical catalog origins and provider releases are explicit", {
  gho <- dsir_metadata(gho_catalog)
  old <- gho$sources[gho$sources$retrieval_status == "bundled_snapshot", ]
  if (nrow(old)) expect_true(all(old$retrieved_at < gho$bundled_at))
  expect_true(all(is.na(gho$sources$api_version)))
  expect_identical(dsir_metadata(sdg_catalog)$sources$api_version, "V5")
  expect_gt(length(dsir_metadata(sdg_catalog)$scope$provider_releases), 0L)
  ghe <- dsir_metadata(ghe_catalog)
  expect_true(ghe$scope$cause_reference$area %in% who_countries$iso3)
  expect_identical(ghe$scope$cause_reference$sex, "TOTAL")
  expect_identical(ghe$scope$cause_reference$age, "TOTAL")
  expect_true(all(is.na(ghe$sources$source_release)))
})

test_that("GHO union retains different names under the same code", {
  legacy <- tibble::tibble(IndicatorCode = "SAME", IndicatorName = "Legacy label", Language = "EN")
  xmart <- legacy
  xmart$IndicatorName <- "xMart label"
  out <- .dsi_catalog_gho(legacy, xmart)
  expect_equal(nrow(out), 2L)
  expect_setequal(out$IndicatorName, c("Legacy label", "xMart label"))
  expect_setequal(out$backend, c("legacy", "xmart"))
  expect_error(.dsi_catalog_gho(legacy[0, ], xmart), "empty")
  expect_error(.dsi_catalog_gho(rbind(legacy, legacy), xmart), "duplicate")
})

test_that("SDG catalog preserves exact many-to-many series links and release labels", {
  series <- tibble::tibble(code = "SHARED", indicator = list(c("1.5.1", "11.5.1")),
                       release = "2026.Q3.G.01", description = "Shared series")
  raw <- tibble::tibble(goal = "1", target = "1.5", code = "1.5.1",
    description = "Example", tier = "1", uri = "/Indicator/1.5.1", series = list(series))
  out <- .dsi_catalog_sdg(raw)
  expect_identical(out$series, raw$series)
  expect_identical(out$backend, "unsdg")
  raw$code <- "11.5.10"
  expect_error(.dsi_catalog_sdg(raw), "unrelated")
  raw$series[[1]]$code <- NA_character_
  expect_error(.dsi_catalog_sdg(raw), "malformed")
})

test_that("GHE catalog lists causes and measures without generating pairs", {
  causes <- tibble::tibble(cause_code = c("0", "1"), cause_name = c("All", "Example"),
    level = 0:1, cause_group = "0", rankable = c(FALSE, TRUE), single_cause = FALSE)
  measures <- .ghe_measures()[1:2, ]
  out <- .dsi_catalog_ghe(causes, measures)
  expect_equal(nrow(out), nrow(causes) + nrow(measures))
  expect_identical(out$code[out$kind == "cause"], causes$cause_code)
  expect_identical(out$field[out$kind == "measure"], measures$field)
  expect_error(.dsi_catalog_ghe(causes, measures[0, ]), "empty")
})

test_that("catalog metadata cannot conceal failed retrievals or inconsistent totals", {
  metadata <- dsir_metadata(gho_catalog)
  sources <- metadata$sources
  sources$retrieval_status[1] <- "failed"
  expect_error(.dsi_catalog_attach(gho_catalog, "gho_catalog", sources,
    metadata$bundled_at, metadata$package_version), "incomplete or inconsistent")
  sources <- metadata$sources
  sources$record_count[1] <- 0L
  expect_error(.dsi_catalog_attach(gho_catalog, "gho_catalog", sources,
    metadata$bundled_at, metadata$package_version), "incomplete or inconsistent")
  testthat::local_mocked_bindings(.dsi_request = function(...) stop("No network"), .package = "DSIR")
  subset <- gho_catalog[gho_catalog$backend == "xmart", ]
  expect_identical(dsir_metadata(subset)$current$rows, nrow(subset))
  expect_identical(dsir_metadata(subset)$record_count, nrow(gho_catalog))
})
