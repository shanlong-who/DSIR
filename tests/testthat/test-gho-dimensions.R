# Unit tests for gho_dimensions(). Uses httr2 mocked responses so the
# tests run offline (and on CRAN).

skip_if_not_installed("httptest2")

mock_json <- function(body, status = 200L) {
  list(httr2::response(
    status_code = status,
    headers     = list(`content-type` = "application/json"),
    body        = charToRaw(body)
  ))
}

# ── Input validation (runs without any HTTP call) ────────────────────

test_that("gho_dimensions validates the indicator argument", {
  expect_error(gho_dimensions(123),         "is.character")
  expect_error(gho_dimensions(c("A", "B")), "length")
  expect_error(gho_dimensions(""),          "nzchar")
})

test_that("gho_dimensions validates the dimension argument", {
  expect_error(gho_dimensions("X", dimension = 1L),
               "is.character")
  expect_error(gho_dimensions("X", dimension = c("a", "b")),
               "length")
})

# ── Behaviour under mocked GHO responses ─────────────────────────────

test_that("gho_dimensions returns sorted unique values of the requested column", {
  # Three rows; SpatialDimType has two distinct values plus an NA. The
  # NA must be dropped and the result must be sorted.
  body <- paste0(
    '{"value":[',
    '{"SpatialDimType":"REGION","Dim1":"BTSX"},',
    '{"SpatialDimType":"COUNTRY","Dim1":"MLE"},',
    '{"SpatialDimType":"COUNTRY","Dim1":null},',
    '{"SpatialDimType":null,"Dim1":"FMLE"}',
    ']}'
  )
  httr2::with_mocked_responses(mock_json(body), {
    out <- gho_dimensions("X")  # default dimension = SpatialDimType
    expect_type(out, "character")
    expect_equal(out, c("COUNTRY", "REGION"))
  })
})

test_that("gho_dimensions picks the requested dimension column", {
  body <- paste0(
    '{"value":[',
    '{"SpatialDimType":"COUNTRY","Dim1":"BTSX"},',
    '{"SpatialDimType":"COUNTRY","Dim1":"MLE"},',
    '{"SpatialDimType":"COUNTRY","Dim1":"FMLE"}',
    ']}'
  )
  httr2::with_mocked_responses(mock_json(body), {
    out <- gho_dimensions("X", dimension = "Dim1")
    expect_equal(out, c("BTSX", "FMLE", "MLE"))  # sorted
  })
})

test_that("gho_dimensions returns empty character when dimension column is missing", {
  # SpatialDimType absent from the response — function should return
  # character(0), not error.
  body <- '{"value":[{"Dim1":"BTSX"},{"Dim1":"MLE"}]}'
  httr2::with_mocked_responses(mock_json(body), {
    out <- gho_dimensions("X")  # default dimension = SpatialDimType
    expect_type(out, "character")
    expect_length(out, 0L)
  })
})

test_that("gho_dimensions returns empty character on HTTP failure", {
  httr2::with_mocked_responses(
    mock_json('{"error":"not found"}', status = 404L),
    {
      out <- suppressWarnings(gho_dimensions("MISSING"))
      expect_type(out, "character")
      expect_length(out, 0L)
    }
  )
})
