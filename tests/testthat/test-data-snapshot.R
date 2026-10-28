test_that("data_snapshot preserves complete observations and distinct times", {
  x <- snapshot_test_data()
  out <- data_snapshot(x)
  expect_s3_class(out, "dsir_data_snapshot")
  expect_identical(out$schema_version, 1L)
  expect_identical(out$data, x)
  expect_identical(out$provenance, attr(x, "who_provenance"))
  expect_s3_class(out$created_at, "POSIXct")
  expect_identical(attr(out$created_at, "tzone"), "UTC")
  expect_identical(out$retrieved_at, "2026-10-27 00:00:00")
  expect_identical(out$data$Date, x$Date)
  expect_identical(out$source_timestamp_fields, "Date")
  expect_identical(out$source, "gho")
  expect_identical(out$backend, "legacy")
  expect_identical(out$indicator, "EXAMPLE")
  expect_identical(out$scope$kind, "recorded")
  expect_true(all(c("Dim1Type", "Dim1", "Dim2Type", "Dim2",
    "TimeDimType", "DataSourceDim") %in% out$key))
  expect_false(any(c("Id", "Date", "NumericValue") %in% out$key))
})

test_that("data_snapshot writes ordinary RDS without silent overwrite", {
  parent <- withr::local_tempdir()
  path <- file.path(parent, "nested", "old.rds")
  x <- snapshot_test_data()
  saved <- data_snapshot(x, path)
  expect_true(file.exists(path))
  expect_identical(readRDS(path), saved)
  expect_identical(readRDS(path)$data, x)
  changed <- x
  changed$NumericValue[1] <- 13
  expect_error(data_snapshot(changed, path), "already exists")
  expect_identical(readRDS(path), saved)
  data_snapshot(changed, path, overwrite = TRUE)
  expect_identical(readRDS(path)$data, changed)
})

test_that("snapshots never infer origins from session defaults", {
  x <- snapshot_test_data()
  x$Provider <- NULL
  attr(x, "who_provenance") <- NULL
  withr::local_options(DSIR.who_backend = "xmart")
  expect_error(data_snapshot(x, scope = snapshot_test_scope()), "backend")
  out <- data_snapshot(x, backend = "legacy", scope = snapshot_test_scope())
  expect_identical(out$backend, "legacy")
  expect_true(is.na(out$retrieved_at))
  expect_length(out$provenance, 0L)
  x$Provider <- c("legacy", NA_character_, "legacy", "legacy")
  expect_error(data_snapshot(x, scope = snapshot_test_scope()), "Missing recorded backend")
  expect_identical(data_snapshot(x, backend = "legacy", scope = snapshot_test_scope())$backend, "legacy")
})

test_that("snapshot scope requires a recorded complete selection or declaration", {
  x <- snapshot_test_data()
  expect_error(data_snapshot(x[1:2, ]), "scope cannot be verified")
  subset <- snapshot_test_wrap(x[1:2, ])
  expect_equal(nrow(subset$data), 2L)
  expect_identical(subset$scope$kind, "declared")
  attr(x, "who_provenance")$complete <- FALSE
  expect_error(snapshot_test_wrap(x), "incomplete")
  attr(x, "who_provenance") <- list(backend = "legacy", complete = TRUE, rows = 4L)
  expect_error(data_snapshot(x), "query URL")
})

test_that("scope canonicalizes named sets without guessing observed coverage", {
  x <- snapshot_test_data()
  a <- data_snapshot(x, scope = list(area = c("PHL", "FJI"), years = list(from = 2020L, to = NULL)))
  b <- data_snapshot(x, scope = list(years = list(to = NULL, from = 2020), area = c("FJI", "PHL", "FJI")))
  expect_identical(a$scope, b$scope)
  expect_equal(compare_snapshots(a, b)$summary$n_unchanged, 4)
  for (scope in list(list(), "PHL", list(area = NA_character_),
    list(area = ""), list(year = Inf), list(area = list("PHL")))) {
    expect_error(data_snapshot(x, scope = scope), "scope|Scope")
  }
})

test_that("identity conflicts and mixed sources are rejected", {
  x <- snapshot_test_data()
  expect_error(data_snapshot(x, backend = "xmart"), "disagrees")
  expect_error(data_snapshot(x, indicator = "OTHER"), "disagrees")
  expect_error(data_snapshot(x, source = "sdg"), "GHO only")
  x$IndicatorCode[2] <- "OTHER"
  expect_error(snapshot_test_wrap(x), "one.*indicator")
  x <- snapshot_test_data()
  x$Provider[2] <- "xmart"
  expect_error(snapshot_test_wrap(x), "one.*backend")
  x <- snapshot_test_data()
  x$source <- "sdg"
  expect_error(snapshot_test_wrap(x), "GHO only")
})

test_that("core identity and active dimension type/code pairs are mandatory", {
  x <- snapshot_test_data()
  expect_error(snapshot_test_wrap(x[, setdiff(names(x), "Dim1Type")]), "Missing GHO identity")
  x$Dim1Type[1] <- NA_character_
  expect_error(snapshot_test_wrap(x), "missing type or code")
  x <- snapshot_test_data()
  x$SpatialDim[1] <- NA_character_
  expect_error(snapshot_test_wrap(x), "Missing core observation")
  x <- snapshot_test_data()
  x$Dim2[1] <- NA_character_
  expect_error(snapshot_test_wrap(x), "missing type or code")
  x <- snapshot_test_data()
  x$Dim3Type <- x$Dim3 <- rep(NA, 4)
  expect_s3_class(snapshot_test_wrap(x), "dsir_data_snapshot")
})

test_that("cleaned snapshots require the full retained identity context", {
  x <- snapshot_test_data()
  expect_error(snapshot_test_wrap(gho_clean(x)), "Missing GHO identity")
  clean <- gho_clean(x, keep_dimensions = TRUE, keep_metadata = TRUE)
  out <- snapshot_test_wrap(clean)
  expect_identical(out$data, clean)
  expect_true(all(c("id", "spatial_type", "time_type", "dim1_type", "dim2") %in% out$key))
  expect_identical(out$primary_value, "value_num")
  expect_identical(out$source_timestamp_fields, "updated")
})

test_that("all named xMart dimensions and measure context are retained", {
  x <- snapshot_test_data()
  x$Provider <- "xmart"
  x$DIM_SEX <- rep(c("MALE", "FEMALE"), 2)
  x$DIM_AGE <- "YEARS15-49"
  x$DIM_WEALTH <- rep(c("Q1", "Q2"), 2)
  x$Unit <- "%"
  x$MeasureField <- "RATE_PER_100_N"
  attr(x, "who_provenance") <- list(backend = "xmart",
    base_url = "https://xmart-api-public.who.int", table = "DATA_/RELAY_EXAMPLE",
    filter = "(IND_ID eq 'EXAMPLE')", retrieved = "2026-10-27 00:00:00",
    complete = TRUE, rows = 4L)
  out <- data_snapshot(x)
  expect_true(all(c("DIM_SEX", "DIM_AGE", "DIM_WEALTH", "Unit", "MeasureField") %in% out$key))
  expect_false("DataSourceDim" %in% out$key)
  expect_identical(out$data, x)
  y <- x
  y$MeasureField[1] <- NA_character_
  expect_error(data_snapshot(y), "missing measure family")
  attr(y, "who_provenance")$filter <- NULL
  y$MeasureField <- x$MeasureField
  expect_error(data_snapshot(y), "table/filter")
})

test_that("higher dimension positions participate in identity", {
  x <- snapshot_test_data()
  x$Provider <- "xmart"
  attr(x, "who_provenance")$backend <- "xmart"
  x$DIM_4_CODE <- "DIM_EDUCATION"
  x$DIM_MEMBER_4_CODE <- "TOTAL"
  out <- snapshot_test_wrap(x)
  expect_true(all(c("DIM_4_CODE", "DIM_MEMBER_4_CODE") %in% out$key))
  x$DIM_MEMBER_4_CODE[1] <- NA_character_
  expect_error(snapshot_test_wrap(x), "missing type or code")
})

test_that("duplicate keys fail and additional semantic dimensions are explicit", {
  x <- snapshot_test_data()
  duplicate <- rbind(x, x[1, ])
  duplicate$Id <- seq_len(nrow(duplicate))
  expect_error(snapshot_test_wrap(duplicate), "Duplicate observation key")
  expect_error(snapshot_test_wrap(duplicate, key = "Id"), "cannot be observation keys")
  expect_error(snapshot_test_wrap(duplicate, key = "NumericValue"), "cannot be observation keys")
  duplicate$survey_round <- c(rep("A", 4), "B")
  out <- snapshot_test_wrap(duplicate, key = "survey_round")
  expect_true("survey_round" %in% out$key)
  expect_true(all(c("Dim1", "Dim1Type") %in% out$key))
  expect_error(snapshot_test_wrap(x, key = "absent"), "key")
  expect_error(snapshot_test_wrap(x, value_fields = "Value"), "primary numeric")
  expect_error(snapshot_test_wrap(x, value_fields = c("NumericValue", "Dim1")), "overlap")
})

test_that("empty selections need a retained schema and explicit indicator", {
  expect_error(data_snapshot(tibble::tibble()), "identity schema")
  empty <- snapshot_test_data()[0, ]
  expect_error(snapshot_test_wrap(empty), "indicator")
  out <- snapshot_test_wrap(empty, indicator = "EXAMPLE")
  expect_equal(nrow(out$data), 0)
})

test_that("obvious credentials and unsupported objects cannot be saved", {
  x <- snapshot_test_data()
  path <- withr::local_tempfile(fileext = ".rds")
  x$api_key <- "sensitive-example"
  expect_error(snapshot_test_wrap(x, file = path), "Credential")
  expect_false(file.exists(path))
  x <- snapshot_test_data()
  attr(x, "api_token") <- "sensitive-example"
  expect_error(snapshot_test_wrap(x), "Credential")
  x <- snapshot_test_data()
  expect_error(data_snapshot(x, scope = list(url = "https://user:pass@example.org/data")), "authenticated URL")
  expect_error(data_snapshot(x, scope = list(url = "https://example.org/data?token=hidden")), "Credential")
  x$Comments[1] <- "Bearer abcdefghijklmnop"
  expect_error(snapshot_test_wrap(x), "Credential")
  x <- snapshot_test_data()
  attr(x, "local_context") <- new.env()
  expect_error(snapshot_test_wrap(x), "unsupported objects")
})

test_that("snapshot arguments are validated before writing", {
  x <- snapshot_test_data()
  expect_error(data_snapshot(x, file = ""), "non-empty")
  expect_error(data_snapshot(x, file = c("a", "b")), "single")
  expect_error(data_snapshot(x, file = withr::local_tempdir()), "directory")
  expect_error(data_snapshot(x, overwrite = NA), "logical")
  expect_error(data_snapshot(list(a = 1)), "data frame")
  x$NumericValue <- as.character(x$NumericValue)
  expect_error(snapshot_test_wrap(x), "must be numeric")
})

test_that("ordinary basic health terminology is preserved without allowing Basic credentials", {
  x <- snapshot_test_data()
  x$IndicatorName <- "Population using basic sanitation services"
  x$Comments <- "Basic immunization"
  expect_identical(snapshot_test_wrap(x)$data, x)
  for (credential in c("Basic dXNlcjpwYXNz", "Basic dTpw")) {
    x$Comments[1] <- credential
    expect_error(snapshot_test_wrap(x), "Credential")
  }
})
