#' Convert ISO3 Codes to UN M49 Numeric Codes
#'
#' Maps ISO 3166-1 alpha-3 country codes to UN M49 numeric area codes
#' using the [`who_countries`] dataset shipped with DSIR. Useful when
#' moving from data sources keyed by ISO3 (e.g. the WHO GHO API) to
#' sources keyed by M49 (e.g. the UN SDG API).
#'
#' Codes that do not correspond to a WHO Member State return `NA`.
#' This includes Associate Members (e.g. Puerto Rico) and other
#' non-Member areas that some indicator data sets cover.
#'
#' Most users will not need to call this function directly:
#' [sdg_data()] and [sdg_coverage()] accept ISO3 codes for their
#' `area` argument and convert internally. This helper is exported
#' for cases where you want to inspect or manipulate the conversion
#' yourself.
#'
#' @param iso3 Character vector of ISO3 codes. Case-insensitive;
#'   values are upper-cased before lookup.
#'
#' @return A character vector the same length as `iso3`, with M49
#'   codes in the same format as `who_countries$m49_code` (three-
#'   character zero-padded strings, e.g. `"076"`). Non-Member areas
#'   return `NA`.
#' @seealso [`who_countries`], [iso3_to_region()], [sdg_data()].
#' @export
#'
#' @examples
#' iso3_to_m49(c("PHL", "FRA", "JPN"))
#' # "608" "250" "392"
#'
#' # Case-insensitive
#' iso3_to_m49("phl")
#' # "608"
#'
#' # Non-Member areas return NA
#' iso3_to_m49(c("PRI", "PHL"))
#' # NA "608"
iso3_to_m49 <- function(iso3) {
  if (!is.character(iso3)) {
    cli::cli_abort(
      "{.arg iso3} must be a character vector, not {.cls {class(iso3)}}."
    )
  }
  m <- match(toupper(iso3), who_countries$iso3)
  who_countries$m49_code[m]
}
