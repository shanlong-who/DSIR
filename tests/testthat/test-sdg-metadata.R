metadata_response <- function(body, status = 200L) {
  httr2::response(status_code = status,
                  headers = list(`content-type` = "application/json"),
                  body = charToRaw(body))
}

metadata_catalog <- function() {
  metadata_response('[{"code":"3.8.2","series":[{"code":"S1"},{"code":"S2"}]}]')
}

test_that("sdg_dimensions returns official names, labels, and distinct SDMX codes", {
  dims <- metadata_response(paste0(
    '[{"id":"Sex","codes":[',
    '{"code":"BOTHSEX","description":"Both sexes","sdmx":"_T"},',
    '{"code":"FEMALE","description":"Female","sdmx":"F"}]}]'
  ))
  attrs <- metadata_response(paste0(
    '[{"id":"Units","codes":[',
    '{"code":"PERCENT","description":"Percentage","sdmx":"PT"}]}]'
  ))
  urls <- character()
  pages <- list(metadata_catalog(), dims, attrs)
  mock <- function(req) {
    urls <<- c(urls, req$url)
    pages[[length(urls)]]
  }
  out <- httr2::with_mocked_responses(mock, {
    sdg_dimensions("3.8.2", series = "S1", include_attributes = TRUE)
  })
  expect_named(out, c("indicator", "series", "kind", "dimension", "code", "label", "sdmx"))
  expect_equal(nrow(out), 3L)
  expect_equal(unique(out$series), "S1")
  expect_equal(out$label[out$code == "BOTHSEX"], "Both sexes")
  expect_equal(out$sdmx[out$code == "BOTHSEX"], "_T")
  expect_equal(out$kind[out$code == "PERCENT"], "attribute")
  expect_match(urls[[1]], "Indicator/3.8.2/Series/List", fixed = TRUE)
  expect_match(urls[[2]], "Series/S1/Dimensions", fixed = TRUE)
  expect_match(urls[[3]], "Series/S1/Attributes", fixed = TRUE)
  expect_false(any(grepl("Indicator/Data", urls, fixed = TRUE)))
})

test_that("metadata for different SDG series stays separate", {
  first <- metadata_response('[{"id":"Age","codes":[{"code":"A","description":"Adult"}]}]')
  second <- metadata_response('[{"id":"Age","codes":[{"code":"A","description":"All ages"}]}]')
  httr2::with_mocked_responses(list(metadata_catalog(), first, second), {
    out <- sdg_dimensions("3.8.2")
    expect_equal(out$series, c("S1", "S2"))
    expect_equal(out$label, c("Adult", "All ages"))
    expect_true(all(is.na(out$sdmx)))
  })
})

test_that("an SDG metadata failure cannot return a partial code list", {
  valid <- metadata_response('[{"id":"Sex","codes":[{"code":"FEMALE"}]}]')
  failure <- metadata_response("{}", 404L)
  httr2::with_mocked_responses(list(metadata_catalog(), valid, failure), {
    expect_warning(out <- sdg_dimensions("3.8.2"), "SDG request failed")
    expect_equal(nrow(out), 0L)
    expect_type(out$label, "character")
  })
  httr2::with_mocked_responses(list(failure), {
    expect_warning(out <- sdg_dimensions("3.8.2"), "SDG request failed")
    expect_equal(nrow(out), 0L)
  })
})

test_that("unknown series and malformed SDG metadata produce clear warnings", {
  httr2::with_mocked_responses(list(metadata_catalog()), {
    expect_warning(out <- sdg_dimensions("3.8.2", "UNKNOWN"), "not linked")
    expect_equal(nrow(out), 0L)
  })
  httr2::with_mocked_responses(list(metadata_response("{}")), {
    expect_warning(out <- sdg_dimensions("3.8.2"), "invalid structure")
    expect_equal(nrow(out), 0L)
  })
  bad <- metadata_response('[{"id":"Sex","codes":[{"oops":"FEMALE"}]}]')
  httr2::with_mocked_responses(list(metadata_catalog(), bad), {
    expect_warning(out <- sdg_dimensions("3.8.2", "S1"), "invalid structure")
    expect_equal(nrow(out), 0L)
  })
})

test_that("empty SDG code lists and missing labels are retained without invention", {
  dims <- metadata_response('[{"id":"Empty","codes":[]},{"id":"Age","codes":[{"code":"X"}]}]')
  httr2::with_mocked_responses(list(metadata_catalog(), dims), {
    out <- sdg_dimensions("3.8.2", "S1")
    expect_setequal(out$dimension, c("Empty", "Age"))
    expect_true(all(is.na(out$label)))
    expect_true(is.na(out$code[out$dimension == "Empty"]))
  })
  httr2::with_mocked_responses(list(metadata_catalog(), metadata_response("[]")), {
    out <- sdg_dimensions("3.8.2", "S1")
    expect_equal(nrow(out), 0L)
    expect_type(out$code, "character")
  })
})

test_that("sdg_dimensions validates arguments before requesting metadata", {
  expect_error(sdg_dimensions(c("3.8.1", "3.8.2")), "single non-empty")
  expect_error(sdg_dimensions(NA_character_), "single non-empty")
  expect_error(sdg_dimensions("3.8.2", include_attributes = NA), "single logical")
})
