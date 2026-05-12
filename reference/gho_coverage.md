# Summarise Per-Location Data Coverage of a GHO Indicator

Fetches only the `SpatialDim` and `TimeDim` columns for a GHO indicator
(much lighter than
[`gho_data()`](https://shanlong-who.github.io/DSIR/reference/gho_data.md))
and summarises the year range and observation count per location. Useful
for answering "which countries have data, and for what years?" before
committing to a full download.

## Usage

``` r
gho_coverage(
  indicator,
  spatial_type = "country",
  area = NULL,
  year_from = NULL,
  year_to = NULL
)
```

## Arguments

- indicator:

  Character scalar. The indicator code (e.g. `"WHOSIS_000001"`).

- spatial_type:

  Character. Spatial dimension to filter on: one of `"country"`,
  `"region"`, `"global"`. Defaults to `"country"` since per-country
  coverage is the typical use case. Pass `NULL` for all spatial levels.

- area:

  Character vector of country or region codes (e.g. `c("FRA", "DEU")`).
  Default `NULL` returns all areas for the chosen `spatial_type`.

- year_from:

  Numeric. Start year filter (inclusive). Default `NULL`.

- year_to:

  Numeric. End year filter (inclusive). Default `NULL`.

## Value

A [tibble](https://tibble.tidyverse.org/reference/tibble.html) with one
row per location and columns:

- `location` (chr) — the `SpatialDim` value (typically ISO3).

- `year_min` (int) — earliest year with data.

- `year_max` (int) — latest year with data.

- `n_obs` (int) — number of observations.

  Sorted by `location`. Empty input or service failure returns an empty
  tibble with the same four columns.

## See also

[`gho_data()`](https://shanlong-who.github.io/DSIR/reference/gho_data.md),
[`gho_has_data()`](https://shanlong-who.github.io/DSIR/reference/gho_has_data.md),
[`gho_count()`](https://shanlong-who.github.io/DSIR/reference/gho_count.md).

## Examples

``` r
if (FALSE) { # \dontrun{
# Year coverage of life expectancy for three countries
gho_coverage("WHOSIS_000001", area = c("FRA", "DEU", "JPN"))

# All countries with any life-expectancy data, since 2010
gho_coverage("WHOSIS_000001", year_from = 2010)
} # }
```
