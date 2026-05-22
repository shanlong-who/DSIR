# Explore Series Coverage of an SDG Indicator

A single SDG indicator (for example `"3.4.1"`, NCD mortality) is
typically published as several **series** stratified by sex, age, or
cause. Different series may have different country and year coverage.
`sdg_coverage()` summarises year range and observation count per
`(location, series)` combination, so you can see which series exist for
an indicator and how each one is covered before committing to a
downstream analysis.

## Usage

``` r
sdg_coverage(indicator, area = NULL, year_from = NULL, year_to = NULL)
```

## Arguments

- indicator:

  Character vector of SDG indicator codes (e.g. `"3.4.1"`).

- area:

  Character vector of country/area codes. Accepts either ISO3 codes
  (e.g. `c("PHL", "FRA")`) — converted automatically via
  [`iso3_to_m49()`](https://shanlong-who.github.io/DSIR/reference/iso3_to_m49.md)
  — or UN M49 numeric codes (e.g. `c("608", "250")`) as returned by
  [`sdg_areas()`](https://shanlong-who.github.io/DSIR/reference/sdg_areas.md).
  Do not mix the two formats in a single call. Default `NULL` returns
  all areas. Unknown ISO3 codes are dropped with a warning before the
  network call.

- year_from:

  Numeric. Start year filter (inclusive). Default `NULL`.

- year_to:

  Numeric. End year filter (inclusive). Default `NULL`.

## Value

A [tibble](https://tibble.tidyverse.org/reference/tibble.html) with one
row per `(location, series)` and columns:

- `location` (chr) — area code (`geoAreaCode`).

- `series` (chr) — SDG series code.

- `year_min` (int) — earliest year with data.

- `year_max` (int) — latest year with data.

- `n_obs` (int) — number of observations.

  Sorted by `location` then `series`. Empty input or service failure
  returns an empty tibble with the same five columns.

## Details

Unlike the GHO availability helpers, this function is a
series-exploration tool rather than a payload-saving precheck: SDG data
is generally complete enough that GHO-style `has_data()` /
[`count()`](https://dplyr.tidyverse.org/reference/count.html) helpers
add little value, so they are intentionally not provided. The SDG API
also offers no payload-reduction option (no `$select` equivalent), so
`sdg_coverage()` calls
[`sdg_data()`](https://shanlong-who.github.io/DSIR/reference/sdg_data.md)
internally and aggregates the result client-side.

## See also

[`sdg_data()`](https://shanlong-who.github.io/DSIR/reference/sdg_data.md),
[`sdg_indicators()`](https://shanlong-who.github.io/DSIR/reference/sdg_indicators.md),
[`gho_coverage()`](https://shanlong-who.github.io/DSIR/reference/gho_coverage.md).

## Examples

``` r
# \donttest{
# Series available for NCD mortality in China and Brazil
sdg_coverage("3.4.1", area = c("156", "076"))
#> Fetching:
#> <https://unstats.un.org/sdgs/UNSDGAPIV5/v1/sdg/Indicator/Data?indicator=3.4.1&pageSize=1000&areaCode=156&areaCode=076&page=1>
#> # A tibble: 0 × 5
#> # ℹ 5 variables: location <chr>, series <chr>, year_min <int>, year_max <int>,
#> #   n_obs <int>

# Filter to a year range
sdg_coverage("3.4.1", area = "156", year_from = 2015)
#> Fetching:
#> <https://unstats.un.org/sdgs/UNSDGAPIV5/v1/sdg/Indicator/Data?indicator=3.4.1&pageSize=1000&areaCode=156&page=1>
#> # A tibble: 1 × 5
#>   location series      year_min year_max n_obs
#>   <chr>    <chr>          <int>    <int> <int>
#> 1 156      SH_DTH_NCOM     2015     2021    12
# }
```
