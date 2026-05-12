#' DSIR: Data Science Infrastructure for Global Health in R
#'
#' A small, opinionated toolkit for global health data analysis.
#' It bundles a publication-ready `ggplot2` theme ([theme_dsi()]),
#' sensible `flextable` defaults ([dsi_flextable_defaults()]),
#' a quick pie chart helper ([ggpie()]), regional country-code
#' datasets ([wpro_cty]) with a WHO region lookup
#' ([iso3_to_region()]), a geometric mean helper for indicator
#' aggregation ([geomean()]), and thin clients for the WHO Global
#' Health Observatory API ([gho_indicators()], [gho_data()],
#' [gho_dimensions()], [gho_has_data()], [gho_count()],
#' [gho_coverage()]) and the UN Sustainable Development Goals API
#' ([sdg_goals()], [sdg_targets()], [sdg_indicators()], [sdg_areas()],
#' [sdg_data()], [sdg_coverage()]).
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
