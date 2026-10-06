# Package-level cache for session-scoped data. Currently used to memoise
# the GHO indicator catalog (see .gho_indicator_catalog()).
.dsi_cache <- new.env(parent = emptyenv())


#' List GHO Indicators
#'
#' Fetches the catalog of indicators from the WHO Global Health
#' Observatory (GHO) OData API.
#'
#' @param search Optional character. Search keywords matched against
#'   `IndicatorName` (case-insensitive). All terms must match
#'   (AND semantics). Accepts either:
#'   * a single string, which is split on whitespace into terms
#'     (e.g. `"child mortality"` matches indicators containing both
#'     "child" and "mortality"), or
#'   * a character vector, whose elements are used as terms verbatim
#'     (whitespace inside an element is treated as part of the term).
#'
#'   Search terms are matched literally; they are not download identifiers.
#'
#' @return A [tibble][tibble::tibble] with columns `IndicatorCode`,
#'   `IndicatorName` and `Language`. Returns an empty tibble (with
#'   a warning) when the service is unreachable.
#' @seealso [gho_data()], [gho_dimensions()].
#' @export
#'
#' @examples
#' \donttest{
#' # All indicators
#' inds <- gho_indicators()
#'
#' # Single keyword
#' gho_indicators("mortality")
#'
#' # Multiple keywords from one string (AND): both terms must appear
#' gho_indicators("child mortality")
#'
#' # Or pass terms as a vector
#' gho_indicators(c("child", "mortality"))
#' }
gho_indicators <- function(search = NULL) {
  .who_gho("indicators", search = search)
}




#' Fetch GHO Data
#'
#' Retrieves observations for a specific indicator from the WHO GHO
#' OData API, with optional filters by spatial level, country /
#' region and year range.
#'
#' @param indicator Character scalar. The indicator code
#'   (e.g. `"NCDMORT3070"`). Use [gho_indicators()] to find codes.
#' @param spatial_type Character. Spatial dimension to filter on:
#'   one of `"country"`, `"region"`, `"global"`, or `NULL` (all
#'   levels, the default).
#' @param area Character vector of country or region codes
#'   (e.g. `c("FRA", "DEU")`). Default `NULL` returns all areas.
#' @param year_from Numeric. Start year filter (inclusive).
#'   Default `NULL`.
#' @param year_to Numeric. End year filter (inclusive).
#'   Default `NULL`.
#' @param dim1,dim2,dim3 Character vector of values to keep for the
#'   `Dim1` / `Dim2` / `Dim3` breakdown columns, filtered server-side
#'   (e.g. `dim1 = "SEX_BTSX"` for both-sexes rows only, or
#'   `dim1 = c("SEX_MLE", "SEX_FMLE")`). The meaning of each dimension
#'   varies by indicator (`Dim1` is sex for one indicator, an age
#'   group for another); use [gho_dimensions()] to discover the values
#'   available for a given indicator. Rows where the dimension is
#'   empty (`null`) are excluded by the filter. Default `NULL` (no
#'   filtering). On xMart wide tables, positions follow named dimensions
#'   in the source table schema (sex, age, then alphabetical).
#'   These positions can differ from the legacy API. Prefer `dimensions`.
#'   Canonical sex codes and the `AGEGROUP_` namespace remain supported in
#'   positional filters. Named filters use the provider's exact native codes.
#' @param dimensions Optional named list of exact xMart dimension fields and
#'   values, e.g. `list(DIM_SEX = 'TOTAL')`. Requires the xMart backend.
#' @details
#' Uses the public production xMart backend by default. Advanced users may
#' set `DSIR.who_backend = "legacy"` for explicit comparisons, or set
#' `DSIR.who_base_url` to another compatible HTTPS origin. Failures never
#' trigger a silent fallback. Public directory coverage differs from the
#' legacy catalog; unknown codes warn instead of substituting another code.
#' Reference lookups are cached only in memory; no credentials
#' or startup requests are required.
#'
#' @return A [tibble][tibble::tibble] of indicator observations, or
#'   an empty tibble when the service is unreachable.
#' @seealso [gho_indicators()], [gho_dimensions()].
#' @export
#'
#' @examples
#' \donttest{
#' # Country-level data for one indicator
#' gho_data("NCDMORT3070", spatial_type = "country")
#'
#' # Specific countries and years
#' gho_data("WHOSIS_000001", area = c("FRA", "DEU"), year_from = 2015)
#'
#' # Keep only the both-sexes breakdown, filtered server-side
#' gho_data("NCDMORT3070", spatial_type = "country", dim1 = "SEX_BTSX")
#' }
gho_data <- function(indicator, spatial_type = NULL, area = NULL, year_from = NULL, year_to = NULL, dim1 = NULL, dim2 = NULL, dim3 = NULL, dimensions = NULL) {
  .who_gho("data", indicator = indicator, spatial_type = spatial_type, area = area, year_from = year_from, year_to = year_to, dim1 = dim1, dim2 = dim2, dim3 = dim3, dimensions = dimensions)
}




#' Check Whether a GHO Indicator Has Data for a Filter
#'
#' Sends a minimal request (`$top=1` with a row count) to the WHO GHO OData
#' API to find out whether any observations exist for the given
#' indicator and filter combination, without downloading the full
#' result set. Useful as a quick precheck before [gho_data()].
#'
#' @inheritParams gho_data
#'
#' @return A logical scalar:
#' * `TRUE` if at least one observation exists for the filter.
#' * `FALSE` if the server returns an empty result.
#' * `NA` if the request fails (network failure, unreachable host,
#'   or the indicator code does not exist and the server returns an
#'   HTTP error). A warning is emitted in the failure case.
#' @seealso [gho_data()], [gho_count()], [gho_coverage()].
#' @export
#'
#' @examples
#' \donttest{
#' # Does WHO have life-expectancy data for France?
#' gho_has_data("WHOSIS_000001", area = "FRA")
#'
#' # Quickly screen a list of indicators before downloading any data
#' inds <- c("WHOSIS_000001", "NCDMORT3070")
#' vapply(inds, gho_has_data, logical(1), area = "FRA")
#' }
gho_has_data <- function(indicator, spatial_type = NULL, area = NULL, year_from = NULL, year_to = NULL, dim1 = NULL, dim2 = NULL, dim3 = NULL, dimensions = NULL) {
  .who_gho("has_data", indicator = indicator, spatial_type = spatial_type, area = area, year_from = year_from, year_to = year_to, dim1 = dim1, dim2 = dim2, dim3 = dim3, dimensions = dimensions)
}


#' Count Observations for a GHO Indicator Filter
#'
#' Sends a `$top=0&$count=true` request to the WHO GHO OData API,
#' which returns the matching row count without transferring any
#' observations. Useful for sizing a download before issuing it.
#'
#' @inheritParams gho_data
#'
#' @return An integer scalar — the number of observations the
#'   server would return for the same filter via [gho_data()].
#'   Returns `NA_integer_` (with a warning) if the request fails.
#' @seealso [gho_data()], [gho_has_data()], [gho_coverage()].
#' @export
#'
#' @examples
#' \donttest{
#' # How many rows would gho_data() pull for France?
#' gho_count("WHOSIS_000001", area = "FRA")
#'
#' # Compare coverage across regions
#' gho_count("NCDMORT3070", spatial_type = "country")
#' gho_count("NCDMORT3070", spatial_type = "region")
#' }
gho_count <- function(indicator, spatial_type = NULL, area = NULL, year_from = NULL, year_to = NULL, dim1 = NULL, dim2 = NULL, dim3 = NULL, dimensions = NULL) {
  .who_gho("count", indicator = indicator, spatial_type = spatial_type, area = area, year_from = year_from, year_to = year_to, dim1 = dim1, dim2 = dim2, dim3 = dim3, dimensions = dimensions)
}


#' Summarise Per-Location Data Coverage of a GHO Indicator
#'
#' Fetches only the `SpatialDim` and `TimeDim` columns for a GHO
#' indicator (much lighter than [gho_data()]) and summarises the
#' year range and observation count per location. Useful for
#' answering "which countries have data, and for what years?"
#' before committing to a full download.
#'
#' @param indicator Character scalar. The indicator code
#'   (e.g. `"WHOSIS_000001"`).
#' @param spatial_type Character. Spatial dimension to filter on:
#'   one of `"country"`, `"region"`, `"global"`. Defaults to
#'   `"country"` since per-country coverage is the typical use
#'   case. Pass `NULL` for all spatial levels.
#' @param area Character vector of country or region codes
#'   (e.g. `c("FRA", "DEU")`). Default `NULL` returns all areas
#'   for the chosen `spatial_type`.
#' @param year_from Numeric. Start year filter (inclusive).
#'   Default `NULL`.
#' @param year_to Numeric. End year filter (inclusive).
#'   Default `NULL`.
#' @inheritParams gho_data
#'
#' @return A [tibble][tibble::tibble] with one row per location and
#'   columns:
#' * `location` (chr) — the `SpatialDim` value (typically ISO3).
#' * `year_min` (int) — earliest year with data.
#' * `year_max` (int) — latest year with data.
#' * `n_obs` (int) — number of observations.
#'
#'   Sorted by `location`. Empty input or service failure returns
#'   an empty tibble with the same four columns.
#' @seealso [gho_data()], [gho_has_data()], [gho_count()].
#' @export
#'
#' @examples
#' \donttest{
#' # Year coverage of life expectancy for three countries
#' gho_coverage("WHOSIS_000001", area = c("FRA", "DEU", "JPN"))
#'
#' # All countries with any life-expectancy data, since 2010
#' gho_coverage("WHOSIS_000001", year_from = 2010)
#' }
gho_coverage <- function(indicator, spatial_type = "country", area = NULL, year_from = NULL, year_to = NULL, dim1 = NULL, dim2 = NULL, dim3 = NULL, dimensions = NULL) {
  .who_gho("coverage", indicator = indicator, spatial_type = spatial_type, area = area, year_from = year_from, year_to = year_to, dim1 = dim1, dim2 = dim2, dim3 = dim3, dimensions = dimensions)
}


#' List Dimensions of a GHO Indicator
#'
#' Returns the unique values of a given dimension across all
#' observations of a GHO indicator. Useful for discovering which
#' ages, sexes, regions, or other breakdowns are available before
#' calling [gho_data()].
#'
#' @param indicator Character scalar. The indicator code
#'   (e.g. `"NCDMORT3070"`).
#' @param dimension Character. Name of the dimension column in the
#'   indicator data. Common values include `"SpatialDim"`,
#'   `"SpatialDimType"`, `"TimeDim"`, `"Dim1"`, `"Dim2"`, and
#'   `"Dim3"`. Case-sensitive (it is sent to the server as an OData
#'   `$select` field name). xMart also accepts exact named fields such as
#'   `"DIM_SEX"` or `"DIM_AGE"`. Default `"SpatialDimType"`.
#'
#' @details
#' Only the requested column is downloaded (via the OData `$select`
#' query option), so this is a lightweight metadata query even for
#' indicators with hundreds of thousands of observations. A
#' `dimension` that is not a column of the GHO data table (e.g. a
#' misspelling) makes the server reject the request; the failure
#' surfaces as a warning and an empty character vector.
#'
#' @return A character vector of unique, sorted dimension values,
#'   or an empty character vector when the service is unreachable
#'   or the dimension is missing.
#' @seealso [gho_data()], [gho_indicators()].
#' @export
#'
#' @examples
#' \donttest{
#' gho_dimensions("NCDMORT3070")
#' gho_dimensions("NCDMORT3070", dimension = "Dim1")
#' }
gho_dimensions <- function(indicator, dimension = "SpatialDimType") {
  .who_gho("dimensions", indicator = indicator, dimension = dimension)
}


#' @noRd
.gho_indicator_catalog <- function() {
  key <- paste(.who_config()$backend, .who_config()$base, sep = '|')
  if (!identical(.dsi_cache$gho_catalog_key, key)) {
    .dsi_cache$gho_indicator_catalog <- NULL
    .dsi_cache$gho_catalog_key <- key
  }
  if (is.null(.dsi_cache$gho_indicator_catalog)) {
    catalog <- gho_indicators()
    # A failed fetch returns an empty tibble (fail-soft), which must
    # NOT be cached: caching it would pin `indicator = NA` for the
    # rest of the session even after connectivity returns. The real
    # catalog is never empty, so nrow > 0 is a safe cache condition.
    if (nrow(catalog) == 0L) return(catalog)
    .dsi_cache$gho_indicator_catalog <- catalog
  }
  .dsi_cache$gho_indicator_catalog
}


#' @noRd
.gho_resolve_location_name <- function(location) {
  if (length(location) == 0L) return(character(0))

  # WHO regional and aggregate codes. Hardcoded because they are stable
  # and not part of who_countries (which lists Member States only).
  region_names <- c(
    AFR    = "Africa",
    AMR    = "Americas",
    SEAR   = "South-East Asia",
    EUR    = "Europe",
    EMR    = "Eastern Mediterranean",
    WPR    = "Western Pacific",
    GLOBAL = "Global"
  )

  out <- rep(NA_character_, length(location))

  iso3_match <- match(location, who_countries$iso3)
  has_iso3 <- !is.na(iso3_match)
  out[has_iso3] <- who_countries$name_short[iso3_match[has_iso3]]

  region_match <- match(location, names(region_names))
  has_region <- !is.na(region_match)
  out[has_region] <- region_names[region_match[has_region]]

  out
}


#' @noRd
.gho_resolve_indicator_name <- function(codes) {
  if (all(is.na(codes))) return(.fill_na(length(codes), "chr"))

  catalog <- .gho_indicator_catalog()

  if (nrow(catalog) == 0L) return(.fill_na(length(codes), "chr"))

  catalog$IndicatorName[match(codes, catalog$IndicatorCode)]
}


#' Tidy a GHO Data Frame
#'
#' Selects, renames, and type-casts the most useful columns from a GHO
#' observation table returned by [gho_data()], producing a compact
#' tibble in the **unified DSIR cleaned-indicator schema** — the same
#' schema produced by [sdg_clean()], so the two outputs can be combined
#' directly with [bind_indicators()].
#'
#' The mapping (GHO source → unified column) is:
#' * `IndicatorCode` → `id`
#' * `IndicatorCode` resolved against the GHO indicator catalog →
#'   `indicator` (the human-readable name; cached at session level
#'   after the first call)
#' * `SpatialDim`    → `location`; also `iso3` when it matches a WHO
#'   Member State, otherwise `iso3 = NA`
#' * `TimeDim`       → `year` (integer)
#' * `Value`         → `value` (character; raw)
#' * `NumericValue`  → `value_num` (numeric)
#' * `Low`, `High`   → `low`, `high` (numeric)
#' * `Dim1`, `Dim2`, `Dim3` → `dim1`, `dim2`, `dim3` (character)
#'
#' The `series` column is always `NA` for GHO output (it is an SDG-only
#' concept; GHE uses it for measure codes). The `location_name` column is populated by looking up
#' `location` (an ISO3 code or a WHO region code) against the
#' [`who_countries`] dataset and a hardcoded set of WHO regional names;
#' other locations use a published `SpatialName` when available, otherwise
#' they remain `NA`.
#'
#' Source columns absent from `df` (e.g. `Low` / `High` for indicators
#' without confidence intervals) are filled with typed `NA`, so the
#' default output always has the same 15 columns with the same column types.
#'
#' xMart supplies indicator labels through its official directory. Legacy
#' observations without an `IndicatorName` use [gho_indicators()].
#' For such input, on the first call within an R session,
#' `gho_clean()` fetches the catalog once and caches it for the rest of
#' the session, so the `indicator` column carries the full
#' human-readable indicator name. If the catalog cannot be fetched
#' (e.g. no network), [gho_indicators()] emits a warning and the
#' `indicator` column falls back to `NA`.
#'
#' @param df A data frame returned by [gho_data()].
#' @param keep_dimensions Logical. Append `dim1_type`, `dim2_type`, and
#'   `dim3_type` from the source's `Dim1Type`, `Dim2Type`, and `Dim3Type`?
#'   Default `FALSE`. Types are kept per row: one indicator can use the
#'   same position for different dimensions. No type is guessed from a
#'   code's spelling, and missing types remain `NA`. xMart output also
#'   retains all named source dimensions as `dim_*` character columns.
#' @param keep_metadata Logical. Retain source context? Default `FALSE`.
#'   With `TRUE`, appends character columns `observation_id`, `spatial_type`,
#'   `time_type`, `data_source_type`, `data_source`, `updated`,
#'   `parent_location`, `parent_location_name`, `time_detail`, `time_start`,
#'   and `time_end`, copied from the raw API fields. Raw `Comments` are kept
#'   as `footnotes`, a list-column of character vectors. Missing scalar
#'   fields are `NA`; missing list fields are empty character vectors.
#'   This option is independent of `keep_dimensions`. Unit and dimension
#'   labels are not inferred. xMart output also retains `unit`,
#'   `measure_field`, `spatial_type_source`, and a `who_provenance` attribute.
#'   Retaining these fields makes no extra
#'   network requests beyond the usual indicator-name lookup.
#'
#' @return A [tibble][tibble::tibble] with 15 core columns: `source` (always
#'   `"gho"`), `id`, `indicator`, `location`, `iso3`, `location_name`,
#'   `year`, `value`, `value_num`, `low`, `high`, `series` (`NA`),
#'   `dim1`, `dim2`, `dim3`. Sorted by `location` then `year`.
#'   Empty input returns an empty tibble with the same columns and
#'   types. Optional dimension types and metadata follow the core columns.
#' @seealso [gho_data()], [sdg_clean()], [bind_indicators()].
#' @export
#'
#' @examples
#' \donttest{
#' gho_data("NCDMORT3070", spatial_type = "country") |>
#'   gho_clean()
#' }
gho_clean <- function(df, keep_dimensions = FALSE, keep_metadata = FALSE) {
  if (!is.data.frame(df)) {
    cli::cli_abort("{.arg df} must be a data frame.")
  }
  .dsi_check_flag(keep_dimensions, "keep_dimensions")
  .dsi_check_flag(keep_metadata, "keep_metadata")

  n <- nrow(df)
  if (n == 0L) {
    out <- .dsi_empty_clean()
    if (keep_dimensions) out <- .gho_append_dimensions(out, df)
    if (keep_metadata) out <- .gho_append_metadata(out, df)
    return(out)
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

  location <- pick_chr("SpatialDim")
  iso3     <- ifelse(location %in% who_countries$iso3,
                     location, NA_character_)

  out <- tibble::tibble(
    source        = rep("gho", n),
    id            = pick_chr("IndicatorCode"),
    indicator     = if ('IndicatorName' %in% names(df)) pick_chr('IndicatorName') else
      .gho_resolve_indicator_name(pick_chr("IndicatorCode")),
    location      = location,
    iso3          = iso3,
    location_name = .gho_resolve_location_name(location),
    year          = pick_int("TimeDim"),
    value         = pick_chr("Value"),
    value_num     = pick_num("NumericValue"),
    low           = pick_num("Low"),
    high          = pick_num("High"),
    series        = .fill_na(n, "chr"),
    dim1          = pick_chr("Dim1"),
    dim2          = pick_chr("Dim2"),
    dim3          = pick_chr("Dim3")
  )
  if (keep_dimensions) out <- .gho_append_dimensions(out, df)
  if (keep_metadata) out <- .gho_append_metadata(out, df)

  missing_name <- is.na(out$location_name)
  if ('SpatialName' %in% names(df)) out$location_name[missing_name] <- pick_chr('SpatialName')[missing_name]
  attr(out, 'who_provenance') <- attr(df, 'who_provenance')

  out[order(out$location, out$year), , drop = FALSE]
}
