test_that("gho_data handles long area vectors via in operator", {
  skip_on_cran()
  skip_if_offline()
  
  result <- gho_data("MDG_0000000026", 
                     spatial_type = "country",
                     area = wpro_cty)
  expect_s3_class(result, "tbl_df")
  expect_gt(nrow(result), 0)
  expect_true(all(result$SpatialDim %in% wpro_cty))
})

test_that("gho_data validates area input", {
  expect_error(gho_data("X", spatial_type = "country", area = c("PHL", NA)))
  expect_error(gho_data("X", spatial_type = "country", area = c("PHL", "")))
  expect_error(gho_data("X", spatial_type = "country", area = 123))
})

test_that("gho_data infers country when area given without spatial_type", {
  skip_on_cran()
  skip_if_offline()

  expect_message(
    gho_data("MDG_0000000026", area = "PHL"),
    regexp = "country"
  )
})

# Filter extracted from a built URL — decoded so the assertions read clearly.
gho_indicators_filter <- function(url) {
  utils::URLdecode(sub(".*\\$filter=", "", url))
}

test_that("gho_indicators builds a single-term filter (backward compatible)", {
  url <- .gho_indicators_build_url("mortality")
  expect_equal(
    gho_indicators_filter(url),
    "contains(tolower(IndicatorName),'mortality')"
  )
})

test_that("gho_indicators splits a string on whitespace into AND-ed terms", {
  url <- .gho_indicators_build_url("child mortality")
  expect_equal(
    gho_indicators_filter(url),
    "contains(tolower(IndicatorName),'child') and contains(tolower(IndicatorName),'mortality')"
  )
})

test_that("gho_indicators uses a character vector as terms directly", {
  url <- .gho_indicators_build_url(c("child", "mortality"))
  expect_equal(
    gho_indicators_filter(url),
    "contains(tolower(IndicatorName),'child') and contains(tolower(IndicatorName),'mortality')"
  )
})

test_that("gho_indicators escapes single quotes in search terms", {
  url <- .gho_indicators_build_url("alzheimer's")
  expect_equal(
    gho_indicators_filter(url),
    "contains(tolower(IndicatorName),'alzheimer''s')"
  )
})