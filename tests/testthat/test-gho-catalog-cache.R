# Regression tests for .gho_indicator_catalog(): a failed catalog
# fetch now returns a bundled snapshot, which must not be cached as live
# data, so the next call can retry once the network is
# back. Before the 0.8.0 fix, one offline first call poisoned the
# session cache and gho_clean()'s indicator column stayed NA for the
# rest of the session.

skip_if_not_installed("httptest2")

mock_json <- function(body, status = 200L) {
  list(httr2::response(
    status_code = status,
    headers     = list(`content-type` = "application/json"),
    body        = charToRaw(body)
  ))
}

catalog_body <- paste0(
  '{"value":[{"IndicatorCode":"X1",',
  '"IndicatorName":"Test indicator","Language":"EN"}]}'
)

test_that("a failed catalog fetch is not cached and is retried on the next call", {
  withr::local_options(DSIR.who_backend = "legacy")
  old <- .dsi_cache$gho_indicator_catalog
  on.exit(.dsi_cache$gho_indicator_catalog <- old)
  .dsi_cache$gho_indicator_catalog <- NULL

  # First call: HTTP failure -> bundled catalog, which must NOT be cached.
  # 404 is not retried by req_retry, so a single mocked response is enough.
  suppressWarnings(
    httr2::with_mocked_responses(
      mock_json('{"error":"down"}', status = 404L),
      out1 <- DSIR:::.gho_indicator_catalog()
    )
  )
  expect_gt(nrow(out1), 0L)
  expect_equal(attr(out1, "catalog_snapshot")$backend, "legacy")
  expect_null(.dsi_cache$gho_indicator_catalog)

  # Second call: the fetch succeeds -> cached and returned.
  httr2::with_mocked_responses(
    mock_json(catalog_body),
    out2 <- DSIR:::.gho_indicator_catalog()
  )
  expect_equal(out2$IndicatorName, "Test indicator")
  expect_equal(nrow(.dsi_cache$gho_indicator_catalog), 1L)
})

test_that("gho_clean resolves indicator names on retry after an offline first call", {
  withr::local_options(DSIR.who_backend = "legacy")
  old <- .dsi_cache$gho_indicator_catalog
  on.exit(.dsi_cache$gho_indicator_catalog <- old)
  .dsi_cache$gho_indicator_catalog <- NULL

  df <- data.frame(
    IndicatorCode = "X1",
    SpatialDim    = "PHL",
    TimeDim       = 2020L,
    Value         = "1",
    NumericValue  = 1
  )

  suppressWarnings(
    httr2::with_mocked_responses(
      mock_json('{"error":"down"}', status = 404L),
      out1 <- gho_clean(df)
    )
  )
  expect_true(is.na(out1$indicator))

  httr2::with_mocked_responses(
    mock_json(catalog_body),
    out2 <- gho_clean(df)
  )
  expect_equal(out2$indicator, "Test indicator")
})
