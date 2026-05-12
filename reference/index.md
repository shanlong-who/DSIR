# Package index

## WHO country metadata

Datasets and helpers for WHO Member States and regional groupings.

- [`who_countries`](https://shanlong-who.github.io/DSIR/reference/who_countries.md)
  : WHO Member States with regional and Pacific classifications
- [`afro_cty`](https://shanlong-who.github.io/DSIR/reference/who_region_vectors.md)
  [`amro_cty`](https://shanlong-who.github.io/DSIR/reference/who_region_vectors.md)
  [`searo_cty`](https://shanlong-who.github.io/DSIR/reference/who_region_vectors.md)
  [`euro_cty`](https://shanlong-who.github.io/DSIR/reference/who_region_vectors.md)
  [`emro_cty`](https://shanlong-who.github.io/DSIR/reference/who_region_vectors.md)
  [`wpro_cty`](https://shanlong-who.github.io/DSIR/reference/who_region_vectors.md)
  : WHO regional Member State ISO3 vectors
- [`pic_cty`](https://shanlong-who.github.io/DSIR/reference/pic_cty.md)
  : Pacific Island Country ISO3 codes
- [`iso3_to_region()`](https://shanlong-who.github.io/DSIR/reference/iso3_to_region.md)
  : Look Up the WHO Region for ISO3 Codes

## GHO indicator data

Functions for fetching and cleaning data from the WHO Global Health
Observatory.

- [`gho_indicators()`](https://shanlong-who.github.io/DSIR/reference/gho_indicators.md)
  : List GHO Indicators
- [`gho_dimensions()`](https://shanlong-who.github.io/DSIR/reference/gho_dimensions.md)
  : List Dimensions of a GHO Indicator
- [`gho_data()`](https://shanlong-who.github.io/DSIR/reference/gho_data.md)
  : Fetch GHO Data
- [`gho_clean()`](https://shanlong-who.github.io/DSIR/reference/gho_clean.md)
  : Tidy a GHO Data Frame
- [`gho_count()`](https://shanlong-who.github.io/DSIR/reference/gho_count.md)
  : Count Observations for a GHO Indicator Filter
- [`gho_coverage()`](https://shanlong-who.github.io/DSIR/reference/gho_coverage.md)
  : Summarise Per-Location Data Coverage of a GHO Indicator
- [`gho_has_data()`](https://shanlong-who.github.io/DSIR/reference/gho_has_data.md)
  : Check Whether a GHO Indicator Has Data for a Filter

## SDG indicator data

Functions for fetching and cleaning data from the UN SDG API.

- [`sdg_goals()`](https://shanlong-who.github.io/DSIR/reference/sdg_goals.md)
  : List SDG Goals
- [`sdg_targets()`](https://shanlong-who.github.io/DSIR/reference/sdg_targets.md)
  : List SDG Targets
- [`sdg_areas()`](https://shanlong-who.github.io/DSIR/reference/sdg_areas.md)
  : List SDG Geographic Areas
- [`sdg_indicators()`](https://shanlong-who.github.io/DSIR/reference/sdg_indicators.md)
  : List SDG Indicators
- [`sdg_data()`](https://shanlong-who.github.io/DSIR/reference/sdg_data.md)
  : Fetch SDG Data
- [`sdg_clean()`](https://shanlong-who.github.io/DSIR/reference/sdg_clean.md)
  : Tidy an SDG Data Frame

## Visual themes

ggplot2 and flextable styling helpers for WHO-style outputs.

- [`theme_dsi()`](https://shanlong-who.github.io/DSIR/reference/theme_dsi.md)
  : DSIR ggplot2 theme — WHO publication-style
- [`dsi_flextable_defaults()`](https://shanlong-who.github.io/DSIR/reference/dsi_flextable_defaults.md)
  : Set DSIR Flextable Defaults
- [`ggpie()`](https://shanlong-who.github.io/DSIR/reference/ggpie.md) :
  Create a Pie Chart with ggplot2

## Utilities

Small mathematical and data helpers.

- [`geomean()`](https://shanlong-who.github.io/DSIR/reference/geomean.md)
  : Geometric Mean
