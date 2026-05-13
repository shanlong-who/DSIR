# =============================================================================
# R/clean_schema.R
#
# Internal helpers for the unified 15-column schema produced by
# gho_clean() and sdg_clean() (and consumed by bind_indicators()).
# Centralises column names and types so all three functions stay in sync.
# =============================================================================


#' Column names and types for the unified cleaned-indicator schema.
#'
#' Names are returned in canonical output order. Types use short codes —
#' `"chr"` for character, `"int"` for integer, `"num"` for numeric — so a
#' single small lookup table covers both the empty-tibble template
#' (`.dsi_empty_clean()`) and the typed NA filler (`.fill_na()`).
#'
#' @noRd
.dsi_clean_schema <- function() {
  c(
    source        = "chr",
    id            = "chr",
    indicator     = "chr",
    location      = "chr",
    iso3          = "chr",
    location_name = "chr",
    year          = "int",
    value         = "chr",
    value_num     = "num",
    low           = "num",
    high          = "num",
    series        = "chr",
    dim1          = "chr",
    dim2          = "chr",
    dim3          = "chr"
  )
}


#' A 0-row tibble with the cleaned-indicator schema and correct
#' column types. Used as the fallback for empty input and for service
#' failure.
#'
#' @noRd
.dsi_empty_clean <- function() {
  schema <- .dsi_clean_schema()
  cols <- lapply(schema, function(t) .fill_na(0L, t))
  names(cols) <- names(schema)
  tibble::as_tibble(cols)
}


#' Typed NA filler of length n.
#'
#' @noRd
.fill_na <- function(n, type) {
  switch(
    type,
    chr = rep(NA_character_, n),
    int = rep(NA_integer_,   n),
    num = rep(NA_real_,      n),
    cli::cli_abort("Unknown column type: {.val {type}}.")
  )
}
