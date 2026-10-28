test_that("identical snapshots are unchanged despite creation/retrieval times", {
  x <- snapshot_test_data()
  old <- data_snapshot(x)
  attr(x, "who_provenance")$retrieved <- "2026-10-28 00:00:00"
  new <- data_snapshot(x)
  new$created_at <- new$created_at + 3600
  out <- compare_snapshots(old, new)
  expect_s3_class(out, "dsir_snapshot_comparison")
  expect_equal(out$summary$n_old, 4)
  expect_equal(out$summary$n_new, 4)
  expect_equal(out$summary$n_unchanged, 4)
  expect_equal(out$summary$n_modified, 0)
  expect_equal(out$summary$n_added, 0)
  expect_equal(out$summary$n_removed, 0)
  expect_identical(out$summary$old_retrieved_at, old$retrieved_at)
  expect_identical(out$summary$new_retrieved_at, new$retrieved_at)
  expect_identical(out$unchanged, new$data)
})

test_that("new years are additions under the same unbounded query", {
  x <- snapshot_test_data()
  y <- rbind(x, x[1, ])
  y$Id[5] <- 5L
  y$TimeDim[5] <- 2022L
  y$TimeDimensionValue[5] <- "2022"
  attr(y, "who_provenance")$rows <- 5L
  out <- compare_snapshots(data_snapshot(x), data_snapshot(y))
  expect_equal(out$summary$n_added, 1)
  expect_equal(out$added$TimeDim, 2022L)
  expect_equal(out$summary$n_modified, 0)
  expect_equal(out$summary$n_removed, 0)
  expect_equal(out$summary$n_unchanged, 4)
})

test_that("historical value revisions retain keys, original rows and deltas", {
  x <- snapshot_test_data()
  y <- x
  y$NumericValue[1] <- 12
  out <- compare_snapshots(snapshot_test_wrap(x), snapshot_test_wrap(y))
  expect_equal(out$summary$n_modified, 1)
  expect_equal(out$summary$n_value_modified, 1)
  expect_equal(out$summary$n_metadata_only, 0)
  expect_equal(out$modified$TimeDim, 2020L)
  expect_equal(out$modified$Dim1, "SEX_MLE")
  expect_equal(out$modified$old_value, 10)
  expect_equal(out$modified$new_value, 12)
  expect_equal(out$modified$absolute_change, 2)
  expect_equal(out$modified$relative_change, 0.2)
  expect_identical(out$modified$changed_fields, list("NumericValue"))
  expect_identical(out$modified$old[1, , drop = FALSE], x[1, ])
  expect_identical(out$modified$new[1, , drop = FALSE], y[1, ])
  expect_s3_class(out$modified$old, "data.frame")
  expect_equal(nrow(out$modified$old), nrow(out$modified))
  expect_identical(out$modified$change_type, "value")
})

test_that("deletions and completely empty selections are supported", {
  x <- snapshot_test_data()
  out <- compare_snapshots(snapshot_test_wrap(x), snapshot_test_wrap(x[-2, ]))
  expect_equal(out$summary$n_removed, 1)
  expect_identical(out$removed, x[2, ])
  expect_equal(out$summary$n_unchanged, 3)
  empty <- snapshot_test_wrap(x[0, ], indicator = "EXAMPLE")
  gone <- compare_snapshots(snapshot_test_wrap(x), empty)
  expect_equal(gone$summary$n_removed, 4)
  expect_equal(gone$summary$n_modified, 0)
  expect_equal(gone$summary$n_unchanged, 0)
  added <- compare_snapshots(empty, snapshot_test_wrap(x))
  expect_equal(added$summary$n_added, 4)
  expect_equal(compare_snapshots(empty, empty)$summary$n_new, 0)
})

test_that("NA changes, zero and non-finite values have explicit semantics", {
  x <- snapshot_test_data()
  x$NumericValue <- c(NA, NA, 0, 10)
  y <- x
  y$NumericValue <- c(NA, 5, 2, NA)
  out <- compare_snapshots(snapshot_test_wrap(x), snapshot_test_wrap(y))
  expect_equal(out$summary$n_modified, 3)
  expect_equal(out$summary$n_unchanged, 1)
  zero <- out$modified[out$modified$old_value %in% 0, ]
  expect_equal(zero$absolute_change, 2)
  expect_true(is.na(zero$relative_change))
  expect_true(all(is.na(out$modified$absolute_change[c(1, 3)])))
  x$NumericValue <- c(-10, Inf, -Inf, NA)
  y$NumericValue <- c(-5, Inf, 1, NA)
  out <- compare_snapshots(snapshot_test_wrap(x), snapshot_test_wrap(y))
  expect_equal(out$summary$n_modified, 2)
  expect_equal(out$modified$relative_change[1], -0.5)
  expect_true(is.na(out$modified$absolute_change[2]))
})

test_that("row and column order do not determine observation identity", {
  x <- snapshot_test_data()
  y <- x[c(4, 2, 1, 3), rev(names(x))]
  out <- compare_snapshots(snapshot_test_wrap(x), snapshot_test_wrap(y))
  expect_equal(out$summary$n_unchanged, 4)
  expect_equal(out$summary$n_modified, 0)
  expect_equal(nrow(out$schema_changes), 0)
  y$NumericValue[y$Id == 1] <- 99
  out <- compare_snapshots(snapshot_test_wrap(x), snapshot_test_wrap(y))
  expect_equal(out$modified$old_value, 10)
  expect_equal(out$modified$new_value, 99)
})

test_that("metadata-only changes include notes, labels and source timestamps", {
  x <- snapshot_test_data()
  y <- x
  y$Comments[1] <- "Reviewed source note"
  y$IndicatorName[2] <- "Updated label"
  y$Date[3] <- "2026-04-01T12:00:00+02:00"
  out <- compare_snapshots(snapshot_test_wrap(x), snapshot_test_wrap(y))
  expect_equal(out$summary$n_modified, 3)
  expect_equal(out$summary$n_value_modified, 0)
  expect_equal(out$summary$n_metadata_only, 3)
  expect_true(all(out$modified$change_type == "metadata_only"))
  expect_equal(out$modified$absolute_change, c(0, 0, 0))
  expect_setequal(unlist(out$modified$changed_fields), c("Comments", "IndicatorName", "Date"))
})

test_that("value and metadata changes can occur on the same observation", {
  x <- snapshot_test_data()
  y <- x
  y$Low[1] <- 7
  y$Comments[1] <- "Re-estimated interval"
  out <- compare_snapshots(snapshot_test_wrap(x), snapshot_test_wrap(y))
  expect_equal(out$summary$n_value_modified, 1)
  expect_equal(out$summary$n_metadata_modified, 1)
  expect_true(out$modified$value_changed)
  expect_true(out$modified$metadata_changed)
  expect_setequal(out$modified$changed_fields[[1]], c("Low", "Comments"))
  expect_equal(out$modified$absolute_change, 0)
})

test_that("absent optional metadata is separate from observation identity", {
  x <- snapshot_test_data()
  x$Comments <- NULL
  x$Date <- NULL
  y <- x
  y$Comments <- rep(NA_character_, 4)
  out <- compare_snapshots(snapshot_test_wrap(x), snapshot_test_wrap(y))
  expect_equal(out$summary$n_modified, 0)
  expect_equal(out$summary$n_unchanged, 4)
  expect_identical(out$schema_changes$field, "Comments")
  expect_identical(out$schema_changes$change, "added")
  y$Comments[1] <- "Now available"
  out <- compare_snapshots(snapshot_test_wrap(x), snapshot_test_wrap(y))
  expect_equal(out$summary$n_metadata_only, 1)
  out <- compare_snapshots(snapshot_test_wrap(y), snapshot_test_wrap(x))
  expect_equal(out$summary$n_metadata_only, 1)
  expect_identical(out$schema_changes$change, "removed")
})

test_that("JSON null-only columns gain a type without false changes", {
  x <- snapshot_test_data()
  x$Low <- x$Comments <- rep(NA, 4)
  y <- x
  y$Low <- rep(NA_real_, 4)
  y$Comments <- rep(NA_character_, 4)
  expect_equal(compare_snapshots(snapshot_test_wrap(x), snapshot_test_wrap(y))$summary$n_modified, 0)
  y$Low[1] <- 5
  y$Comments[2] <- "New note"
  out <- compare_snapshots(snapshot_test_wrap(x), snapshot_test_wrap(y))
  expect_equal(out$summary$n_value_modified, 1)
  expect_equal(out$summary$n_metadata_only, 1)
})

test_that("numeric precision is exact unless an absolute tolerance is supplied", {
  x <- snapshot_test_data()
  y <- x
  y$NumericValue[1] <- y$NumericValue[1] + 1e-8
  a <- snapshot_test_wrap(x)
  b <- snapshot_test_wrap(y)
  expect_equal(compare_snapshots(a, b)$summary$n_modified, 1)
  expect_equal(compare_snapshots(a, b, tolerance = 1e-7)$summary$n_modified, 0)
  y$Value[1] <- "10.00000001"
  b <- snapshot_test_wrap(y)
  expect_equal(compare_snapshots(a, b, tolerance = 1e-7)$summary$n_modified, 1)
  expect_equal(compare_snapshots(a, b, fields = "NumericValue", tolerance = 1e-7)$summary$n_modified, 0)
  for (tolerance in list(-1, NA_real_, Inf, "0", c(0, 1))) {
    expect_error(compare_snapshots(a, b, tolerance = tolerance), "tolerance")
  }
})

test_that("character, date, timestamp and list metadata compare correctly", {
  x <- snapshot_test_data()
  x$reviewed <- as.Date(rep("2026-01-01", 4))
  x$published <- as.POSIXct(rep("2026-01-01", 4), tz = "UTC")
  x$notes <- rep(list(character()), 4)
  y <- x
  y$reviewed[1] <- y$reviewed[1] + 1
  y$notes[[2]] <- c("A", "B")
  attr(y$published, "tzone") <- "Asia/Manila"
  out <- compare_snapshots(snapshot_test_wrap(x), snapshot_test_wrap(y))
  expect_equal(out$summary$n_metadata_only, 2)
  expect_setequal(unlist(out$modified$changed_fields), c("reviewed", "notes"))
  y$notes[[3]] <- NA_character_
  expect_equal(compare_snapshots(snapshot_test_wrap(x), snapshot_test_wrap(y))$summary$n_modified, 2)
})

test_that("incompatible field types are explicit errors", {
  x <- snapshot_test_data()
  y <- x
  y$Comments <- 1:4
  x$Comments <- rep("Reviewed", 4)
  expect_error(compare_snapshots(snapshot_test_wrap(x), snapshot_test_wrap(y)), "Incompatible types.*Comments")
  x <- snapshot_test_data()
  y <- x
  x$NumericValue <- as.integer(x$NumericValue)
  expect_equal(compare_snapshots(snapshot_test_wrap(x), snapshot_test_wrap(y))$summary$n_modified, 0)
})

test_that("source, indicator, backend, origin and query selections are guarded", {
  x <- snapshot_test_data()
  a <- data_snapshot(x)
  y <- x
  y$IndicatorCode <- "OTHER"
  expect_error(compare_snapshots(a, data_snapshot(y)), "indicator")
  y <- x
  attr(y, "who_provenance")$query_url <- "https://ghoapi.azureedge.net/api/EXAMPLE"
  expect_error(compare_snapshots(a, data_snapshot(y)), "scope")
  b <- data_snapshot(x, scope = list(area = "WPR"))
  expect_error(compare_snapshots(snapshot_test_wrap(x), b), "scope")
  y <- x
  y$Provider <- "xmart"
  attr(y, "who_provenance")$backend <- "xmart"
  expect_error(compare_snapshots(snapshot_test_wrap(x), snapshot_test_wrap(y)), "backend")
  y <- x
  attr(y, "who_provenance")$base_url <- "https://example.org"
  expect_error(compare_snapshots(a, data_snapshot(y)), "origin")
  b <- a
  b$source <- "sdg"
  expect_error(compare_snapshots(a, b), "source")
})

test_that("units, measure families and dimension schemas cannot silently change", {
  x <- snapshot_test_data()
  x$Unit <- "%"
  y <- x
  y$Unit <- "per 1000"
  expect_error(compare_snapshots(snapshot_test_wrap(x), snapshot_test_wrap(y)), "Unit or measure-family")
  x$Unit <- c("%", "per 1000", "%", "per 1000")
  y <- x
  y$Unit <- rev(x$Unit)
  expect_error(compare_snapshots(snapshot_test_wrap(x), snapshot_test_wrap(y)), "matching observation coordinates")
  x$MeasureField <- "RATE_N"
  y <- x
  y$MeasureField <- "COUNT_N"
  expect_error(compare_snapshots(snapshot_test_wrap(x), snapshot_test_wrap(y)), "Unit or measure-family")
  x <- snapshot_test_data()
  y <- x
  y$DIM_EXTRA <- "TOTAL"
  expect_error(compare_snapshots(snapshot_test_wrap(x), snapshot_test_wrap(y)), "key")
})

test_that("key matching does not concatenate codes with ambiguous delimiters", {
  x <- snapshot_test_data()[1:2, ]
  x$TimeDim <- 2020L
  x$TimeDimensionValue <- "2020"
  x$Dim1 <- c("A|B", "A")
  x$Dim2 <- c("C", "B|C")
  y <- x[2:1, ]
  y$NumericValue[1] <- 13
  out <- compare_snapshots(snapshot_test_wrap(x), snapshot_test_wrap(y))
  expect_equal(out$summary$n_modified, 1)
  expect_equal(out$modified$old_value, 12)
  x <- snapshot_test_data()
  x$extra_coordinate <- c(1, 1 + 1e-15, 1, 1)
  y <- x
  y$extra_coordinate[1] <- 1 + 1e-15
  out <- compare_snapshots(snapshot_test_wrap(x, key = "extra_coordinate"),
                           snapshot_test_wrap(y, key = "extra_coordinate"))
  expect_equal(out$summary$n_added, 1)
  expect_equal(out$summary$n_removed, 1)
  x$extra_coordinate <- 0
  y <- x
  y$extra_coordinate <- -0
  out <- compare_snapshots(snapshot_test_wrap(x, key = "extra_coordinate"),
                           snapshot_test_wrap(y, key = "extra_coordinate"))
  expect_equal(out$summary$n_unchanged, 4)
})

test_that("RDS round trips and cleaned frames support the same offline workflow", {
  x <- snapshot_test_data()
  y <- x
  y$NumericValue[1] <- 11
  old_path <- withr::local_tempfile(fileext = ".rds")
  new_path <- withr::local_tempfile(fileext = ".rds")
  data_snapshot(x, old_path)
  data_snapshot(y, new_path)
  testthat::local_mocked_bindings(.dsi_request = function(...) stop("Unexpected network call"), .package = "DSIR")
  out <- compare_snapshots(old_path, new_path)
  expect_equal(out$summary$n_modified, 1)
  clean <- function(data) gho_clean(data, keep_dimensions = TRUE, keep_metadata = TRUE)
  cleaned <- compare_snapshots(snapshot_test_wrap(clean(x)), snapshot_test_wrap(clean(y)))
  expect_equal(cleaned$summary$n_modified, 1)
  expect_equal(cleaned$modified$old_value, 10)
  expect_equal(cleaned$modified$new_value, 11)
})

test_that("corrupt, legacy-cache or unsupported snapshot files fail clearly", {
  a <- snapshot_test_wrap(snapshot_test_data())
  expect_error(compare_snapshots(snapshot_test_data(), a), "schema-version")
  path <- withr::local_tempfile(fileext = ".rds")
  saveRDS(a$data, path)
  expect_error(compare_snapshots(path, a), "schema-version")
  expect_error(compare_snapshots(paste0(path, ".absent"), a), "does not exist")
  b <- a
  b$schema_version <- 2L
  expect_error(compare_snapshots(a, b), "schema-version")
  b <- a
  b$data <- rbind(b$data, b$data[1, ])
  expect_error(compare_snapshots(a, b), "Duplicate observation key")
  b <- a
  b$data$Dim1Type <- NULL
  expect_error(compare_snapshots(a, b), "Missing GHO identity")
  expect_error(compare_snapshots(a, a, fields = "absent"), "fields")
  expect_error(compare_snapshots(a, a, fields = "Dim1"), "fields")
})
