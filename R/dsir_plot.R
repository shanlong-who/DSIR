#' Plot a Cleaned DSIR Indicator
#'
#' Draw an annual trend or a same-year country comparison from a
#' [dsir_data][as_dsir_data] object. All checks and plotting are offline.
#'
#' @param x A `dsir_data` object, normally returned by [gho_clean()],
#'   [sdg_clean()] or [ghe_clean()].
#' @param y Unused; must be `NULL`.
#' @param ... Reserved; must be empty. Customize the returned ggplot with `+`.
#' @param type Required: `"trend"` for points and annual line segments, or
#'   `"compare"` for horizontal country points at one common year.
#' @param country Optional character vector of ISO3 codes present in `x`.
#'   This first version supports countries, not regional aggregates.
#' @param year Optional integer-valued year vector. For comparisons, exactly
#'   one year must be selected or already present in `x`.
#' @param group Optional column name for colour groups, such as `"dim1"`
#'   or `"dim_sex"`. Trends with multiple countries default to `"iso3"`.
#' @param facet Optional column name for panels, such as `"iso3"` or
#'   `"dim_age"`. Other population dimensions must be constant.
#' @param interval Logical. Show reported `low` and `high` bounds as ranges?
#'   Default `FALSE`. No intervals are calculated, and no confidence level
#'   is assumed. Incomplete bounds are omitted with a warning; invalid bounds
#'   cause an error.
#'
#' @return A standard ggplot object using [theme_dsi()] or [theme_dsi_facet()].
#'   No aggregation, unit conversion, interpolation or data retrieval occurs.
#' @details
#' Select one source, backend, indicator, series/measure and unit before
#' plotting. Use normal row filtering to select other dimensions. Unmapped
#' population dimensions must be constant even when there is only one row
#' per country/year. Recorded aliases, such as GHE `dim1` and `dim_sex`, may
#' represent the same dimension. Every country/year/group/panel position
#' must be unique; duplicate observations cause an error.
#'
#' Cleaning metadata retains constant context without adding table columns.
#' If varying dimensions or units were omitted, clean the original data again
#' with `keep_dimensions = TRUE` and, for GHO/SDG, `keep_metadata = TRUE`.
#' Filtering the compact table cannot recover the missing row identities.
#' Unknown units are labelled explicitly. Metadata is evidence about the
#' supplied data, not a certification of comparability or completeness.
#'
#' Changes to plot-relevant fields marked `needs_review` prevent automatic
#' plotting. Unrelated added flags or notes do not. Review derived measures
#' and use explicit ggplot mappings for analyses outside this contract.
#' Missing/non-finite estimates are omitted with a warning. Trends break
#' across missing estimates and gaps greater than one year, without filling
#' missing years. Known non-annual or truncated time periods are rejected.
#' @export
#' @examples
#' raw <- tibble::tibble(
#'   IndicatorCode = "EXAMPLE", IndicatorName = "Illustrative indicator",
#'   SpatialDim = rep(c("PHL", "LAO"), each = 3),
#'   TimeDim = rep(2021:2023, 2), NumericValue = c(12, 11, 10, 15, 14, 13),
#'   Unit = "percent", Dim1 = "SEX_BTSX", Dim1Type = "SEX"
#' )
#' data.clean <- gho_clean(raw)
#' plot(data.clean, type = "trend")
#' plot(data.clean, type = "compare", year = 2023)
plot.dsir_data <- function(x, y = NULL, ..., type = c("trend", "compare"),
                           country = NULL, year = NULL, group = NULL,
                           facet = NULL, interval = FALSE) {
  rlang::check_dots_empty()
  if (!is.null(y)) cli::cli_abort("{.arg y} is not used; customize the returned ggplot instead.")
  if (missing(type)) cli::cli_abort('Specify {.code type = "trend"} or {.code type = "compare"}.')
  type <- match.arg(type)
  .dsi_check_flag(interval, "interval")
  metadata <- dsir_metadata(x)
  problem <- .dsi_data_problem(x)
  if (!is.null(problem)) cli::cli_abort("{problem}")
  data <- .dsi_data_plain(x)
  if (!is.null(country)) {
    if (!is.character(country) || !length(country) || anyNA(country) || any(!nzchar(country))) {
      cli::cli_abort("{.arg country} must be a non-empty character vector of ISO3 codes.")
    }
    absent <- setdiff(country, data$iso3)
    if (length(absent)) cli::cli_abort("Country codes absent from {.arg x}: {.val {absent}}.")
    data <- data[data$iso3 %in% country, , drop = FALSE]
  }
  if (!is.null(year)) {
    if (!is.numeric(year) || !length(year) || anyNA(year) ||
        any(!is.finite(year) | year != trunc(year))) {
      cli::cli_abort("{.arg year} must contain finite integer-valued years.")
    }
    absent <- setdiff(year, data$year)
    if (length(absent)) cli::cli_abort("Years absent from the selected data: {.val {absent}}.")
    data <- data[data$year %in% year, , drop = FALSE]
  }
  if (!nrow(data)) cli::cli_abort("No observations remain to plot.")
  if (anyNA(data$iso3) || any(!nzchar(data$iso3))) {
    cli::cli_abort("Select country observations with recorded ISO3 codes before plotting.")
  }
  if (anyNA(data$year)) cli::cli_abort("Missing years cannot be plotted; inspect or filter these rows.")
  if (type == "compare" && length(unique(data$year)) != 1L) {
    cli::cli_abort("Comparisons require one common year; supply {.arg year} or filter first.")
  }
  if (is.null(group) && type == "trend" && length(unique(data$iso3)) > 1L) group <- "iso3"
  for (arg in c("group", "facet")) {
    field <- if (arg == "group") group else facet
    if (is.null(field)) next
    if (!is.character(field) || length(field) != 1L || is.na(field) || !field %in% names(data)) {
      cli::cli_abort("{.arg {arg}} must name one column in {.arg x}.")
    }
    if (!is.atomic(data[[field]]) || !is.null(dim(data[[field]])) ||
        anyNA(data[[field]]) || any(!nzchar(as.character(data[[field]])))) {
      cli::cli_abort("The {.field {field}} mapping must contain non-missing scalar values.")
    }
  }
  context <- .dsi_plot_context(data, metadata, c(group, facet), interval)
  keys <- unique(c("iso3", "year", group, facet))
  if (anyDuplicated(data[keys])) {
    cli::cli_abort(c("Duplicate observations occupy the same plot position.",
      "i" = "Filter additional dimensions or map them with {.arg group}/{.arg facet}; observations are never aggregated."))
  }
  if (type == "trend" && length(unique(data$iso3)) > 1L &&
      !any(c(group, facet) %in% c("iso3", "location", "location_name"))) {
    cli::cli_abort("Multiple countries need a country {.arg group} or {.arg facet} in a trend.")
  }
  data$.dsir_group <- if (is.null(group)) factor("Observations") else factor(data[[group]])
  data$.dsir_panel <- if (is.null(facet)) factor("Observations") else factor(data[[facet]])
  data$.dsir_line <- vctrs::vec_group_id(data[c("iso3", ".dsir_group", ".dsir_panel")])
  data <- data[order(data$.dsir_line, data$year), , drop = FALSE]
  finite <- is.finite(data$value_num)
  if (any(!finite)) cli::cli_warn("Omitting {sum(!finite)} missing or non-finite estimate{?s}; trend lines break at these rows.")
  if (!any(finite)) cli::cli_abort("No finite estimates remain to plot.")
  bounds <- rep(FALSE, nrow(data))
  if (interval) {
    bounds <- finite & !is.na(data$low) & !is.na(data$high)
    invalid <- (finite & ((!is.na(data$low) & !is.finite(data$low)) |
                          (!is.na(data$high) & !is.finite(data$high)))) |
      (bounds & (data$low > data$high | data$value_num < data$low | data$value_num > data$high))
    if (any(invalid)) cli::cli_abort("Reported bounds must be finite and satisfy low <= value_num <= high.")
    if (!any(bounds)) cli::cli_abort("No complete reported intervals are available.")
    if (any(finite & !bounds)) cli::cli_warn("Omitting {sum(finite & !bounds)} incomplete reported interval{?s}; estimates are retained.")
  }
  # Separate runs of consecutive years; missing estimates also break runs.
  n <- nrow(data)
  starts <- c(TRUE, data$.dsir_line[-1L] != data$.dsir_line[-n] |
    diff(data$year) != 1 | !finite[-1L] | !finite[-n])
  data$.dsir_segment <- cumsum(starts)
  countries <- sort(unique(data$iso3))
  labels <- data$location_name[match(countries, data$iso3)]
  labels[is.na(labels) | !nzchar(labels)] <- countries[is.na(labels) | !nzchar(labels)]
  labels <- stats::setNames(paste0(labels, " (", countries, ")"), countries)
  data$.dsir_country <- factor(data$iso3, levels = rev(countries[order(labels)]))
  groups <- nlevels(data$.dsir_group)
  data$.dsir_position <- as.integer(data$.dsir_country) +
    (as.integer(data$.dsir_group) - (groups + 1) / 2) * 0.6 / groups
  points <- data[finite, , drop = FALSE]
  ranges <- data[bounds, , drop = FALSE]
  if (type == "trend") {
    p <- ggplot2::ggplot(points, ggplot2::aes(x = .data$year, y = .data$value_num,
      colour = .data$.dsir_group, group = .data$.dsir_segment))
    sizes <- table(points$.dsir_segment)
    lines <- points[as.character(points$.dsir_segment) %in% names(sizes)[sizes > 1L], , drop = FALSE]
    if (nrow(lines)) p <- p + ggplot2::geom_line(data = lines, linewidth = 0.6)
    if (interval) p <- p + ggplot2::geom_linerange(data = ranges,
      ggplot2::aes(ymin = .data$low, ymax = .data$high), linewidth = 0.4)
    p <- p + ggplot2::geom_point(size = 2) + ggplot2::labs(x = "Year", y = context$unit)
  } else {
    p <- ggplot2::ggplot(points, ggplot2::aes(x = .data$.dsir_position, y = .data$value_num,
      colour = .data$.dsir_group, group = .data$.dsir_group))
    if (interval) p <- p + ggplot2::geom_linerange(data = ranges,
      ggplot2::aes(ymin = .data$low, ymax = .data$high), linewidth = 0.4)
    p <- p + ggplot2::geom_point(size = 2.5) +
      ggplot2::scale_x_continuous(breaks = seq_along(levels(data$.dsir_country)),
        labels = unname(labels[levels(data$.dsir_country)])) + ggplot2::coord_flip() +
      ggplot2::labs(x = NULL, y = context$unit)
  }
  if (!is.null(facet)) p <- p + ggplot2::facet_wrap(ggplot2::vars(.data$.dsir_panel))
  theme <- if (is.null(facet)) theme_dsi() else theme_dsi_facet()
  subtitle <- c(if (type == "compare") paste("Year:", unique(data$year)), context$strata)
  p <- p + theme + ggplot2::scale_colour_viridis_d(end = 0.8) +
    ggplot2::labs(title = context$title, subtitle = paste(subtitle, collapse = " | "),
                  colour = group, caption = context$caption)
  if (is.null(group)) p <- p + ggplot2::guides(colour = "none")
  p
}

.dsi_plot_context <- function(data, metadata, mapped, interval) {
  profile <- metadata$cleaning$fields
  if (is.null(profile)) profile <- tibble::tibble(column = character(),
    retained_as = character(), distinct = integer(), constant = character())
  lost <- profile$column[is.na(profile$retained_as) & profile$distinct > 1L]
  if (length(lost)) cli::cli_abort(c(
    "Varying context was omitted during cleaning: {.val {lost}}.",
    "i" = "Reclean the original data with {.code keep_dimensions = TRUE} and, for GHO/SDG, {.code keep_metadata = TRUE}."))
  if (isTRUE(metadata$cleaning$year_precision_lost > 0L)) {
    cli::cli_abort("Cleaning lost time precision; annual plots cannot represent these periods.")
  }
  context <- as.list(data)
  for (i in seq_len(nrow(profile))) {
    field <- profile$column[[i]]
    if (!field %in% names(context)) context[[field]] <- profile$constant[[i]]
  }
  relevant <- names(context)[.dsi_data_roles(names(context)) != "metadata"]
  relevant <- union(relevant, c("indicator", "location_name", mapped))
  if (!interval) relevant <- setdiff(relevant, c("low", "high"))
  review <- intersect(metadata$processing$review_columns, relevant)
  if (length(review)) cli::cli_abort(c("Plot metadata needs review for {.val {review}}.",
    "i" = "Review derived measures and use explicit ggplot mappings, or return to the original cleaned data."))
  normalize <- function(x) {
    x <- as.character(x)
    x[!is.na(x) & !nzchar(trimws(x))] <- NA_character_
    unique(x)
  }
  values <- lapply(context, normalize)
  identity <- intersect(c("source", "id", "series", "provider", "measure_field", "indicator"), names(values))
  mixed <- identity[lengths(values[identity]) > 1L]
  if (length(mixed)) cli::cli_abort("Select one indicator, series/measure and origin; mixed {.val {mixed}}.")
  if (length(values$id) != 1L || is.na(values$id)) cli::cli_abort("A single recorded indicator code is required.")
  backend <- if (length(values$provider) && !all(is.na(values$provider))) values$provider else
    unique(c(metadata$sources$backend, metadata$provenance$retrieval$backend))
  if (length(backend) > 1L) cli::cli_abort("Multiple recorded backends cannot be combined automatically.")
  measures <- names(values)[.dsi_data_roles(names(values)) == "measure"]
  mixed <- measures[lengths(values[measures]) > 1L]
  if (length(mixed)) cli::cli_abort("Select a single unit and measurement basis; mixed {.val {mixed}}.")
  units <- unique(stats::na.omit(unlist(values[intersect(c("unit", "attr_units"), names(values))], use.names = FALSE)))
  if (length(units) > 1L) cli::cli_abort("Conflicting unit fields; verify units before plotting.")
  if (length(values$time_type) && any(!is.na(values$time_type) & !values$time_type %in% c("YEAR", "Year", "year"))) {
    cli::cli_abort("Only annual observations are supported; inspect {.field time_type}.")
  }
  aliases <- metadata$cleaning$aliases
  mapped <- union(mapped, unname(aliases[names(aliases) %in% mapped]))
  mapped <- union(mapped, names(aliases)[aliases %in% mapped])
  dimensions <- names(values)[.dsi_data_roles(names(values)) == "dimension"]
  dimensions <- setdiff(dimensions, c("location", "iso3", "location_name", "year", mapped))
  varying <- dimensions[lengths(values[dimensions]) > 1L]
  if (length(varying)) cli::cli_abort(c("Unresolved population or time dimensions: {.val {varying}}.",
    "i" = "Filter to comparable strata or name the dimension in {.arg group}/{.arg facet}."))
  fixed <- dimensions[vapply(values[dimensions], function(x) length(x) == 1L && !is.na(x), logical(1))]
  fixed <- setdiff(fixed, c("time_type", "spatial_type", grep("_type$", fixed, value = TRUE), names(aliases)))
  basis <- setdiff(measures, c("unit", "attr_units", "measure_field"))
  basis <- basis[vapply(values[basis], function(x) length(x) == 1L && !is.na(x), logical(1))]
  fixed <- union(fixed, basis)
  strata <- vapply(fixed, function(field) paste0(field, ": ", values[[field]]), character(1))
  retrieval <- unique(metadata$sources$retrieved_at %||% metadata$provenance$retrieval$retrieved)
  retrieval <- retrieval[!is.na(retrieval)]
  caption <- c(paste("Source:", paste(values$source, collapse = ", ")),
    if (length(backend)) paste("Backend:", paste(backend, collapse = ", ")),
    if (length(retrieval)) paste("Retrieved:", paste(retrieval, collapse = ", ")))
  title <- values$indicator
  if (!length(title) || is.na(title)) title <- values$id
  list(title = title, unit = if (length(units)) units else "Value (unit not recorded)",
       strata = strata, caption = paste(caption, collapse = " | "))
}
