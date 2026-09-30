#' List SDG Dimension Codes and Labels
#'
#' Retrieves the official code lists for each series linked to an SDG
#' indicator, without downloading its observations. These are available
#' categories, not evidence that every category occurs in every country's
#' data. Inspect `unique(df$dimensions)` after [sdg_data()] to see observed
#' strata. Use the `code` column for filters; `sdmx` is an alternative
#' representation and may differ from the JSON API's observation codes.
#'
#' @param indicator A single SDG indicator code, e.g. `"3.8.2"`.
#' @param series Optional character vector of series codes linked to the
#'   indicator. Default `NULL` retrieves all its series.
#' @param include_attributes Logical. Also return attribute code lists,
#'   including units and data nature? Default `FALSE`.
#'
#' @return A tibble with character columns `indicator`, `series`, `kind`
#'   (`"dimension"` or `"attribute"`), `dimension` (the original field
#'   name), `code`, `label`, and `sdmx`. Missing source labels stay `NA`.
#'   Sorted by series, kind, dimension, and code. If any required request
#'   fails or its structure is invalid, warns and returns a typed empty
#'   tibble instead of a partial code list.
#' @seealso [sdg_data()], [sdg_clean()], [sdg_indicators()].
#' @export
#'
#' @examples
#' \donttest{
#' sdg_dimensions("3.8.2")
#' sdg_dimensions("3.8.2", include_attributes = TRUE)
#' }
sdg_dimensions <- function(indicator, series = NULL, include_attributes = FALSE) {
  if (!is.character(indicator) || length(indicator) != 1L ||
      is.na(indicator) || !nzchar(indicator)) {
    cli::cli_abort("{.arg indicator} must be a single non-empty SDG code.")
  }
  .sdg_validate_filters(series, NULL)
  .dsi_check_flag(include_attributes, "include_attributes")
  empty <- .sdg_empty_dimensions()
  base_url <- "https://unstats.un.org/sdgs/UNSDGAPIV5/v1/sdg/"
  catalog <- .sdg_get(paste0(
    base_url, "Indicator/", utils::URLencode(indicator, reserved = TRUE), "/Series/List"
  ))
  if (is.null(catalog)) return(empty)
  if (!is.data.frame(catalog) || !all(c("code", "series") %in% names(catalog))) {
    cli::cli_warn("SDG series metadata has an invalid structure.")
    return(empty)
  }
  linked <- catalog$series[catalog$code %in% indicator]
  series_codes <- character()
  for (entry in linked) {
    if (length(entry) == 0L) next
    if (!is.data.frame(entry) || !"code" %in% names(entry)) {
      cli::cli_warn("SDG series metadata has an invalid structure.")
      return(empty)
    }
    series_codes <- c(series_codes, as.character(entry$code))
  }
  series_codes <- unique(series_codes[!is.na(series_codes) & nzchar(series_codes)])
  if (!is.null(series)) {
    missing_series <- setdiff(series, series_codes)
    if (length(missing_series) > 0L) {
      cli::cli_warn("Series not linked to indicator {.val {indicator}}: {.val {missing_series}}.")
      return(empty)
    }
    series_codes <- series_codes[series_codes %in% series]
  }
  if (length(series_codes) == 0L) {
    cli::cli_warn("No series metadata returned for indicator {.val {indicator}}.")
    return(empty)
  }

  kinds <- c(dimension = "Dimensions")
  if (include_attributes) kinds <- c(kinds, attribute = "Attributes")
  tables <- list()
  for (code in series_codes) {
    for (kind in names(kinds)) {
      url <- paste0(base_url, "Series/", utils::URLencode(code, reserved = TRUE),
                    "/", kinds[[kind]])
      metadata <- .sdg_get(url)
      if (is.null(metadata)) return(empty)
      table <- .sdg_codebook_rows(metadata, indicator, code, kind)
      if (is.null(table)) return(empty)
      tables[[length(tables) + 1L]] <- table
    }
  }
  out <- unique(do.call(vctrs::vec_rbind, tables))
  out[order(out$series, out$kind, out$dimension, out$code), , drop = FALSE]
}


#' @noRd
.sdg_empty_dimensions <- function() {
  tibble::tibble(
    indicator = character(), series = character(), kind = character(),
    dimension = character(), code = character(), label = character(),
    sdmx = character()
  )
}


#' @noRd
.sdg_codebook_rows <- function(metadata, indicator, series, kind) {
  invalid <- function() {
    cli::cli_warn("SDG {kind} metadata for series {.val {series}} has an invalid structure.")
    NULL
  }
  if (is.list(metadata) && length(metadata) == 0L) return(.sdg_empty_dimensions())
  if (!is.data.frame(metadata) || !all(c("id", "codes") %in% names(metadata))) {
    return(invalid())
  }
  tables <- list(.sdg_empty_dimensions())
  for (i in seq_len(nrow(metadata))) {
    field <- as.character(metadata$id[[i]])
    if (is.na(field) || !nzchar(field)) return(invalid())
    codes <- metadata$codes[[i]]
    if (length(codes) == 0L || (is.data.frame(codes) && nrow(codes) == 0L)) {
      codes <- tibble::tibble(code = NA_character_)
    }
    if (!is.data.frame(codes) || !"code" %in% names(codes)) return(invalid())
    tables[[length(tables) + 1L]] <- tibble::tibble(
      indicator = indicator, series = series, kind = kind, dimension = field,
      code = .dsi_pick_chr(codes, "code"),
      label = .dsi_pick_chr(codes, "description"),
      sdmx = .dsi_pick_chr(codes, "sdmx")
    )
  }
  do.call(vctrs::vec_rbind, tables)
}
