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

  Character vector of area codes (e.g. `c("32", "76")`). Use
  [`sdg_areas()`](https://shanlong-who.github.io/DSIR/reference/sdg_areas.md)
  to find codes. Default `NULL` returns all areas.

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
[`sdg_areas()`](https://shanlong-who.github.io/DSIR/reference/sdg_areas.md).

## Examples

``` r
if (FALSE) { # \dontrun{
# All data for indicator 1.1.1
sdg_data("1.1.1")

# Specific area and year range
sdg_data("3.2.1", area = "156", year_from = 2015, year_to = 2023)
} # }
```
