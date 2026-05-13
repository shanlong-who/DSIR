#' Explore Series Coverage of an SDG Indicator
#'
#' A single SDG indicator (for example `"3.4.1"`, NCD mortality) is
#' typically published as several **series** stratified by sex, age,
#' or cause. Different series may have different country and year
#' coverage. `sdg_coverage()` summarises year range and observation
#' count per `(location, series)` combination, so you can see which
#' series exist for an indicator and how each one is covered before
#' committing to a downstream analysis.
#'
#' Unlike the GHO availability helpers, this function is a
#' series-exploration tool rather than a payload-saving precheck:
#' SDG data is generally complete enough that GHO-style
#' `has_data()` / `count()` helpers add little value, so they are
#' intentionally not provided. The SDG API also offers no
#' payload-reduction option (no `$select` equivalent), so
#' `sdg_coverage()` calls [sdg_data()] internally and aggregates
#' the result client-side.
#'
#' @param indicator Character vector of SDG indicator codes
#'   (e.g. `"3.4.1"`).
#' @param area Character vector of country/area codes. Accepts either
#'   ISO3 codes (e.g. `c("PHL", "FRA")`) — converted automatically via
#'   [iso3_to_m49()] — or UN M49 numeric codes (e.g. `c("608", "250")`)
#'   as returned by [sdg_areas()]. Do not mix the two formats in a
#'   single call. Default `NULL` returns all areas. Unknown ISO3 codes
#'   are dropped with a warning before the network call.
#' @param year_from Numeric. Start year filter (inclusive).
#'   Default `NULL`.
#' @param year_to Numeric. End year filter (inclusive).
#'   Default `NULL`.
#'
#' @return A [tibble][tibble::tibble] with one row per
#'   `(location, series)` and columns:
#' * `location` (chr) — area code (`geoAreaCode`).
#' * `series` (chr) — SDG series code.
#' * `year_min` (int) — earliest year with data.
#' * `year_max` (int) — latest year with data.
#' * `n_obs` (int) — number of observations.
#'
#'   Sorted by `location` then `series`. Empty input or service
#'   failure returns an empty tibble with the same five columns.
#' @seealso [sdg_data()], [sdg_indicators()], [gho_coverage()].
#' @export
#'
#' @examples
#' \donttest{
#' # Series available for NCD mortality in China and Brazil
#' sdg_coverage("3.4.1", area = c("156", "076"))
#'
#' # Filter to a year range
#' sdg_coverage("3.4.1", area = "156", year_from = 2015)
#' }
sdg_coverage <- function(indicator, area = NULL,
                         year_from = NULL, year_to = NULL) {
  # Resolve up-front so the "unknown ISO3" warning surfaces from
  # sdg_coverage() rather than being swallowed by the
  # suppressWarnings() wrapper around sdg_data() below.
  area <- .resolve_area(area)

  empty <- tibble::tibble(
    location = character(),
    series   = character(),
    year_min = integer(),
    year_max = integer(),
    n_obs    = integer()
  )

  df <- suppressWarnings(
    sdg_data(indicator, area = area,
             year_from = year_from, year_to = year_to)
  )
  if (!is.data.frame(df) || nrow(df) == 0L) return(empty)
  if (!all(c("geoAreaCode", "series", "timePeriodStart") %in% names(df))) {
    return(empty)
  }

  loc <- as.character(df$geoAreaCode)
  ser <- as.character(df$series)
  yr  <- suppressWarnings(as.integer(df$timePeriodStart))

  # \x1f (US, unit separator) cannot appear in an M49 numeric code or
  # an SDG series code, so it separates the two parts unambiguously.
  key <- paste(loc, ser, sep = "\x1f")
  idx <- split(seq_along(key), key)

  yr_range <- function(x, fn) {
    x <- x[!is.na(x)]
    if (length(x) == 0L) NA_integer_ else as.integer(fn(x))
  }

  parts <- strsplit(names(idx), "\x1f", fixed = TRUE)
  out <- tibble::tibble(
    location = vapply(parts, `[[`, character(1), 1L),
    series   = vapply(parts, `[[`, character(1), 2L),
    year_min = vapply(idx, function(i) yr_range(yr[i], min), integer(1)),
    year_max = vapply(idx, function(i) yr_range(yr[i], max), integer(1)),
    n_obs    = vapply(idx, length, integer(1))
  )

  out[order(out$location, out$series), , drop = FALSE]
}
