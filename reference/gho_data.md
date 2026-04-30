# Fetch GHO Data

Retrieves observations for a specific indicator from the WHO GHO OData
API, with optional filters by spatial level, country / region and year
range.

## Usage

``` r
gho_data(
  indicator,
  spatial_type = NULL,
  area = NULL,
  year_from = NULL,
  year_to = NULL
)
```

## Arguments

- indicator:

  Character scalar. The indicator code (e.g. `"NCDMORT3070"`). Use
  [`gho_indicators()`](https://shanlong-who.github.io/DSIR/reference/gho_indicators.md)
  to find codes.

- spatial_type:

  Character. Spatial dimension to filter on: one of `"country"`,
  `"region"`, `"global"`, or `NULL` (all levels, the default).

- area:

  Character vector of country or region codes (e.g. `c("FRA", "DEU")`).
  Default `NULL` returns all areas.

- year_from:

  Numeric. Start year filter (inclusive). Default `NULL`.

- year_to:

  Numeric. End year filter (inclusive). Default `NULL`.

## Value

A [tibble](https://tibble.tidyverse.org/reference/tibble.html) of
indicator observations, or an empty tibble when the service is
unreachable.

## See also

[`gho_indicators()`](https://shanlong-who.github.io/DSIR/reference/gho_indicators.md),
[`gho_dimensions()`](https://shanlong-who.github.io/DSIR/reference/gho_dimensions.md).

## Examples

``` r
if (FALSE) { # \dontrun{
# Country-level data for one indicator
gho_data("NCDMORT3070", spatial_type = "country")

# Specific countries and years
gho_data("WHOSIS_000001", area = c("FRA", "DEU"), year_from = 2015)
} # }
```
