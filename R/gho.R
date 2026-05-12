#' List GHO Indicators
#'
#' Fetches the catalog of indicators from the WHO Global Health
#' Observatory (GHO) OData API.
#'
#' @param search Optional character. Search keywords matched against
#'   `IndicatorName` (case-insensitive). All terms must match
#'   (AND semantics). Accepts either:
#'   * a single string, which is split on whitespace into terms
#'     (e.g. `"child mortality"` matches indicators containing both
#'     "child" and "mortality"), or
#'   * a character vector, whose elements are used as terms verbatim
#'     (whitespace inside an element is treated as part of the term).
#'
#'   Single quotes in any term are escaped for the OData filter.
#'
#' @return A [tibble][tibble::tibble] with columns `IndicatorCode`,
#'   `IndicatorName` and `Language`. Returns an empty tibble (with
#'   a message) when the service is unreachable.
#' @seealso [gho_data()], [gho_dimensions()].
#' @export
#'
#' @examples
#' \dontrun{
#' # All indicators
#' inds <- gho_indicators()
#'
#' # Single keyword
#' gho_indicators("mortality")
#'
#' # Multiple keywords from one string (AND): both terms must appear
#' gho_indicators("child mortality")
#'
#' # Or pass terms as a vector
#' gho_indicators(c("child", "mortality"))
#' }
gho_indicators <- function(search = NULL) {
  url <- .gho_indicators_build_url(search)

  res <- .gho_get(url)
  if (is.null(res) || nrow(res) == 0L) {
    return(tibble::tibble(IndicatorCode = character(),
                          IndicatorName = character(),
                          Language = character()))
  }
  res[, c("IndicatorCode", "IndicatorName", "Language")]
}


#' @noRd
.gho_indicators_build_url <- function(search = NULL) {
  base_url <- "https://ghoapi.azureedge.net/api/Indicator"
  if (is.null(search)) return(base_url)

  stopifnot(
    is.character(search),
    length(search) >= 1L,
    !anyNA(search),
    all(nzchar(search))
  )

  terms <- if (length(search) == 1L) {
    strsplit(search, "\\s+")[[1]]
  } else {
    search
  }
  terms <- terms[nzchar(terms)]
  stopifnot(length(terms) >= 1L)

  terms_escaped <- gsub("'", "''", tolower(terms), fixed = TRUE)
  clauses <- paste0("contains(tolower(IndicatorName),'", terms_escaped, "')")
  filter <- paste(clauses, collapse = " and ")
  paste0(base_url, "?$filter=", utils::URLencode(filter, reserved = TRUE))
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
#' @return A [tibble][tibble::tibble] of indicator observations, or
#'   an empty tibble when the service is unreachable.
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
  url <- .gho_build_url(indicator,
                        spatial_type = spatial_type, area = area,
                        year_from = year_from, year_to = year_to)
  res <- .gho_get(url)
  if (is.null(res)) tibble::tibble() else res
}


#' @noRd
.gho_build_url <- function(indicator, spatial_type = NULL, area = NULL,
                           year_from = NULL, year_to = NULL,
                           top = NULL, select = NULL, count = FALSE) {
  stopifnot(is.character(indicator), length(indicator) == 1L, nzchar(indicator))
  base_url <- paste0("https://ghoapi.azureedge.net/api/", indicator)

  filters <- character(0)

  if (!is.null(area) && is.null(spatial_type)) {
    cli::cli_inform(c(
      "Assuming {.arg spatial_type} = {.val country} since {.arg area} was given.",
      "i" = "Pass {.arg spatial_type} explicitly to silence this message."
    ))
    spatial_type <- "country"
  }

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
    stopifnot(
      is.character(area),
      length(area) >= 1L,
      !anyNA(area),
      all(nzchar(area))
    )
    area_filter <- paste0(
      "SpatialDim in ('",
      paste(area, collapse = "','"),
      "')"
    )
    filters <- c(filters, area_filter)
  }

  if (!is.null(year_from)) {
    filters <- c(filters, paste0("TimeDim ge ", year_from))
  }
  if (!is.null(year_to)) {
    filters <- c(filters, paste0("TimeDim le ", year_to))
  }

  query_parts <- character(0)
  if (length(filters) > 0) {
    filter_str <- paste(filters, collapse = " and ")
    query_parts <- c(query_parts,
                     paste0("$filter=", utils::URLencode(filter_str, reserved = TRUE)))
  }
  if (!is.null(top)) {
    query_parts <- c(query_parts, paste0("$top=", top))
  }
  if (!is.null(select)) {
    query_parts <- c(query_parts, paste0("$select=", paste(select, collapse = ",")))
  }
  if (isTRUE(count)) {
    query_parts <- c(query_parts, "$count=true")
  }

  if (length(query_parts) == 0L) return(base_url)
  paste0(base_url, "?", paste(query_parts, collapse = "&"))
}


#' Check Whether a GHO Indicator Has Data for a Filter
#'
#' Sends a minimal request (`$top=1&$select=Id`) to the WHO GHO OData
#' API to find out whether any observations exist for the given
#' indicator and filter combination, without downloading the full
#' result set. Useful as a quick precheck before [gho_data()].
#'
#' @inheritParams gho_data
#'
#' @return A logical scalar:
#' * `TRUE` if at least one observation exists for the filter.
#' * `FALSE` if the server returns an empty result.
#' * `NA` if the request fails (network failure, unreachable host,
#'   or the indicator code does not exist and the server returns an
#'   HTTP error). A warning is emitted in the failure case.
#' @seealso [gho_data()], [gho_count()], [gho_coverage()].
#' @export
#'
#' @examples
#' \dontrun{
#' # Does WHO have life-expectancy data for France?
#' gho_has_data("WHOSIS_000001", area = "FRA")
#'
#' # Quickly screen a list of indicators before downloading any data
#' inds <- c("WHOSIS_000001", "NCDMORT3070")
#' vapply(inds, gho_has_data, logical(1), area = "FRA")
#' }
gho_has_data <- function(indicator, spatial_type = NULL, area = NULL,
                         year_from = NULL, year_to = NULL) {
  url <- .gho_build_url(indicator,
                        spatial_type = spatial_type, area = area,
                        year_from = year_from, year_to = year_to,
                        top = 1, select = "Id")
  res <- .gho_get(url)
  if (is.null(res)) return(NA)
  nrow(res) > 0L
}


#' Count Observations for a GHO Indicator Filter
#'
#' Sends a `$top=0&$count=true` request to the WHO GHO OData API,
#' which returns the matching row count without transferring any
#' observations. Useful for sizing a download before issuing it.
#'
#' @inheritParams gho_data
#'
#' @return An integer scalar — the number of observations the
#'   server would return for the same filter via [gho_data()].
#'   Returns `NA_integer_` (with a warning) if the request fails.
#' @seealso [gho_data()], [gho_has_data()], [gho_coverage()].
#' @export
#'
#' @examples
#' \dontrun{
#' # How many rows would gho_data() pull for France?
#' gho_count("WHOSIS_000001", area = "FRA")
#'
#' # Compare coverage across regions
#' gho_count("NCDMORT3070", spatial_type = "country")
#' gho_count("NCDMORT3070", spatial_type = "region")
#' }
gho_count <- function(indicator, spatial_type = NULL, area = NULL,
                      year_from = NULL, year_to = NULL) {
  url <- .gho_build_url(indicator,
                        spatial_type = spatial_type, area = area,
                        year_from = year_from, year_to = year_to,
                        top = 0, count = TRUE)

  cli::cli_inform("Fetching: {.url {url}}")
  resp <- tryCatch(
    httr2::request(url) |>
      httr2::req_headers(Accept = "application/json") |>
      httr2::req_retry(max_tries = 3) |>
      httr2::req_perform(),
    error = function(e) {
      cli::cli_warn(c(
        "GHO request failed.",
        "i" = "URL: {.url {url}}",
        "x" = conditionMessage(e)
      ))
      NULL
    }
  )
  if (is.null(resp)) return(NA_integer_)

  body <- httr2::resp_body_json(resp, simplifyVector = TRUE)
  cnt <- body[["@odata.count"]]
  if (is.null(cnt)) return(NA_integer_)
  as.integer(cnt)
}


#' Summarise Per-Location Data Coverage of a GHO Indicator
#'
#' Fetches only the `SpatialDim` and `TimeDim` columns for a GHO
#' indicator (much lighter than [gho_data()]) and summarises the
#' year range and observation count per location. Useful for
#' answering "which countries have data, and for what years?"
#' before committing to a full download.
#'
#' @param indicator Character scalar. The indicator code
#'   (e.g. `"WHOSIS_000001"`).
#' @param spatial_type Character. Spatial dimension to filter on:
#'   one of `"country"`, `"region"`, `"global"`. Defaults to
#'   `"country"` since per-country coverage is the typical use
#'   case. Pass `NULL` for all spatial levels.
#' @param area Character vector of country or region codes
#'   (e.g. `c("FRA", "DEU")`). Default `NULL` returns all areas
#'   for the chosen `spatial_type`.
#' @param year_from Numeric. Start year filter (inclusive).
#'   Default `NULL`.
#' @param year_to Numeric. End year filter (inclusive).
#'   Default `NULL`.
#'
#' @return A [tibble][tibble::tibble] with one row per location and
#'   columns:
#' * `location` (chr) — the `SpatialDim` value (typically ISO3).
#' * `year_min` (int) — earliest year with data.
#' * `year_max` (int) — latest year with data.
#' * `n_obs` (int) — number of observations.
#'
#'   Sorted by `location`. Empty input or service failure returns
#'   an empty tibble with the same four columns.
#' @seealso [gho_data()], [gho_has_data()], [gho_count()].
#' @export
#'
#' @examples
#' \dontrun{
#' # Year coverage of life expectancy for three countries
#' gho_coverage("WHOSIS_000001", area = c("FRA", "DEU", "JPN"))
#'
#' # All countries with any life-expectancy data, since 2010
#' gho_coverage("WHOSIS_000001", year_from = 2010)
#' }
gho_coverage <- function(indicator, spatial_type = "country", area = NULL,
                         year_from = NULL, year_to = NULL) {
  empty <- tibble::tibble(
    location = character(),
    year_min = integer(),
    year_max = integer(),
    n_obs    = integer()
  )

  url <- .gho_build_url(indicator,
                        spatial_type = spatial_type, area = area,
                        year_from = year_from, year_to = year_to,
                        select = c("SpatialDim", "TimeDim"))
  res <- .gho_get(url)
  if (is.null(res) || nrow(res) == 0L) return(empty)
  if (!all(c("SpatialDim", "TimeDim") %in% names(res))) return(empty)

  loc <- as.character(res$SpatialDim)
  yr  <- suppressWarnings(as.integer(res$TimeDim))

  by_loc <- split(yr, loc)
  by_loc <- by_loc[order(names(by_loc))]

  yr_range <- function(x, fn) {
    x <- x[!is.na(x)]
    if (length(x) == 0L) NA_integer_ else as.integer(fn(x))
  }

  tibble::tibble(
    location = names(by_loc),
    year_min = vapply(by_loc, yr_range, integer(1), fn = min),
    year_max = vapply(by_loc, yr_range, integer(1), fn = max),
    n_obs    = vapply(by_loc, length, integer(1))
  )
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


#' Tidy a GHO Data Frame
#'
#' Selects and renames the most useful columns from a GHO observation
#' table returned by [gho_data()], producing a compact tibble suitable
#' for downstream analysis.
#'
#' The mapping is:
#' * `IndicatorCode` -> `id`
#' * `SpatialDim`    -> `location`
#' * `TimeDim`       -> `year`
#' * `Dim1`, `Dim2`, `Dim3` -> `dim1`, `dim2`, `dim3`
#' * `Value`         -> `value`
#' * `NumericValue`  -> `value_num`
#' * `Low`, `High`   -> `low`, `high`
#' * `IndicatorName` -> `indicator`
#'
#' Source columns that are absent from `df` (for example `Low` /
#' `High` on indicators without confidence intervals) are filled
#' with `NA`, so the output always has the same nine columns.
#'
#' @param df A data frame returned by [gho_data()].
#'
#' @return A [tibble][tibble::tibble] with columns `id`,
#'   `location`, `year`, `dim1`, `dim2`, `dim3`, `value`, `value_num`, `low`,
#'   `high`, `indicator`, sorted by `location` then `year`. An empty input
#'   returns an empty tibble with the same columns.
#' @seealso [gho_data()].
#' @export
#'
#' @examples
#' \dontrun{
#' gho_data("NCDMORT3070", spatial_type = "country") |>
#'   gho_clean()
#' }
gho_clean <- function(df) {
  if (!is.data.frame(df)) {
    cli::cli_abort("{.arg df} must be a data frame.")
  }

  rename_map <- c(
    id        = "IndicatorCode",
    location  = "SpatialDim",
    year      = "TimeDim",
    dim1      = "Dim1",
    dim2      = "Dim2",
    dim3      = "Dim3",
    value     = "Value",
    value_num = "NumericValue",
    low       = "Low",
    high      = "High", 
    indicator = "IndicatorName"
  )

  n <- nrow(df)
  cols <- lapply(rename_map, function(src) {
    if (src %in% names(df)) df[[src]] else rep(NA, n)
  })
  out <- tibble::as_tibble(cols)

  out[order(out$location, out$year), , drop = FALSE]
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
    # Skip empty `value` chunks. GHO returns `value = []` (an empty list,
    # not an empty data frame) when a filter matches no rows; rbind-ing
    # it would produce a spurious 1x1 result.
    val <- body$value
    if (is.data.frame(val) && nrow(val) > 0L) {
      all_data <- c(all_data, list(val))
    }

    next_url <- body[["@odata.nextLink"]]
    if (is.null(next_url)) break
  }

  if (length(all_data) == 0L) return(tibble::tibble())
  out <- do.call(rbind, c(all_data, list(make.row.names = FALSE)))
  rownames(out) <- NULL
  tibble::as_tibble(out)
}
