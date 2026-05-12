# Fetch SDG Data

Retrieves data for one or more SDG indicators from the UN SDG API, with
optional filters by area and year.

## Usage

``` r
sdg_data(
  indicator,
  area = NULL,
  year_from = NULL,
  year_to = NULL,
  page_size = 1000L
)
```

## Arguments

- indicator:

  Character vector of indicator codes (e.g. `"1.1.1"`). Use
  [`sdg_indicators()`](https://shanlong-who.github.io/DSIR/reference/sdg_indicators.md)
  to find codes.

- area:

  Character vector of country/area codes. Accepts either ISO3 codes
  (e.g. `c("PHL", "FRA")`) — converted automatically via
  [`iso3_to_m49()`](https://shanlong-who.github.io/DSIR/reference/iso3_to_m49.md)
  — or UN M49 numeric codes (e.g. `c("608", "250")`) as returned by
  [`sdg_areas()`](https://shanlong-who.github.io/DSIR/reference/sdg_areas.md).
  Do not mix the two formats in a single call. Default `NULL` returns
  all areas.

- year_from:

  Numeric. Start year filter (inclusive). Default `NULL`.

- year_to:

  Numeric. End year filter (inclusive). Default `NULL`.

- page_size:

  Integer. Number of records per page. Default `1000`, maximum `10000`.

## Value

A [tibble](https://tibble.tidyverse.org/reference/tibble.html) of
indicator observations, or an empty tibble when the service is
unreachable or there are no matching rows.

## See also

[`sdg_indicators()`](https://shanlong-who.github.io/DSIR/reference/sdg_indicators.md),
[`sdg_areas()`](https://shanlong-who.github.io/DSIR/reference/sdg_areas.md),
[`iso3_to_m49()`](https://shanlong-who.github.io/DSIR/reference/iso3_to_m49.md).

## Examples

``` r
if (FALSE) { # \dontrun{
# All data for indicator 1.1.1
sdg_data("1.1.1")

# Specific area and year range
sdg_data("3.2.1", area = "156", year_from = 2015, year_to = 2023)

# ISO3 codes work directly — DSIR's regional vectors can be passed in
sdg_data("3.4.1", area = wpro_cty)
sdg_data("3.4.1", area = c("PHL", "FRA", "JPN"))
} # }
```
