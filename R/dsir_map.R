#' Map an Indicator with Recorded or User-Supplied Boundaries
#'
#' Draw a choropleth from a [dsir_data][as_dsir_data] object, an ordinary
#' data frame or an `sf` table. Return a standard ggplot. WHO ADM0 boundaries
#' are downloaded by country only with permission and cached outside the
#' package. Alternatively, supply your own polygons for an offline map.
#'
#' @param data A data frame with one row per mapped area. A `dsir_data` object
#'   uses its existing semantic checks. An `sf` input supplies its own geometry.
#' @param value Name of the numeric value column, default `"value_num"`.
#'   For `dsir_data`, use `value_num`; for a derived measure, supply an ordinary
#'   analysis table with its units defined explicitly instead of borrowing the
#'   original indicator's metadata.
#' @param country Name of the area-key column, default `"iso3"`. WHO downloads
#'   require uppercase three-letter ISO3 codes. User-supplied boundaries can
#'   use other character or factor keys; matching is exact.
#' @param year Optional single integer-valued year, selecting the `year`
#'   column. If that column exists, the selected data must contain one common
#'   non-missing year. No latest-year selection or aggregation occurs.
#' @param boundaries Optional `sf` polygons. If omitted, use geometry in
#'   `data`, or obtain WHO ADM0 polygons. No other source is used to fill gaps.
#' @param boundary_key Key column in `boundaries`. Defaults to `country` when
#'   present, otherwise `"ISO_3_CODE"`. Each requested key must match exactly
#'   one polygon or multipolygon row. Extra, unrequested areas are not drawn.
#' @param download Download policy: `"ask"` (default) asks interactively when
#'   uncached countries are needed; in non-interactive sessions it errors with
#'   guidance. `"allow"` explicitly permits downloads; `"never"` requires a
#'   valid cache or user-supplied geometry. No downloads occur on package load.
#' @param cache_dir Directory for the country cache. Defaults to the `maps`
#'   subdirectory of `tools::R_user_dir("DSIR", "cache")`. Supply a project
#'   directory to retain the exact boundaries used by an analysis.
#' @param refresh Logical, default `FALSE`. Explicitly download fresh WHO
#'   polygons even when cached. Download permission is still required. Failed
#'   or invalid downloads never replace a valid country cache.
#' @param crs Optional display coordinate reference system passed to
#'   [ggplot2::coord_sf()]. It does not change cached source geometries.
#'
#' @return A ggplot using [theme_dsi()] and a continuous viridis scale.
#'   Missing estimates are shown in grey. Its data is an `sf` table containing
#'   the selected analysis columns and matched geometry. [dsir_metadata()]
#'   reports map-creation context, input metadata and boundary provenance;
#'   this record does not audit subsequent ggplot modifications.
#'
#' @details
#' The optional package `sf` is required only when this function is used.
#' Filter to one indicator, measure, unit and population stratum before
#' mapping. Known semantic fields in ordinary tables are checked as well;
#' fields absent from such tables cannot be verified. Ordinary tables should
#' provide a constant `unit` column when units are known. A matching key alone
#' does not establish geographic or temporal comparability.
#'
#' Empty or invalid geometries, unknown coordinate systems, missing areas and
#' duplicate keys cause errors. Geometries are never repaired, simplified,
#' dissolved or combined with another source automatically. The WHO ADM0
#' service returned empty Philippine geometry during development; a Philippine
#' map therefore requires corrected official data or complete user-supplied
#' boundaries. This is validated from each response, not a country blacklist.
#'
#' Downloads use the public WHO `Detailed_Boundary_ADM0` Feature Service,
#' layer 0, item `39663258d2b44dcaa28af952ed40760b`, without authentication.
#' Its item terms require use without modification and link to
#' \url{https://data.who.int/about/data/terms-and-conditions}.
#' Consult the source terms and appropriate cartographic presentation for
#' your output. Permission to download does not certify geometry completeness.
#'
#' The downloader verifies one stable feature identifier per country and
#' checks the returned country, coordinate system and geometry before caching.
#' Each cache records its endpoint, query, retrieval time, item modification
#' time, source terms and download checksum. Item modification time is not an
#' official boundary reference date. Cache use preserves retrieval time and
#' makes no network calls. Cached countries may have different retrieval dates;
#' inspect the boundary records when a common snapshot is required.
#' @seealso [plot.dsir_data()], [dsir_metadata()]
#' @export
#' @examples
#' if (requireNamespace("sf", quietly = TRUE)) {
#'   # Artificial polygons and values for an entirely offline example.
#'   square <- function(x) sf::st_polygon(list(matrix(
#'     c(x, 0, x + 1, 0, x + 1, 1, x, 1, x, 0), ncol = 2, byrow = TRUE)))
#'   borders <- sf::st_sf(code = c("A", "B"),
#'     geometry = sf::st_sfc(square(0), square(1), crs = 4326))
#'   values <- data.frame(code = c("A", "B"), rate = c(10, 20), unit = "percent")
#'   p <- dsir_map(values, value = "rate", country = "code", boundaries = borders)
#'   p
#'   dsir_metadata(p)$boundaries
#' }
dsir_map <- function(data, value = "value_num", country = "iso3", year = NULL,
                     boundaries = NULL, boundary_key = NULL,
                     download = c("ask", "allow", "never"), cache_dir = NULL,
                     refresh = FALSE, crs = NULL) {
  if (!requireNamespace("sf", quietly = TRUE)) {
    cli::cli_abort("Mapping requires the optional {.pkg sf} package; install it with {.code install.packages('sf')}.")
  }
  download <- match.arg(download)
  .dsi_check_flag(refresh, "refresh")
  if (!is.data.frame(data)) cli::cli_abort("{.arg data} must be a data frame or sf table.")
  if (inherits(data, c("grouped_df", "rowwise_df"))) cli::cli_abort("Ungroup {.arg data} before mapping.")
  if (anyDuplicated(names(data)) || anyNA(names(data)) || any(!nzchar(names(data)))) {
    cli::cli_abort("Analysis column names must be unique and non-empty.")
  }
  for (arg in c("value", "country")) {
    field <- if (arg == "value") value else country
    if (!is.character(field) || length(field) != 1L || is.na(field) || !field %in% names(data)) {
      cli::cli_abort("{.arg {arg}} must name one column in {.arg data}.")
    }
  }
  structured <- inherits(data, "dsir_data")
  if (structured && value != "value_num") {
    cli::cli_abort("For derived measures, supply an ordinary analysis table with explicit units; DSIR metadata describes {.field value_num}.")
  }
  if (inherits(data, "sf")) {
    if (!is.null(boundaries)) cli::cli_abort("Supply geometry in {.arg data} or {.arg boundaries}, not both.")
    boundaries <- data
    boundary_key <- boundary_key %||% country
    data <- sf::st_drop_geometry(data)
  }
  if (!nrow(data)) cli::cli_abort("No observations remain to map.")
  if (!is.numeric(data[[value]]) || is.object(data[[value]]) || !is.null(dim(data[[value]]))) {
    cli::cli_abort("The mapped value column must be numeric.")
  }
  if (any(!is.finite(data[[value]]) & !is.na(data[[value]]))) cli::cli_abort("Infinite values cannot be mapped.")
  if (!is.null(year)) {
    if (!is.numeric(year) || length(year) != 1L || !is.finite(year) || year != trunc(year)) {
      cli::cli_abort("{.arg year} must be a single finite integer-valued year.")
    }
    if (!"year" %in% names(data)) cli::cli_abort("A {.field year} column is needed to select {.arg year}.")
    data <- data[!is.na(data$year) & data$year == year, , drop = FALSE]
    if (!nrow(data)) cli::cli_abort("No observations match the requested year.")
  }
  if ("year" %in% names(data)) {
    if (!is.numeric(data$year) || is.object(data$year) || anyNA(data$year) ||
        any(!is.finite(data$year) | data$year != trunc(data$year)) || length(unique(data$year)) != 1L) {
      cli::cli_abort("Maps require one common non-missing integer-valued year; select {.arg year} or filter first.")
    }
  }
  keys <- .dsi_map_keys(data[[country]], "Analysis")
  if (anyDuplicated(keys)) cli::cli_abort("Duplicate analysis keys; select one observation per area before mapping.")
  recorded <- attr(data, "dsir_metadata", exact = TRUE)
  metadata <- if (is.null(recorded)) list() else dsir_metadata(data)
  plain <- .dsi_data_plain(data)
  context.data <- plain
  # An ordinary table's `id` can be an area/row key, not an indicator code.
  if (!structured && !any(c("indicator", "series") %in% names(plain))) context.data$id <- NULL
  context <- .dsi_plot_context(context.data, metadata, mapped = c(country, value),
                               interval = FALSE, require_indicator = structured)
  if (is.null(context$title)) context$title <- value
  if (identical(context$unit, "Value (unit not recorded)")) context$unit <- paste0(value, " (unit not recorded)")
  if (is.null(boundaries)) {
    if (!is.null(boundary_key)) cli::cli_abort("{.arg boundary_key} applies only to supplied boundaries.")
    if (any(!grepl("^[A-Z]{3}$", keys))) cli::cli_abort("WHO ADM0 downloads require uppercase three-letter ISO3 keys.")
    result <- .dsi_map_who_boundaries(keys, download, cache_dir, refresh)
    borders <- result$data
    boundary.metadata <- result$metadata
  } else {
    if (refresh) cli::cli_abort("{.arg refresh} applies only to downloaded WHO boundaries.")
    if (is.null(boundary_key)) boundary_key <- if (country %in% names(boundaries)) country else "ISO_3_CODE"
    borders <- .dsi_map_select_boundaries(boundaries, boundary_key, keys)
    boundary.metadata <- list(origin = "user_supplied", key = boundary_key,
      countries = keys, crs = sf::st_crs(borders)$wkt,
      supplied_metadata = attr(boundaries, "dsir_metadata", exact = TRUE))
  }
  map.data <- sf::st_sf(plain, geometry = sf::st_geometry(borders))
  missing <- sum(is.na(map.data[[value]]))
  subtitle <- c(if ("year" %in% names(plain)) paste("Year:", unique(plain$year)), context$strata)
  caption <- c(context$caption,
    if (boundary.metadata$origin == "who_gis") "Boundaries: WHO ADM0" else "Boundaries: user supplied",
    if (missing) paste("Grey: missing estimate; areas:", missing))
  p <- ggplot2::ggplot(map.data, ggplot2::aes(fill = .data[[value]])) +
    ggplot2::geom_sf(colour = "grey50", linewidth = 0.2) +
    ggplot2::scale_fill_viridis_c(end = 0.9, na.value = "grey85", name = context$unit) +
    ggplot2::coord_sf(crs = crs, datum = NA) + theme_dsi(grid = "none") +
    ggplot2::theme(axis.line.x = ggplot2::element_blank(),
      axis.line.y = ggplot2::element_blank(), axis.ticks = ggplot2::element_blank(),
      axis.text = ggplot2::element_blank(), panel.grid = ggplot2::element_blank()) +
    ggplot2::labs(title = context$title, subtitle = paste(subtitle, collapse = " | "),
                  caption = paste(caption, collapse = "\n"))
  attr(p, "dsir_metadata") <- list(schema_version = 1L, layout = "map",
    created_at = .dsi_timestamp(), selection = list(country_column = country,
      value_column = value, keys = keys, year = if ("year" %in% names(plain)) unique(plain$year) else NULL,
      rows = nrow(plain), missing_values = missing),
    data = metadata, boundaries = boundary.metadata)
  p
}

.dsi_map_keys <- function(x, label, allow_missing = FALSE) {
  if ((!is.character(x) && !is.factor(x)) || !is.null(dim(x)) ||
      (!allow_missing && (anyNA(x) || any(!nzchar(trimws(as.character(x))))))) {
    cli::cli_abort("{label} keys must be non-missing character or factor values.")
  }
  as.character(x)
}

.dsi_map_select_boundaries <- function(boundaries, key, keys) {
  if (!inherits(boundaries, "sf")) cli::cli_abort("{.arg boundaries} must be an sf table.")
  if (!is.character(key) || length(key) != 1L || is.na(key) || !key %in% names(boundaries)) {
    cli::cli_abort("{.arg boundary_key} must name a column in the boundary table.")
  }
  ids <- .dsi_map_keys(boundaries[[key]], "Boundary", allow_missing = TRUE)
  selected <- ids %in% keys
  if (anyDuplicated(ids[selected])) cli::cli_abort("Duplicate boundary keys; supply one polygon or multipolygon row per area.")
  absent <- setdiff(keys, ids)
  if (length(absent)) cli::cli_abort("Boundary geometry is missing for {.val {absent}}.")
  out <- boundaries[match(keys, ids), , drop = FALSE]
  if (is.na(sf::st_crs(out))) cli::cli_abort("Boundary coordinate reference system is missing; verify it before mapping.")
  empty <- sf::st_is_empty(out)
  if (any(empty)) cli::cli_abort("Empty boundary geometry for {.val {keys[empty]}}; obtain corrected source data or supply complete sf boundaries.")
  if (any(!as.character(sf::st_geometry_type(out)) %in% c("POLYGON", "MULTIPOLYGON"))) {
    cli::cli_abort("Map boundaries must be polygons or multipolygons.")
  }
  valid <- sf::st_is_valid(out)
  if (anyNA(valid) || any(!valid)) cli::cli_abort("Invalid boundary geometry for {.val {keys[is.na(valid) | !valid]}}; no automatic repair is performed.")
  out
}
