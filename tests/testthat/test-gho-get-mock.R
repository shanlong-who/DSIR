# Offline regression tests for .gho_get() and the gho_*() callers that
# wrap it. Uses httr2 mocked responses so these run on CRAN and on
# machines without internet. Each test guards an explicit fix that is
# described in NEWS.md.

skip_if_not_installed("httptest2")  # Suggests dependency

# Build a canned JSON response wrapped in a length-1 list, which is the
# form httr2::with_mocked_responses() expects for "return this single
# response to every request inside the block".
mock_json <- function(body, status = 200L) {
  list(httr2::response(
    status_code = status,
    headers     = list(`content-type` = "application/json"),
    body        = charToRaw(body)
  ))
}

test_that(".gho_get returns an empty tibble when GHO sends value = []", {
  # NEWS 0.6.0: the previous implementation produced a spurious 1x1
  # list-column tibble for an empty `value` field. We assert the fix.
  httr2::with_mocked_responses(
    mock_json('{"value": []}'),
    {
      out <- DSIR:::.gho_get("https://example.test/api/X")
      expect_s3_class(out, "tbl_df")
      expect_equal(nrow(out), 0L)
    }
  )
})

test_that(".gho_get follows @odata.nextLink and concatenates pages", {
  page1 <- paste0(
    '{"value":[',
    '{"IndicatorCode":"X","SpatialDim":"FRA","TimeDim":2019,"NumericValue":1}',
    '],"@odata.nextLink":"https://example.test/api/X?$skip=1"}'
  )
  page2 <- paste0(
    '{"value":[',
    '{"IndicatorCode":"X","SpatialDim":"DEU","TimeDim":2019,"NumericValue":2}',
    ']}'
  )
  # Two-page response — flatten the two single-element response lists
  # into one list of two responses, consumed in order.
  httr2::with_mocked_responses(
    c(mock_json(page1), mock_json(page2)),
    {
      out <- DSIR:::.gho_get("https://example.test/api/X")
      expect_equal(nrow(out), 2L)
      expect_setequal(out$SpatialDim, c("FRA", "DEU"))
    }
  )
})

test_that(".gho_get returns NULL with a warning when GHO errors out", {
  # 404 is not retried (req_retry only retries on 5xx / 429 / network),
  # so a single mocked 404 lands in the tryCatch and triggers the
  # cli_warn + NULL return that .gho_get advertises.
  httr2::with_mocked_responses(
    mock_json('{"error":"not found"}', status = 404L),
    {
      expect_warning(
        out <- DSIR:::.gho_get("https://example.test/api/X"),
        "GHO request failed"
      )
      expect_null(out)
    }
  )
})

test_that("gho_data returns an empty tibble on request failure", {
  httr2::with_mocked_responses(
    mock_json('{"error":"not found"}', status = 404L),
    {
      out <- suppressWarnings(
        gho_data("X", spatial_type = "country", area = "FRA")
      )
      expect_s3_class(out, "tbl_df")
      expect_equal(nrow(out), 0L)
    }
  )
})

test_that("gho_indicators returns an empty 3-col tibble on request failure", {
  httr2::with_mocked_responses(
    mock_json('{"error":"oops"}', status = 404L),
    {
      out <- suppressWarnings(gho_indicators("mortality"))
      expect_s3_class(out, "tbl_df")
      expect_named(out, c("IndicatorCode", "IndicatorName", "Language"))
      expect_equal(nrow(out), 0L)
    }
  )
})

test_that("gho_data() sends area filter using the OData 'in' operator", {
  # NEWS 0.5.0: switched from chained OR to `SpatialDim in (...)` to
  # avoid HTTP 400 on long area vectors. Verify the URL form.
  captured <- character()
  mock_fn <- function(req) {
    captured[[length(captured) + 1L]] <<- req$url
    httr2::response(
      status_code = 200L,
      headers     = list(`content-type` = "application/json"),
      body        = charToRaw('{"value": []}')
    )
  }
  httr2::with_mocked_responses(mock_fn, {
    gho_data("X", spatial_type = "country",
             area = c("FRA", "DEU", "JPN"))
  })
  expect_length(captured, 1L)
  decoded <- utils::URLdecode(captured[1])
  expect_match(decoded, "SpatialDim in ('FRA','DEU','JPN')", fixed = TRUE)
})

test_that(".gho_get returns NULL with a warning on a malformed JSON body", {
  # NEWS 0.7.0: a truncated upstream body (premature EOF) reaches
  # resp_body_json() as unparseable JSON. The body-parse tryCatch must
  # downgrade the jsonlite error to a warning + NULL, the same way an
  # HTTP failure is handled. Without it the parse error would propagate
  # and break R CMD check examples.
  httr2::with_mocked_responses(
    mock_json('{"value": [{"SpatialDim":"FRA"'),  # truncated, unparseable
    {
      expect_warning(
        out <- DSIR:::.gho_get("https://example.test/api/X"),
        "could not be parsed as JSON"
      )
      expect_null(out)
    }
  )
})

test_that("gho_count returns NA on a malformed JSON body", {
  # NEWS 0.7.0: gho_count() has its own HTTP call site (it needs
  # @odata.count, not value), so it carries its own body-parse
  # tryCatch. A truncated body must yield NA_integer_, not an error.
  httr2::with_mocked_responses(
    mock_json('{"@odata.count": 4'),  # truncated, unparseable
    {
      expect_warning(
        n <- gho_count("X", spatial_type = "country", area = "FRA"),
        "could not be parsed as JSON"
      )
      expect_identical(n, NA_integer_)
    }
  )
})
