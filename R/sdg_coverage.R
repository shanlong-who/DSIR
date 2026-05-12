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
#' @param area Character vector of area codes (e.g.
#'   `c("156", "608")`). Default `NULL` returns all areas.
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
#' @seealso [sdg_data()], [sdg_indicators()].
#' @export
#'
#' @examples
#' \dontrun{
#' # Series available for NCD mortality in China and Brazil
#' sdg_coverage("3.4.1", area = c("156", "076"))
#'
#' # Filter to a year range
#' sdg_coverage("3.4.1", area = "156", year_from = 2015)
#' }
sdg_coverage <- function(indicator, area = NULL,
                         year_from = NULL, year_to = NULL) {
  empty <- tibble::tibble(
    location = character(),
    series   = character(),
    year_min = integer(),
    year_max = integer(),
    n_obs    = integer()
  )

  df <- sdg_data(indicator, area = area,
                 year_from = year_from, year_to = year_to)
  if (!is.data.frame(df) || nrow(df) == 0L) return(empty)
  if (!all(c("geoAreaCode", "series", "timePeriodStart") %in% names(df))) {
    return(empty)
  }

  loc <- as.character(df$geoAreaCode)
  ser <- as.character(df$series)
  yr  <- suppressWarnings(as.integer(df$timePeriodStart))

  key <- paste(loc, ser, sep = "\r")
  idx <- split(seq_along(key), key)

  yr_range <- function(x, fn) {
    x <- x[!is.na(x)]
    if (length(x) == 0L) NA_integer_ else as.integer(fn(x))
  }

  out_loc <- vapply(idx, function(i) loc[i[1]], character(1))
  out_ser <- vapply(idx, function(i) ser[i[1]], character(1))
  out <- tibble::tibble(
    location = out_loc,
    series   = out_ser,
    year_min = vapply(idx, function(i) yr_range(yr[i], min), integer(1)),
    year_max = vapply(idx, function(i) yr_range(yr[i], max), integer(1)),
    n_obs    = vapply(idx, length, integer(1))
  )

  out[order(out$location, out$series), , drop = FALSE]
}
