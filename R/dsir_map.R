#' Map an Indicator with Recorded or User-Supplied Boundaries
#'
#' Draw a choropleth or a point-symbol map from a
#' [dsir_data][as_dsir_data] object or an ordinary data frame. Polygon maps
#' also accept an `sf` table or supplied polygons. WHO ADM0 polygons and
#' centre coordinates are requested only with permission and cached
#' outside the package. Return a standard ggplot.
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
#'   polygons or centre coordinates even when cached. Download permission
#'   is still required. Failed or invalid downloads never replace a valid
#'   country cache.
#' @param crs Optional display coordinate reference system passed to
#'   [ggplot2::coord_sf()]. It does not change cached source geometries.
#' @param type Map type. `"polygon"` (default) uses polygons.
#'   `"point"` reads the published `CENTER_LON` and `CENTER_LAT` fields of
#'   the same WHO ADM0 layer. Use a regular analysis table without supplied
#'   boundaries in this mode.
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
#' duplicate keys cause errors. Geometries are used as supplied. If WHO ADM0
#' returns empty or invalid geometry, obtain a corrected WHO boundary or
#' provide a complete, validated `sf` table using `boundaries`. After a
#' correction to the WHO service, set `refresh = TRUE` to request a fresh copy.
#'
#' Point maps require one finite, in-range coordinate pair per requested
#' ISO3 code. They cache coordinates separately and emit a message with the
#' UTC retrieval date or dates and the unverified WHO GIS release status.
#' These dates also appear in the caption and the map metadata as records
#' of coordinate retrieval.
#' For Western Pacific codes in [wpro_cty], centres outside the display
#' extent (88°E to 141°W across the date line and 48°S to 53°N) are flagged
#' in the caption and metadata. Western Pacific maps using the default
#' projection display flagged points in a world locator when the main view
#' has points. Other projections display flagged points at their reported
#' positions. Every requested point remains in the returned `sf` data.
#'
#' Boundary validation errors have class `dsir_map_boundary_error` and a
#' `diagnostics` field with area keys, validation reasons, engine and version,
#' check time and source context. For geometry downloads, source context
#' can include the query URL, HTTP status, file size, checksum and ArcGIS
#' error code. ArcGIS can report a service error, including rate limiting,
#' in a response with HTTP status 200. Follow the reported retry interval
#' when the service is rate limiting requests. Catch with
#' `tryCatch(dsir_map(...), dsir_map_boundary_error = function(e) e)` and
#' inspect or save the returned condition's `diagnostics` field. S2 validates
#' geographic coordinates when enabled in sf; otherwise GEOS is used.
#' Structural checks (including empty geometry) are labelled sf. A boundary
#' can render on a web map while failing topology validation; this does not
#' mean its geometry is missing. Unknown validity also causes an error.
#' Successful maps retain validation records in
#' `dsir_metadata(map)$boundaries$validation`. Cache reads validate again;
#' invalid-cache warnings retain geometry diagnostics when available.
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
#' The GeoJSON reader uses a temporary 512 MiB feature parsing limit for
#' WHO downloads when `OGR_GEOJSON_MAX_OBJ_SIZE` is unset. An explicit
#' GDAL setting takes precedence.
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
                     refresh = FALSE, crs = NULL, type = c("polygon", "point")) {
  if (!requireNamespace("sf", quietly = TRUE)) {
    cli::cli_abort("Mapping requires the optional {.pkg sf} package; install it with {.code install.packages('sf')}.")
  }
  download <- match.arg(download)
  type <- match.arg(type)
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
  if (type == "point" && (inherits(data, "sf") || !is.null(boundaries) || !is.null(boundary_key))) {
    cli::cli_abort("Point maps use WHO ADM0 centre coordinates. Supply an analysis table without geometry or boundary arguments.")
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
    result <- if (type == "point") .dsi_map_who_centres(keys, download, cache_dir, refresh) else
      .dsi_map_who_boundaries(keys, download, cache_dir, refresh)
    borders <- result$data
    boundary.metadata <- result$metadata
  } else {
    if (refresh) cli::cli_abort("{.arg refresh} applies only to downloaded WHO boundaries.")
    if (is.null(boundary_key)) boundary_key <- if (country %in% names(boundaries)) country else "ISO_3_CODE"
    borders <- .dsi_map_select_boundaries(boundaries, boundary_key, keys)
    boundary.metadata <- list(origin = "user_supplied", key = boundary_key,
      countries = keys, crs = sf::st_crs(borders)$wkt,
      validation = list(attr(borders, "dsir_boundary_validation", exact = TRUE)),
      supplied_metadata = attr(boundaries, "dsir_metadata", exact = TRUE))
  }
  map.data <- sf::st_sf(plain, geometry = sf::st_geometry(borders))
  missing <- sum(is.na(map.data[[value]]))
  subtitle <- c(if ("year" %in% names(plain)) paste("Year:", unique(plain$year)), context$strata)
  if (type == "point") {
    outliers <- boundary.metadata$outliers$iso3
    p <- .dsi_map_draw_points(map.data, keys, value, country, context$unit, crs, outliers)
    geo.caption <- c(boundary.metadata$note, if (length(outliers))
      paste0("Reported centres outside the Western Pacific display: ", paste(outliers, collapse = ", "), "."))
    message(boundary.metadata$note)
  } else {
    geo.caption <- if (boundary.metadata$origin == "who_gis") "Boundaries: WHO ADM0" else "Boundaries: user supplied"
    p <- ggplot2::ggplot(map.data, ggplot2::aes(fill = .data[[value]])) +
      ggplot2::geom_sf(colour = "grey50", linewidth = 0.2) +
      ggplot2::scale_fill_viridis_c(end = 0.9, na.value = "grey85", name = context$unit) +
      ggplot2::coord_sf(crs = crs, datum = NA)
  }
  caption <- c(context$caption, geo.caption, if (missing) paste("Grey: missing estimate; areas:", missing))
  p <- p + theme_dsi(grid = "none") +
    ggplot2::theme(axis.line.x = ggplot2::element_blank(),
      axis.line.y = ggplot2::element_blank(), axis.ticks = ggplot2::element_blank(),
      axis.text = ggplot2::element_blank(), panel.grid = ggplot2::element_blank()) +
    ggplot2::labs(title = context$title, subtitle = paste(subtitle, collapse = " | "),
                  caption = paste(caption, collapse = "\n"))
  if (type == "point") {
    p <- p + ggplot2::labs(x = NULL, y = NULL) +
      ggplot2::theme(
        panel.grid = ggplot2::element_line(colour = "#D6E5EC", linewidth = 0.25),
        panel.grid.minor = ggplot2::element_blank(),
        panel.background = ggplot2::element_rect(fill = "#F6FAFC", colour = NA),
        plot.caption = ggplot2::element_text(hjust = 0))
  }
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

.dsi_map_select_boundaries <- function(boundaries, key, keys, source = list(origin = "user_supplied")) {
  if (!inherits(boundaries, "sf")) cli::cli_abort("{.arg boundaries} must be an sf table.")
  if (!is.character(key) || length(key) != 1L || is.na(key) || !key %in% names(boundaries)) {
    cli::cli_abort("{.arg boundary_key} must name a column in the boundary table.")
  }
  ids <- .dsi_map_keys(boundaries[[key]], "Boundary", allow_missing = TRUE)
  selected <- ids %in% keys
  if (anyDuplicated(ids[selected])) cli::cli_abort("Duplicate boundary keys; supply one polygon or multipolygon row per area.")
  absent <- setdiff(keys, ids)
  if (length(absent)) .dsi_map_structure_abort("Boundary geometry is missing.", absent,
    "No matching boundary key.", source, "missing_feature")
  out <- boundaries[match(keys, ids), , drop = FALSE]
  if (is.na(sf::st_crs(out))) .dsi_map_structure_abort("Boundary coordinate reference system is missing; verify it before mapping.", keys, "Missing coordinate reference system.", source)
  empty <- sf::st_is_empty(out)
  if (any(empty)) {
    message <- if (identical(source$stage, "download")) {
      "Empty boundary geometry in the WHO ADM0 response. Obtain a corrected WHO boundary or supply complete sf boundaries."
    } else "Empty boundary geometry. Supply complete sf boundaries for the requested areas."
    .dsi_map_structure_abort(message, keys[empty], "Empty geometry.", source, "empty_geometry")
  }
  type <- as.character(sf::st_geometry_type(out))
  wrong <- !type %in% c("POLYGON", "MULTIPOLYGON")
  if (any(wrong)) {
    .dsi_map_structure_abort("Map boundaries must be polygons or multipolygons.", keys[wrong], paste("Unsupported geometry type:", type[wrong]), source)
  }
  validation <- .dsi_map_validation(out, keys, source)
  if (any(!validation$checks$valid)) {
    validation$issue <- "invalid_geometry"
    message <- if (identical(source$stage, "download")) {
      "Invalid boundary geometry in the WHO ADM0 response. Obtain a corrected WHO boundary or supply complete, validated sf boundaries."
    } else "Invalid boundary geometry. Supply complete, validated sf boundaries for the requested areas."
    .dsi_map_boundary_abort(message, validation)
  }
  attr(out, "dsir_boundary_validation") <- validation
  out
}
