snapshot_test_data <- function() {
  x <- tibble::tibble(
    Id = 1:4, IndicatorCode = "EXAMPLE", IndicatorName = "Example indicator",
    SpatialDimType = "COUNTRY", SpatialDim = "PHL",
    TimeDimType = "YEAR", TimeDim = c(2020L, 2020L, 2021L, 2021L),
    TimeDimensionValue = c("2020", "2020", "2021", "2021"),
    Dim1Type = "SEX", Dim1 = rep(c("SEX_MLE", "SEX_FMLE"), 2L),
    Dim2Type = "AGEGROUP", Dim2 = "AGEGROUP_YEARS15-49",
    Dim3Type = NA_character_, Dim3 = NA_character_,
    DataSourceDimType = "DATASOURCE", DataSourceDim = "DATASOURCE_EXAMPLE",
    NumericValue = c(10, 12, 20, 22), Value = c("10", "12", "20", "22"),
    Low = c(8, 10, 18, 20), High = c(12, 14, 22, 24),
    Comments = NA_character_, Date = "2026-01-01T12:00:00+01:00",
    Provider = "legacy")
  attr(x, "who_provenance") <- list(backend = "legacy",
    base_url = "https://ghoapi.azureedge.net",
    query_url = paste0("https://ghoapi.azureedge.net/api/EXAMPLE?",
      "$filter=SpatialDim%20eq%20%27PHL%27%20and%20TimeDim%20ge%202020"),
    retrieved = "2026-10-27 00:00:00", complete = TRUE, rows = 4L)
  x
}

snapshot_test_scope <- function() {
  list(area = "PHL", spatial_type = "country", year_from = 2020L, year_to = NULL)
}

snapshot_test_wrap <- function(data, ...) {
  data_snapshot(data, scope = snapshot_test_scope(), ...)
}
