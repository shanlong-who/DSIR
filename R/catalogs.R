#' Bundled GHO Indicator Catalog from Both Backends
#'
#' An offline union of the legacy and xMart [gho_indicators()] directories.
#' A code present in both backends has two rows. Names are kept as supplied;
#' matching codes do not establish equivalent definitions or releases.
#'
#' @format A tibble with four character columns:
#' \describe{
#'   \item{IndicatorCode}{Provider indicator code.}
#'   \item{IndicatorName}{Provider indicator name.}
#'   \item{Language}{Provider language code.}
#'   \item{backend}{`legacy` or `xmart`.}
#' }
#' @details
#' Use [dsir_metadata()] for the catalog version, DSIR build version,
#' bundling time and separate source retrieval times and statuses. These
#' are snapshot records, not the current availability of observations.
#' A `bundled_snapshot` source retains its historical retrieval time when
#' the live catalog was unavailable. The xMart side follows the existing
#' English-language directory and code deduplication in [gho_indicators()].
#' This dataset does not change live discovery or backend fallback rules.
#' Refresh through `data-raw/catalogs.R` in the source repository.
#' @source WHO legacy GHO and public xMart indicator directories:
#' \url{https://www.who.int/data/gho/info/gho-odata-api} and
#' \url{https://xmart-api-public.who.int/DATA_/IND_DIRECTORY_WIDE}.
#' @seealso [sdg_catalog], [ghe_catalog], [dsir_metadata()]
#' @examples
#' head(gho_catalog)
#' table(gho_catalog$backend)
#' dsir_metadata(gho_catalog)$sources
"gho_catalog"


#' Bundled SDG Indicator and Series Catalog
#'
#' An offline snapshot of [sdg_indicators()], preserving the API's nested
#' indicator-to-series relationships and provider release labels.
#'
#' @format A tibble with eight columns:
#' \describe{
#'   \item{goal}{SDG goal code.}
#'   \item{target}{SDG target code.}
#'   \item{code}{SDG indicator code.}
#'   \item{description}{Indicator description.}
#'   \item{tier}{Provider tier code.}
#'   \item{uri}{Provider-relative indicator URI.}
#'   \item{series}{List of data frames containing the linked series and
#'     their original `code`, `description`, `release` and other fields.}
#'   \item{backend}{`unsdg`.}
#' }
#' @details
#' [dsir_metadata()] distinguishes the DSIR catalog snapshot version,
#' package build version, API version and provider release labels. A
#' release label is recorded as supplied, not inferred from retrieval time.
#' Catalog membership does not establish country/year observation coverage.
#' Refresh through `data-raw/catalogs.R` in the source repository.
#' @source UN SDG V5 indicator directory:
#' \url{https://unstats.un.org/sdgs/UNSDGAPIV5/v1/sdg/Indicator/List}.
#' @seealso [gho_catalog], [ghe_catalog], [sdg_dimensions()]
#' @examples
#' sdg_catalog[sdg_catalog$goal == "3", c("code", "description")]
#' dsir_metadata(sdg_catalog)$sources
"sdg_catalog"


#' Bundled GHE Cause and Measure Catalog
#'
#' An offline snapshot of [ghe_causes()] and [ghe_dimensions()] with
#' `dimension = "measure"`. Causes and measures are separate row kinds,
#' not a claim that every cause-measure combination has observations.
#'
#' @format A tibble with ten columns:
#' \describe{
#'   \item{kind}{`cause` or `measure`.}
#'   \item{code}{Cause code or DSIR measure code, interpreted with `kind`.}
#'   \item{label}{Cause name or measure label.}
#'   \item{backend}{`xmart`.}
#'   \item{field}{Provider measure field; missing for causes.}
#'   \item{unit}{DSIR measure unit; missing for causes.}
#'   \item{level}{Published cause level; missing for measures.}
#'   \item{cause_group}{Published cause group, not a parent identifier.}
#'   \item{rankable}{Published cause flag; missing for measures.}
#'   \item{single_cause}{Published cause flag; missing for measures.}
#' }
#' @details
#' Cause discovery uses the same latest-year, all-age, both-sex reference
#' country as [ghe_causes()]. The exact selection is recorded in
#' `dsir_metadata(ghe_catalog)$scope`; it is not a global coverage audit.
#' Measure labels and units come from DSIR's adapter, and their provider
#' fields were verified against the table schema. Reference year, retrieval
#' time, package version and catalog version are separate concepts. No
#' unreported WHO release or API version is invented.
#' Refresh through `data-raw/catalogs.R` in the source repository.
#' @source WHO public xMart GHE table:
#' \url{https://xmart-api-public.who.int/DEX_CMS/GHE_FULL}.
#' @seealso [gho_catalog], [sdg_catalog], [ghe_coverage()]
#' @examples
#' ghe_catalog[ghe_catalog$kind == "measure", c("code", "label", "unit")]
#' dsir_metadata(ghe_catalog)$scope
"ghe_catalog"


.dsi_catalog_check <- function(data, required, key) {
  if (!is.data.frame(data) || !nrow(data) || !all(required %in% names(data))) {
    cli::cli_abort("Catalog is empty or lacks required fields; the existing snapshot must be retained.")
  }
  for (field in key) {
    value <- data[[field]]
    if (!is.character(value) || anyNA(value) || any(!nzchar(trimws(value)))) {
      cli::cli_abort("Catalog key {.val {field}} contains invalid codes.")
    }
  }
  if (anyDuplicated(data[key])) cli::cli_abort("Catalog contains duplicate source keys.")
  invisible(data)
}

.dsi_catalog_gho <- function(legacy, xmart) {
  required <- c("IndicatorCode", "IndicatorName", "Language")
  parts <- list(legacy = legacy, xmart = xmart)
  for (backend in names(parts)) {
    .dsi_catalog_check(parts[[backend]], required, c("IndicatorCode", "Language"))
    out <- .dsi_data_plain(parts[[backend]][required])
    if (!all(vapply(out, is.character, logical(1)))) cli::cli_abort("GHO catalog fields must be character.")
    out$backend <- backend
    parts[[backend]] <- out
  }
  out <- vctrs::vec_rbind(!!!unname(parts))
  out[order(out$IndicatorCode, out$backend, out$Language), ]
}

.dsi_catalog_sdg <- function(data) {
  required <- c("goal", "target", "code", "description", "tier", "uri", "series")
  .dsi_catalog_check(data, required, "code")
  if (!is.list(data$series)) cli::cli_abort("SDG catalog lacks nested series metadata.")
  for (i in seq_len(nrow(data))) {
    entry <- data$series[[i]]
    if (is.null(entry) || length(entry) == 0L) next
    if (!is.data.frame(entry) || !all(c("code", "indicator", "release", "description") %in% names(entry)) ||
        anyNA(entry$code) || any(!nzchar(entry$code)) ||
        anyNA(entry$indicator)) {
      cli::cli_abort("SDG catalog contains malformed indicator-to-series links.")
    }
    # A series can carry a vector of shared indicator codes in a list-column.
    linked <- as.list(entry$indicator)
    if (any(!vapply(linked, function(codes) {
      is.character(codes) && !anyNA(codes) && data$code[[i]] %in% codes
    }, logical(1)))) {
      cli::cli_abort("SDG catalog contains unrelated indicator-to-series links.")
    }
  }
  out <- .dsi_data_plain(data[required])
  out$backend <- "unsdg"
  out
}

.dsi_catalog_ghe <- function(causes, measures) {
  .dsi_catalog_check(causes, c("cause_code", "cause_name", "level", "cause_group", "rankable", "single_cause"), "cause_code")
  .dsi_catalog_check(measures, c("code", "label", "field", "unit"), "code")
  cause.rows <- tibble::tibble(kind = "cause", code = causes$cause_code,
    label = causes$cause_name, backend = "xmart", field = NA_character_, unit = NA_character_,
    level = causes$level, cause_group = causes$cause_group,
    rankable = causes$rankable, single_cause = causes$single_cause)
  measure.rows <- tibble::tibble(kind = "measure", code = measures$code,
    label = measures$label, backend = "xmart", field = measures$field, unit = measures$unit,
    level = NA_integer_, cause_group = NA_character_, rankable = NA, single_cause = NA)
  vctrs::vec_rbind(cause.rows, measure.rows)
}

.dsi_catalog_attach <- function(data, name, sources, bundled_at, package_version, scope = list()) {
  required <- c("component", "backend", "endpoint", "retrieved_at", "retrieval_status", "record_count", "api_version", "source_release")
  .dsi_catalog_check(sources, required, c("component", "backend"))
  if (anyNA(sources$retrieved_at) || any(!nzchar(sources$retrieved_at)) ||
      any(!sources$retrieval_status %in% c("live", "bundled_snapshot")) ||
      anyNA(sources$record_count) || any(sources$record_count <= 0) ||
      sum(sources$record_count) != nrow(data)) {
    cli::cli_abort("Catalog source metadata is incomplete or inconsistent.")
  }
  attr(data, "dsir_metadata") <- list(
    schema_version = 1L, layout = "catalog", catalog_name = name,
    catalog_version = bundled_at, package_version = package_version,
    bundled_at = bundled_at, record_count = nrow(data), sources = sources, scope = scope
  )
  data
}
