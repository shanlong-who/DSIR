#' List GHO Indicators
#'
#' Fetches the catalog of indicators from the WHO Global Health
#' Observatory (GHO) OData API.
#'
#' @param search Optional character string. If supplied, only
#'   indicators whose name contains `search` (case-insensitive)
#'   are returned.
#'
#' @return A data frame with columns `IndicatorCode`,
#'   `IndicatorName` and `Language`. Returns an empty data frame
#'   (with a message) when the service is unreachable.
#' @seealso [gho_data()], [gho_dimensions()].
#' @export
#'
#' @examples
#' \dontrun{
#' # All indicators
#' inds <- gho_indicators()
#'
#' # Search by keyword
#' gho_indicators("mortality")
#' }
gho_indicators <- function(search = NULL) {
  base_url <- "https://ghoapi.azureedge.net/api/Indicator"

  if (!is.null(search)) {
    filter <- paste0("contains(tolower(IndicatorName),'", tolower(search), "')")
    url <- paste0(base_url, "?$filter=", utils::URLencode(filter, reserved = TRUE))
  } else {
    url <- base_url
  }

  res <- .gho_get(url)
  if (is.null(res) || nrow(res) == 0L) {
    return(data.frame(IndicatorCode = character(),
                      IndicatorName = character(),
                      Language = character()))
  }
  res[, c("IndicatorCode", "IndicatorName", "Language")]
}


#' Fetch GHO Data
#'
#' Retrieves observations for a specific indicator from the WHO GHO
#' OData API, with optional filters by spatial level, country /
#' region and year range.
#'
#' @param indicator Character scalar. The indicator code
#'   (e.g. `"NCDMORT3070"`). Use [gho_indicators()] to find codes.
#' @param spatial_type Character. Spatial dimension to filter on:
#'   one of `"country"`, `"region"`, `"global"`, or `NULL` (all
#'   levels, the default).
#' @param area Character vector of country or region codes
#'   (e.g. `c("FRA", "DEU")`). Default `NULL` returns all areas.
#' @param year_from Numeric. Start year filter (inclusive).
#'   Default `NULL`.
#' @param year_to Numeric. End year filter (inclusive).
#'   Default `NULL`.
#'
#' @return A data frame of indicator observations, or an empty
#'   data frame when the service is unreachable.
#' @seealso [gho_indicators()], [gho_dimensions()].
#' @export
#'
#' @examples
#' \dontrun{
#' # Country-level data for one indicator
#' gho_data("NCDMORT3070", spatial_type = "country")
#'
#' # Specific countries and years
#' gho_data("WHOSIS_000001", area = c("FRA", "DEU"), year_from = 2015)
#' }
gho_data <- function(indicator, spatial_type = NULL, area = NULL,
                     year_from = NULL, year_to = NULL) {
  stopifnot(is.character(indicator), length(indicator) == 1L, nzchar(indicator))
  base_url <- paste0("https://ghoapi.azureedge.net/api/", indicator)

  filters <- character(0)

  if (!is.null(spatial_type)) {
    spatial_type <- tolower(spatial_type)
    st <- switch(spatial_type,
      country = "COUNTRY",
      region  = "REGION",
      global  = "GLOBAL",
      cli::cli_abort("Unknown {.arg spatial_type}: {.val {spatial_type}}. Use \"country\", \"region\", or \"global\".")
    )
    filters <- c(filters, paste0("SpatialDimType eq '", st, "'"))
  }

  if (!is.null(area)) {
    area_filter <- paste0("SpatialDim eq '", area, "'", collapse = " or ")
    filters <- c(filters, paste0("(", area_filter, ")"))
  }

  if (!is.null(year_from)) {
    filters <- c(filters, paste0("TimeDim ge ", year_from))
  }
  if (!is.null(year_to)) {
    filters <- c(filters, paste0("TimeDim le ", year_to))
  }

  if (length(filters) > 0) {
    filter_str <- paste(filters, collapse = " and ")
    url <- paste0(base_url, "?$filter=", utils::URLencode(filter_str, reserved = TRUE))
  } else {
    url <- base_url
  }

  res <- .gho_get(url)
  if (is.null(res)) data.frame() else res
}


#' List Dimensions of a GHO Indicator
#'
#' Returns the unique values of a given dimension across all
#' observations of a GHO indicator. Useful for discovering which
#' ages, sexes, regions, or other breakdowns are available before
#' calling [gho_data()].
#'
#' @param indicator Character scalar. The indicator code
#'   (e.g. `"NCDMORT3070"`).
#' @param dimension Character. Name of the dimension column in the
#'   indicator data. Common values include `"SpatialDim"`,
#'   `"SpatialDimType"`, `"TimeDim"`, `"Dim1"`, `"Dim2"`, and
#'   `"Dim3"`. Default `"SpatialDimType"`.
#'
#' @return A character vector of unique, sorted dimension values,
#'   or an empty character vector when the service is unreachable
#'   or the dimension is missing.
#' @seealso [gho_data()], [gho_indicators()].
#' @export
#'
#' @examples
#' \dontrun{
#' gho_dimensions("NCDMORT3070")
#' gho_dimensions("NCDMORT3070", dimension = "Dim1")
#' }
gho_dimensions <- function(indicator, dimension = "SpatialDimType") {
  stopifnot(is.character(indicator), length(indicator) == 1L, nzchar(indicator))
  stopifnot(is.character(dimension), length(dimension) == 1L)

  res <- .gho_get(paste0("https://ghoapi.azureedge.net/api/", indicator))
  if (is.null(res) || !dimension %in% names(res)) return(character())
  vals <- unique(res[[dimension]])
  sort(vals[!is.na(vals)])
}


#' @noRd
.gho_get <- function(url) {
  all_data <- list()
  next_url <- url

  repeat {
    cli::cli_inform("Fetching: {.url {next_url}}")

    resp <- tryCatch(
      httr2::request(next_url) |>
        httr2::req_headers(Accept = "application/json") |>
        httr2::req_retry(max_tries = 3) |>
        httr2::req_perform(),
      error = function(e) {
        cli::cli_warn(c(
          "GHO request failed.",
          "i" = "URL: {.url {next_url}}",
          "x" = conditionMessage(e)
        ))
        NULL
      }
    )
    if (is.null(resp)) return(NULL)

    body <- httr2::resp_body_json(resp, simplifyVector = TRUE)
    all_data <- c(all_data, list(body$value))

    next_url <- body[["@odata.nextLink"]]
    if (is.null(next_url)) break
  }

  out <- do.call(rbind, c(all_data, list(make.row.names = FALSE)))
  rownames(out) <- NULL
  out
}
