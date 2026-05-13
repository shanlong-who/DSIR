# DSIR: Data Science Infrastructure for Global Health in R

A small, opinionated toolkit for global health data analysis. It bundles
a publication-ready `ggplot2` theme
([`theme_dsi()`](https://shanlong-who.github.io/DSIR/reference/theme_dsi.md),
[`theme_dsi_facet()`](https://shanlong-who.github.io/DSIR/reference/theme_dsi_facet.md))
with flush-axis bar-chart scales
([`scale_y_dsi_col()`](https://shanlong-who.github.io/DSIR/reference/scale_dsi_col.md),
[`scale_x_dsi_col()`](https://shanlong-who.github.io/DSIR/reference/scale_dsi_col.md)),
sensible `flextable` defaults
([`dsi_flextable_defaults()`](https://shanlong-who.github.io/DSIR/reference/dsi_flextable_defaults.md)),
a quick pie chart helper
([`ggpie()`](https://shanlong-who.github.io/DSIR/reference/ggpie.md)),
regional country-code datasets
([wpro_cty](https://shanlong-who.github.io/DSIR/reference/who_region_vectors.md))
with WHO region and UN M49 lookups
([`iso3_to_region()`](https://shanlong-who.github.io/DSIR/reference/iso3_to_region.md),
[`iso3_to_m49()`](https://shanlong-who.github.io/DSIR/reference/iso3_to_m49.md),
[`m49_to_iso3()`](https://shanlong-who.github.io/DSIR/reference/m49_to_iso3.md)),
a geometric mean helper for indicator aggregation
([`geomean()`](https://shanlong-who.github.io/DSIR/reference/geomean.md)),
thin clients for the WHO Global Health Observatory API
([`gho_indicators()`](https://shanlong-who.github.io/DSIR/reference/gho_indicators.md),
[`gho_data()`](https://shanlong-who.github.io/DSIR/reference/gho_data.md),
[`gho_dimensions()`](https://shanlong-who.github.io/DSIR/reference/gho_dimensions.md),
[`gho_has_data()`](https://shanlong-who.github.io/DSIR/reference/gho_has_data.md),
[`gho_count()`](https://shanlong-who.github.io/DSIR/reference/gho_count.md),
[`gho_coverage()`](https://shanlong-who.github.io/DSIR/reference/gho_coverage.md))
and the UN Sustainable Development Goals API
([`sdg_goals()`](https://shanlong-who.github.io/DSIR/reference/sdg_goals.md),
[`sdg_targets()`](https://shanlong-who.github.io/DSIR/reference/sdg_targets.md),
[`sdg_indicators()`](https://shanlong-who.github.io/DSIR/reference/sdg_indicators.md),
[`sdg_areas()`](https://shanlong-who.github.io/DSIR/reference/sdg_areas.md),
[`sdg_data()`](https://shanlong-who.github.io/DSIR/reference/sdg_data.md),
[`sdg_coverage()`](https://shanlong-who.github.io/DSIR/reference/sdg_coverage.md)),
plus a unified cleaning / binding pipeline
([`gho_clean()`](https://shanlong-who.github.io/DSIR/reference/gho_clean.md),
[`sdg_clean()`](https://shanlong-who.github.io/DSIR/reference/sdg_clean.md),
[`bind_indicators()`](https://shanlong-who.github.io/DSIR/reference/bind_indicators.md))
that puts GHO and SDG output into the same 15-column schema.

## See also

Useful links:

- <https://github.com/shanlong-who/DSIR>

- <https://shanlong-who.github.io/DSIR/>

- Report bugs at <https://github.com/shanlong-who/DSIR/issues>

## Author

**Maintainer**: Shanlong Ding <dings@who.int>
([ORCID](https://orcid.org/0000-0002-8831-1684))

Authors:

- Shanlong Ding <dings@who.int>
  ([ORCID](https://orcid.org/0000-0002-8831-1684))
