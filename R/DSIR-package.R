#' DSIR: Data Science Infrastructure for Global Health in R
#'
#' A small, opinionated toolkit for global health data analysis.
#' It bundles a publication-ready `ggplot2` theme ([theme_dsi()],
#' [theme_dsi_facet()]) with flush-axis bar-chart scales
#' ([scale_y_dsi_col()], [scale_x_dsi_col()]),
#' sensible `flextable` defaults ([dsi_flextable_defaults()]),
#' a quick pie chart helper ([ggpie()]), regional country-code
#' datasets ([wpro_cty]) with WHO region and UN M49 lookups
#' ([iso3_to_region()], [iso3_to_m49()], [m49_to_iso3()]), a
#' geometric mean helper for indicator aggregation ([geomean()]),
#' thin clients for the WHO Global Health Observatory API
#' ([gho_indicators()], [gho_data()], [gho_dimensions()],
#' [gho_has_data()], [gho_count()], [gho_coverage()]) and the UN
#' Sustainable Development Goals API ([sdg_goals()], [sdg_targets()],
#' [sdg_indicators()], [sdg_areas()], [sdg_data()], [sdg_coverage()]),
#' plus a unified cleaning / binding pipeline ([gho_clean()],
#' [sdg_clean()], [bind_indicators()]) that puts GHO and SDG output
#' into the same 15-column schema.
#'
#' @keywords internal
"_PACKAGE"

## usethis namespace: start
#' @importFrom rlang .data %||%
#' @importFrom tibble as_tibble tibble
## usethis namespace: end
NULL

# Silence R CMD check NOTE for the lazy-loaded `who_countries` dataset
# referenced unqualified inside package functions (e.g. iso3_to_region()).
utils::globalVariables("who_countries")
