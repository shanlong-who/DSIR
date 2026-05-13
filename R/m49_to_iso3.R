#' Convert UN M49 Numeric Codes to ISO3 Codes
#'
#' Maps UN M49 numeric area codes to ISO 3166-1 alpha-3 country codes
#' using the [`who_countries`] dataset shipped with DSIR. Counterpart
#' to [iso3_to_m49()] and used internally by [sdg_clean()] to populate
#' the `iso3` column on SDG output.
#'
#' M49 codes that do not correspond to a WHO Member State return `NA`.
#' This includes region / world aggregates (e.g. `"900"` for World,
#' `"001"` for World, `"419"` for Latin America and the Caribbean)
#' and codes for non-Member areas (e.g. Puerto Rico, Tokelau).
#'
#' Input accepts either the zero-padded form (`"076"`) or the bare
#' form (`"76"`); both are normalised before lookup. Non-numeric
#' input returns `NA` (with a single warning from the underlying
#' [as.integer()] coercion).
#'
#' @param m49 Character vector of M49 codes.
#'
#' @return A character vector the same length as `m49`. Non-Member
#'   codes (region aggregates, non-Member areas) return `NA`.
#' @seealso [`who_countries`], [iso3_to_m49()], [sdg_clean()].
#' @export
#'
#' @examples
#' m49_to_iso3(c("608", "250", "392"))
#' # "PHL" "FRA" "JPN"
#'
#' # Zero-padded and bare forms both accepted
#' m49_to_iso3(c("076", "76"))
#' # "BRA" "BRA"
#'
#' # Non-Member areas / aggregates return NA
#' m49_to_iso3(c("900", "608"))
#' # NA "PHL"
m49_to_iso3 <- function(m49) {
  if (!is.character(m49)) {
    cli::cli_abort(
      "{.arg m49} must be a character vector, not {.cls {class(m49)}}."
    )
  }
  padded <- formatC(suppressWarnings(as.integer(m49)),
                    width = 3, flag = "0")
  # formatC(NA_integer_) returns "NA" — turn it back into NA_character_
  # so match() returns NA, not a spurious match against a literal "NA".
  padded[padded == "NA"] <- NA_character_
  m <- match(padded, who_countries$m49_code)
  who_countries$iso3[m]
}
