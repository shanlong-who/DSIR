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
#' \donttest{
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
#' \donttest{
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
#' \donttest{
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
#' \donttest{
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
#' \donttest{
#' # One indicator, one country — the typical entry point
#' sdg_data("1.1.1", area = "PHL")
#'
#' # Specific area and year range (M49 code)
#' sdg_data("3.2.1", area = "156", year_from = 2015, year_to = 2023)
#'
#' # ISO3 codes work directly — DSIR's regional vectors can be passed in
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

  # `make.row.names = FALSE` is essential: with the default TRUE, rbind
  # tries to combine each tibble's "1".."pageSize" row names, which
  # collide across pages and trip `duplicate 'row.names' are not allowed`
  # for indicators that span more than one full page.
  out <- do.call(rbind, c(all_data, list(make.row.names = FALSE)))
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


#' Tidy an SDG Data Frame
#'
#' Selects, renames, and type-casts the most useful columns from an
#' SDG observation table returned by [sdg_data()], producing a compact
#' tibble in the **unified DSIR cleaned-indicator schema** — the same
#' schema produced by [gho_clean()], so the two outputs can be combined
#' directly with [bind_indicators()].
#'
#' The mapping (SDG source → unified column) is:
#' * `indicator` (list-column, flattened) → `id` (e.g. `"3.4.1"`)
#' * `seriesDescription`                  → `indicator` (human-readable
#'   label; `NA` if the API response does not include it)
#' * `geoAreaCode`                        → `location` (UN M49 numeric,
#'   as character); also `iso3` via [m49_to_iso3()] for WHO Member
#'   States — region / world aggregates and non-Member areas get
#'   `iso3 = NA`
#' * `geoAreaName`                        → `location_name`
#' * `timePeriodStart`                    → `year` (integer)
#' * `value`                              → `value` (character; raw)
#'   and `value_num` (numeric; `NA` for non-numeric entries like
#'   `"<0.1"` or aggregate notes)
#' * `lowerBound`, `upperBound`           → `low`, `high` (numeric)
#' * `series`                             → `series`
#'
#' Three columns are always present but never populated for SDG
#' output: `dim1`, `dim2`, `dim3` (GHO-only concepts).
#'
#' @param df A data frame returned by [sdg_data()].
#'
#' @return A [tibble][tibble::tibble] with 15 columns: `source` (always
#'   `"sdg"`), `id`, `indicator`, `location`, `iso3`, `location_name`,
#'   `year`, `value`, `value_num`, `low`, `high`, `series`, `dim1`
#'   (`NA`), `dim2` (`NA`), `dim3` (`NA`). Sorted by `location` then
#'   `year`. Empty input returns an empty tibble with the same columns
#'   and types.
#' @seealso [sdg_data()], [gho_clean()], [bind_indicators()],
#'   [m49_to_iso3()].
#' @export
#'
#' @examples
#' \donttest{
#' sdg_data("3.2.1", area = "156", year_from = 2015) |>
#'   sdg_clean()
#' }
sdg_clean <- function(df) {
  if (!is.data.frame(df)) {
    cli::cli_abort("{.arg df} must be a data frame.")
  }

  n <- nrow(df)
  if (n == 0L) return(.dsi_empty_clean())

  flatten_chr <- function(src) {
    if (!src %in% names(df)) return(.fill_na(n, "chr"))
    x <- df[[src]]
    if (is.list(x)) {
      vapply(x, function(v) {
        if (length(v) == 0L) NA_character_ else as.character(v[[1]])
      }, character(1))
    } else {
      as.character(x)
    }
  }
  pick_chr <- function(src) {
    if (src %in% names(df)) as.character(df[[src]]) else .fill_na(n, "chr")
  }
  pick_num <- function(src) {
    if (src %in% names(df)) {
      suppressWarnings(as.numeric(df[[src]]))
    } else {
      .fill_na(n, "num")
    }
  }
  pick_int <- function(src) {
    if (src %in% names(df)) {
      suppressWarnings(as.integer(df[[src]]))
    } else {
      .fill_na(n, "int")
    }
  }

  location <- pick_chr("geoAreaCode")
  value_chr <- pick_chr("value")

  out <- tibble::tibble(
    source        = rep("sdg", n),
    id            = flatten_chr("indicator"),
    indicator     = pick_chr("seriesDescription"),
    location      = location,
    iso3          = m49_to_iso3(location),
    location_name = pick_chr("geoAreaName"),
    year          = pick_int("timePeriodStart"),
    value         = value_chr,
    value_num     = suppressWarnings(as.numeric(value_chr)),
    low           = pick_num("lowerBound"),
    high          = pick_num("upperBound"),
    series        = pick_chr("series"),
    dim1          = .fill_na(n, "chr"),
    dim2          = .fill_na(n, "chr"),
    dim3          = .fill_na(n, "chr")
  )

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
