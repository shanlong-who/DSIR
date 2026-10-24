# Fetch SDG Data

Retrieves data for one or more SDG indicators from the UN SDG API, with
optional filters by area, year, series, and named dimensions.

## Usage

``` r
sdg_data(
  indicator,
  area = NULL,
  year_from = NULL,
  year_to = NULL,
  page_size = 1000L,
  series = NULL,
  dimensions = NULL
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

- series:

  Optional character vector of series codes to keep. Default `NULL`
  keeps all series. Applied client-side after all pages have been
  retrieved.

- dimensions:

  Optional named list of character vectors, using the exact names and
  codes in the returned `dimensions` column, for example
  `list(Sex = "BOTHSEX", Quantile = "_T")`. Values within a dimension
  are OR-ed; different dimensions are AND-ed. Matching is
  case-sensitive. Missing dimension values do not match. An absent
  requested dimension warns and returns no rows. Default `NULL` keeps
  all strata. Like year and series filters, these filters run
  client-side and do not reduce the number of downloaded pages.

## Value

A [tibble](https://tibble.tidyverse.org/reference/tibble.html) of
indicator observations, or an empty tibble when the service is
unreachable or there are no matching rows. The raw `dimensions` and
`attributes` columns retain the API's named breakdowns and attributes
(usually packed data-frame columns). Inspect `unique(df$dimensions)` to
discover observed strata. Use `sdg_clean(df, keep_dimensions = TRUE)` to
retain named dimensions as flat columns when cleaning. If reported page
numbers, page counts, or total row counts are inconsistent, warns and
returns no rows. Counts are checked before local filters. Counts omitted
by the API cannot be verified; a response without `totalPages` is
treated as one page.

## See also

[`sdg_indicators()`](https://shanlong-who.github.io/DSIR/reference/sdg_indicators.md),
[`sdg_areas()`](https://shanlong-who.github.io/DSIR/reference/sdg_areas.md),
[`sdg_clean()`](https://shanlong-who.github.io/DSIR/reference/sdg_clean.md),
[`sdg_dimensions()`](https://shanlong-who.github.io/DSIR/reference/sdg_dimensions.md),
[`iso3_to_m49()`](https://shanlong-who.github.io/DSIR/reference/iso3_to_m49.md).

## Examples

``` r
# \donttest{
# One indicator, one country — the typical entry point
sdg_data("1.1.1", area = "PHL")

# Specific area and year range (M49 code)
sdg_data("3.2.1", area = "156", year_from = 2015, year_to = 2023)

# ISO3 codes work directly — DSIR's regional vectors can be passed in
sdg_data("3.4.1", area = c("PHL", "FRA", "JPN"))
# }
```
