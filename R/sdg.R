#' Normalise an SDG `area` argument
#'
#' Detects whether `area` contains ISO3 codes or UN M49 codes and
#' returns M49 in either case. Rejects mixed formats and inputs that
#' are neither ISO3 nor M49. Unknown ISO3 codes are dropped with a
#' warning.
#'
#' @noRd
.resolve_area <- function(area) {
  if (is.null(area)) return(NULL)
  if (!is.character(area)) {
    cli::cli_abort(
      "{.arg area} must be a character vector, not {.cls {class(area)}}."
    )
  }
  if (length(area) == 0L) return(area)

  is_iso3 <- grepl("^[A-Za-z]{3}$", area)
  is_m49  <- grepl("^[0-9]+$", area)

  if (!all(is_iso3 | is_m49)) {
    bad <- area[!is_iso3 & !is_m49]
    cli::cli_abort(c(
      "Invalid {.arg area} value{?s}: {.val {bad}}",
      "i" = "Use ISO3 codes (e.g. {.val PHL}) or UN M49 numeric codes (e.g. {.val 608})."
    ))
  }

  if (any(is_iso3) && any(is_m49)) {
    cli::cli_abort(c(
      "{.arg area} mixes ISO3 and M49 codes.",
      "i" = "Use one format consistently within a single call."
    ))
  }

  if (all(is_m49)) return(area)

  converted <- iso3_to_m49(area)
  bad <- area[is.na(converted)]
  if (length(bad) > 0L) {
    cli::cli_warn(
      "{length(bad)} ISO3 code{?s} did not match a WHO Member State and {?was/were} dropped: {.val {bad}}"
    )
    converted <- converted[!is.na(converted)]
  }
  if (length(converted) == 0L) {
    cli::cli_abort("No valid area codes remain after conversion.")
  }
  converted
}


#' List SDG Goals
#'
#' Fetches the list of Sustainable Development Goals from the UN
#' SDG API.
#'
#' @param include_children Logical. Include targets and indicators
#'   nested under each goal? Default `FALSE`.
#'
#' @return A list (or [tibble][tibble::tibble]) of SDG goals, or
#'   `NULL` when the service is unreachable.
#' @seealso [sdg_targets()], [sdg_indicators()], [sdg_data()].
#' @export
#'
#' @examples
#' \dontrun{
#' sdg_goals()
#' sdg_goals(include_children = TRUE)
#' }
sdg_goals <- function(include_children = FALSE) {
  url <- paste0(
    "https://unstats.un.org/sdgs/UNSDGAPIV5/v1/sdg/Goal/List",
    "?includechildren=", tolower(as.character(include_children))
  )
  .sdg_get(url)
}


#' List SDG Targets
#'
#' Fetches the list of SDG targets from the UN SDG API.
#'
#' @param include_children Logical. Include indicators nested under
#'   each target? Default `FALSE`.
#'
#' @return A list (or [tibble][tibble::tibble]) of SDG targets, or
#'   `NULL` when the service is unreachable.
#' @seealso [sdg_goals()], [sdg_indicators()].
#' @export
#'
#' @examples
#' \dontrun{
#' sdg_targets()
#' }
sdg_targets <- function(include_children = FALSE) {
  url <- paste0(
    "https://unstats.un.org/sdgs/UNSDGAPIV5/v1/sdg/Target/List",
    "?includechildren=", tolower(as.character(include_children))
  )
  .sdg_get(url)
}


#' List SDG Indicators
#'
#' Fetches the list of SDG indicators from the UN SDG API, with
#' optional keyword filtering on the indicator description.
#'
#' @param search Optional character. Search keywords matched against
#'   the `description` column (case-insensitive). All terms must
#'   match (AND semantics). Accepts either:
#'   * a single string, which is split on whitespace into terms
#'     (e.g. `"mortality cancer"` keeps rows whose description
#'     contains both "mortality" and "cancer"), or
#'   * a character vector, whose elements are used as terms verbatim
#'     (so a term may itself contain whitespace, e.g.
#'     `c("mortality rate", "attributed")`).
#'
#'   The filter is applied client-side using
#'   [grepl()] with `fixed = TRUE` because the UN SDG
#'   `/Indicator/List` endpoint is not OData and exposes no
#'   server-side search parameter; the full list is small
#'   (~250 rows) so this is cheap.
#'
#' @return A list (or [tibble][tibble::tibble]) of SDG indicators,
#'   or `NULL` when the service is unreachable. When `search` matches
#'   no rows, an empty tibble with the same columns as the unfiltered
#'   response is returned.
#' @seealso [sdg_targets()], [sdg_data()].
#' @export
#'
#' @examples
#' \dontrun{
#' # Full list
#' sdg_indicators()
#'
#' # Single keyword
#' sdg_indicators("mortality")
#'
#' # Multi-keyword — AND semantics
#' sdg_indicators("mortality cancer")
#' sdg_indicators(c("maternal", "mortality"))
#' }
sdg_indicators <- function(search = NULL) {
  terms <- if (is.null(search)) NULL else .sdg_indicators_parse_terms(search)

  res <- .sdg_get(
    "https://unstats.un.org/sdgs/UNSDGAPIV5/v1/sdg/Indicator/List"
  )
  if (is.null(terms) || is.null(res)) return(res)
  if (!"description" %in% names(res)) return(res[integer(0), , drop = FALSE])

  haystack <- tolower(res$description)
  keep <- rep(TRUE, length(haystack))
  for (term in tolower(terms)) {
    keep <- keep & grepl(term, haystack, fixed = TRUE)
  }
  res[which(keep), , drop = FALSE]
}


#' @noRd
.sdg_indicators_parse_terms <- function(search) {
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
  terms
}


#' List SDG Geographic Areas
#'
#' Fetches the list of geographic areas available from the UN SDG
#' database.
#'
#' @return A [tibble][tibble::tibble] with area codes and names, or
#'   `NULL` when the service is unreachable.
#' @seealso [sdg_data()].
#' @export
#'
#' @examples
#' \dontrun{
#' sdg_areas()
#' }
sdg_areas <- function() {
  .sdg_get("https://unstats.un.org/sdgs/UNSDGAPIV5/v1/sdg/GeoArea/List")
}


#' Fetch SDG Data
#'
#' Retrieves data for one or more SDG indicators from the UN SDG
#' API, with optional filters by area and year.
#'
#' @param indicator Character vector of indicator codes
#'   (e.g. `"1.1.1"`). Use [sdg_indicators()] to find codes.
#' @param area Character vector of country/area codes. Accepts either
#'   ISO3 codes (e.g. `c("PHL", "FRA")`) — converted automatically via
#'   [iso3_to_m49()] — or UN M49 numeric codes (e.g. `c("608", "250")`)
#'   as returned by [sdg_areas()]. Do not mix the two formats in a
#'   single call. Default `NULL` returns all areas.
#' @param year_from Numeric. Start year filter (inclusive).
#'   Default `NULL`.
#' @param year_to Numeric. End year filter (inclusive).
#'   Default `NULL`.
#' @param page_size Integer. Number of records per page.
#'   Default `1000`, maximum `10000`.
#'
#' @return A [tibble][tibble::tibble] of indicator observations, or
#'   an empty tibble when the service is unreachable or there are no
#'   matching rows.
#' @seealso [sdg_indicators()], [sdg_areas()], [iso3_to_m49()].
#' @export
#'
#' @examples
#' \dontrun{
#' # All data for indicator 1.1.1
#' sdg_data("1.1.1")
#'
#' # Specific area and year range
#' sdg_data("3.2.1", area = "156", year_from = 2015, year_to = 2023)
#'
#' # ISO3 codes work directly — DSIR's regional vectors can be passed in
#' sdg_data("3.4.1", area = wpro_cty)
#' sdg_data("3.4.1", area = c("PHL", "FRA", "JPN"))
#' }
sdg_data <- function(indicator, area = NULL,
                     year_from = NULL, year_to = NULL,
                     page_size = 1000L) {
  stopifnot(is.character(indicator), length(indicator) >= 1L)
  area <- .resolve_area(area)

  # The SDG API expects multi-value parameters as repeated keys
  # (`indicator=3.4.1&indicator=3.4.2`) rather than comma-separated.
  # A comma-separated value is silently dropped and the filter is
  # ignored, returning all rows for the indicator.
  parts <- c(
    paste0("indicator=", indicator),
    paste0("pageSize=", page_size)
  )
  if (!is.null(area))      parts <- c(parts, paste0("areaCode=", area))

  # Year filtering (`year_from` / `year_to`) is applied client-side,
  # not as `timePeriodStart` / `timePeriodEnd` server-side parameters.
  # The UN SDG API returns HTTP 500 and stalls (~30x slower) when
  # those parameters are sent for some indicator/area combinations.

  base_url <- "https://unstats.un.org/sdgs/UNSDGAPIV5/v1/sdg/Indicator/Data"
  url <- paste0(base_url, "?", paste(parts, collapse = "&"))

  all_data <- list()
  page <- 1

  repeat {
    page_url <- paste0(url, "&page=", page)
    body <- .sdg_get(page_url)
    if (is.null(body)) return(tibble::tibble())
    if (is.null(body$data) || length(body$data) == 0) break

    all_data <- c(all_data, list(tibble::as_tibble(body$data)))

    total_pages <- body$totalPages %||% 1
    if (page >= total_pages) break
    page <- page + 1
  }

  if (length(all_data) == 0) {
    cli::cli_warn("No data returned for indicator {.val {indicator}}.")
    return(tibble::tibble())
  }

  # Default `make.row.names = TRUE` so rbind disambiguates the
  # per-page tibble row names (which are otherwise "1", "2", ...
  # repeated across pages and would error). The names are then
  # discarded by tibble::as_tibble.
  out <- do.call(rbind, all_data)
  out <- tibble::as_tibble(out)

  # Client-side year filter — workaround for UN SDG API bug where
  # timePeriodStart / timePeriodEnd cause HTTP 500 server-side.
  if (!is.null(year_from) || !is.null(year_to)) {
    if (!"timePeriodStart" %in% names(out)) {
      cli::cli_warn(c(
        "Cannot apply year filter: {.field timePeriodStart} column missing.",
        "i" = "Returning unfiltered data."
      ))
    } else {
      yr <- suppressWarnings(as.integer(out$timePeriodStart))
      keep <- !is.na(yr)
      if (!is.null(year_from)) keep <- keep & yr >= as.integer(year_from)
      if (!is.null(year_to))   keep <- keep & yr <= as.integer(year_to)
      out <- out[keep, , drop = FALSE]
    }
  }

  out
}


#' Summarise Series-Level Coverage of an SDG Indicator
#'
#' Fetches an SDG indicator via [sdg_data()] and summarises how each
#' constituent **series** is covered, by location and year. SDG
#' indicators are typically published as several series stratified
#' by sex, age, cause, vaccine, or similar — for example, indicator
#' `"3.b.1"` (vaccine coverage) is split into `SH_ACS_DTP3`,
#' `SH_ACS_MCV2`, `SH_ACS_PCV3`, and `SH_ACS_HPV`. Each series can
#' have its own country / year coverage; `sdg_coverage()` makes
#' those differences visible before committing to an analysis.
#'
#' This is a *series-exploration* helper, not an availability
#' precheck. SDG data is generally complete enough that GHO-style
#' [gho_has_data()] / [gho_count()] analogues add little value, and
#' are intentionally not provided. The more useful pre-analysis
#' question for SDG is "which series exist, and how is each
#' covered?", which is what this function answers.
#'
#' @param indicator Character scalar. The indicator code
#'   (e.g. `"3.b.1"`). Use [sdg_indicators()] to find codes.
#' @param area Character vector of country/area codes. Accepts either
#'   ISO3 codes (e.g. `c("PHL", "FRA")`) — converted automatically via
#'   [iso3_to_m49()] — or UN M49 numeric codes (e.g. `c("608", "250")`)
#'   as returned by [sdg_areas()]. Do not mix the two formats in a
#'   single call. Default `NULL` returns all areas.
#' @param year_from Numeric. Start year filter (inclusive).
#'   Default `NULL`.
#' @param year_to Numeric. End year filter (inclusive).
#'   Default `NULL`.
#'
#' @return A [tibble][tibble::tibble] with one row per
#'   `(location, series)` combination and columns:
#' * `location` (chr) — the `geoAreaCode` value (M49 numeric, as a
#'   string).
#' * `series` (chr) — the SDG series code (e.g. `"SH_ACS_DTP3"`).
#' * `year_min` (int) — earliest year with data.
#' * `year_max` (int) — latest year with data.
#' * `n_obs` (int) — number of observations.
#'
#'   Sorted by `location`, then `series`. Empty input or service
#'   failure returns an empty tibble with the same five columns
#'   and the same column types.
#' @seealso [sdg_data()], [sdg_indicators()], [gho_coverage()].
#' @export
#'
#' @examples
#' \dontrun{
#' # Vaccine coverage in China and Brazil — four series per country
#' sdg_coverage("3.b.1", area = c("156", "76"))
#'
#' # NCD mortality in WPR since 2010
#' sdg_coverage("3.4.1", area = wpro_cty, year_from = 2010)
#' }
sdg_coverage <- function(indicator, area = NULL,
                         year_from = NULL, year_to = NULL) {
  area <- .resolve_area(area)
  empty <- tibble::tibble(
    location = character(),
    series   = character(),
    year_min = integer(),
    year_max = integer(),
    n_obs    = integer()
  )

  res <- suppressWarnings(
    sdg_data(indicator, area = area,
             year_from = year_from, year_to = year_to)
  )
  if (!is.data.frame(res) || nrow(res) == 0L) return(empty)
  if (!all(c("geoAreaCode", "timePeriodStart", "series") %in% names(res))) {
    return(empty)
  }

  loc <- as.character(res$geoAreaCode)
  ser <- as.character(res$series)
  yr  <- suppressWarnings(as.integer(res$timePeriodStart))

  # Composite key: \x1f (US, unit separator) cannot appear in either
  # an M49 numeric code or an SDG series code, so it safely separates
  # the two parts and the split is unambiguous.
  key <- paste(loc, ser, sep = "\x1f")
  by_key <- split(seq_along(key), key)
  by_key <- by_key[order(names(by_key))]

  yr_range <- function(x, fn) {
    x <- x[!is.na(x)]
    if (length(x) == 0L) NA_integer_ else as.integer(fn(x))
  }

  parts <- strsplit(names(by_key), "\x1f", fixed = TRUE)
  tibble::tibble(
    location = vapply(parts, `[[`, character(1), 1L),
    series   = vapply(parts, `[[`, character(1), 2L),
    year_min = vapply(by_key, function(i) yr_range(yr[i], min), integer(1)),
    year_max = vapply(by_key, function(i) yr_range(yr[i], max), integer(1)),
    n_obs    = vapply(by_key, length, integer(1))
  )
}


#' Tidy an SDG Data Frame
#'
#' Selects and renames the most useful columns from an SDG
#' observation table returned by [sdg_data()], producing a compact
#' tibble suitable for downstream analysis.
#'
#' The mapping is:
#' * `goal`            -> `goal`
#' * `target`          -> `target`
#' * `indicator`       -> `indicator` (flattened to the first code
#'   when the source column is a list)
#' * `series`          -> `series`
#' * `geoAreaCode`     -> `location`
#' * `geoAreaName`     -> `location_name`
#' * `timePeriodStart` -> `year`
#' * `value`           -> `value`
#' * `lowerBound`      -> `low`
#' * `upperBound`      -> `high`
#'
#' Source columns that are absent from `df` are filled with `NA`,
#' so the output always has the same ten columns. `value`, `low`
#' and `high` are returned in their original character form because
#' the SDG API returns non-numeric values (e.g. `"<0.1"` or
#' aggregate notes) for some rows; coerce with [as.numeric()]
#' downstream when appropriate.
#'
#' @param df A data frame returned by [sdg_data()].
#'
#' @return A [tibble][tibble::tibble] with columns `goal`, `target`,
#'   `indicator`, `series`, `location`, `location_name`, `year`,
#'   `value`, `low`, `high`, sorted by `location` then `year`. An
#'   empty input returns an empty tibble with the same columns.
#' @seealso [sdg_data()].
#' @export
#'
#' @examples
#' \dontrun{
#' sdg_data("3.2.1", area = "156", year_from = 2015) |>
#'   sdg_clean()
#' }
sdg_clean <- function(df) {
  if (!is.data.frame(df)) {
    cli::cli_abort("{.arg df} must be a data frame.")
  }

  rename_map <- c(
    goal          = "goal",
    target        = "target",
    indicator     = "indicator",
    series        = "series",
    location      = "geoAreaCode",
    location_name = "geoAreaName",
    year          = "timePeriodStart",
    value         = "value",
    low           = "lowerBound",
    high          = "upperBound"
  )

  n <- nrow(df)
  cols <- lapply(rename_map, function(src) {
    if (!src %in% names(df)) return(rep(NA, n))
    x <- df[[src]]
    if (is.list(x)) {
      vapply(x, function(v) {
        if (length(v) == 0) NA_character_ else as.character(v[[1]])
      }, character(1))
    } else {
      x
    }
  })
  out <- tibble::as_tibble(cols)

  out[order(out$location, out$year), , drop = FALSE]
}


#' @noRd
.sdg_get <- function(url) {
  cli::cli_inform("Fetching: {.url {url}}")

  resp <- tryCatch(
    httr2::request(url) |>
      httr2::req_headers(Accept = "application/json") |>
      httr2::req_timeout(20) |>
      httr2::req_retry(
        max_tries = 3,
        backoff   = ~ min(2 ^ .x, 30)
      ) |>
      httr2::req_perform(),
    error = function(e) {
      cli::cli_warn(c(
        "SDG request failed.",
        "i" = "URL: {.url {url}}",
        "x" = conditionMessage(e)
      ))
      NULL
    }
  )
  if (is.null(resp)) return(NULL)

  out <- httr2::resp_body_json(resp, simplifyVector = TRUE)
  if (is.data.frame(out)) tibble::as_tibble(out) else out
}
