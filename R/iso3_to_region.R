#' Look Up the WHO Region for ISO3 Codes
#'
#' Maps ISO 3166-1 alpha-3 country codes to WHO region codes using
#' the [`who_countries`] dataset shipped with DSIR. Stays in sync with
#' WHO governance changes reflected in DSIR — for example, Indonesia's
#' reassignment from SEAR to WPR following EB156 (May 2025).
#'
#' Codes that do not correspond to a WHO Member State return `NA`.
#' This includes Associate Members (Puerto Rico, Tokelau) and other
#' non-Member areas that some indicator data sets cover.
#'
#' @param iso3 Character vector of ISO3 codes. Case-sensitive
#'   (uppercase, as in [`who_countries`]).
#' @param long Logical. If `TRUE`, return long-form region names
#'   (e.g. `"Western Pacific"`). If `FALSE` (default), return the
#'   short codes used elsewhere in DSIR: `"AFR"`, `"AMR"`, `"SEAR"`,
#'   `"EUR"`, `"EMR"`, `"WPR"`.
#'
#' @return A character vector the same length as `iso3`.
#' @seealso [`who_countries`], [`wpro_cty`].
#' @export
#'
#' @examples
#' iso3_to_region(c("PHL", "FRA", "USA", "COK"))
#' # "WPR" "EUR" "AMR" "WPR"
#'
#' iso3_to_region(c("IDN", "JPN"), long = TRUE)
#' # "Western Pacific" "Western Pacific"  (Indonesia in WPR since May 2025)
#'
#' # Non-Member areas return NA
#' iso3_to_region(c("PRI", "TKL", "PHL"))
#' # NA NA "WPR"
iso3_to_region <- function(iso3, long = FALSE) {
  if (!is.character(iso3)) {
    cli::cli_abort("{.arg iso3} must be a character vector, not {.cls {class(iso3)}}.")
  }
  if (!isTRUE(long) && !isFALSE(long)) {
    cli::cli_abort("{.arg long} must be a single logical value.")
  }

  m <- match(iso3, who_countries$iso3)
  codes <- who_countries$who_region[m]

  if (!long) return(codes)

  long_map <- c(
    AFR  = "Africa",
    AMR  = "Americas",
    SEAR = "South-East Asia",
    EUR  = "Europe",
    EMR  = "Eastern Mediterranean",
    WPR  = "Western Pacific"
  )
  unname(long_map[codes])
}
