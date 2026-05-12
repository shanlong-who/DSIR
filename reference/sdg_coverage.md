# Summarise Series-Level Coverage of an SDG Indicator

Fetches an SDG indicator via
[`sdg_data()`](https://shanlong-who.github.io/DSIR/reference/sdg_data.md)
and summarises how each constituent **series** is covered, by location
and year. SDG indicators are typically published as several series
stratified by sex, age, cause, vaccine, or similar — for example,
indicator `"3.b.1"` (vaccine coverage) is split into `SH_ACS_DTP3`,
`SH_ACS_MCV2`, `SH_ACS_PCV3`, and `SH_ACS_HPV`. Each series can have its
own country / year coverage; `sdg_coverage()` makes those differences
visible before committing to an analysis.

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

sdg_coverage(indicator, area = NULL, year_from = NULL, year_to = NULL)
```

## Arguments

- indicator:

  Character vector of SDG indicator codes (e.g. `"3.4.1"`).

- area:

  Character vector of area codes (e.g. `c("156", "608")`). Default
  `NULL` returns all areas.

- year_from:

  Numeric. Start year filter (inclusive). Default `NULL`.

- year_to:

  Numeric. End year filter (inclusive). Default `NULL`.

## Value

A [tibble](https://tibble.tidyverse.org/reference/tibble.html) with one
row per `(location, series)` combination and columns:

- `location` (chr) — the `geoAreaCode` value (M49 numeric, as a string).

- `series` (chr) — the SDG series code (e.g. `"SH_ACS_DTP3"`).

- `year_min` (int) — earliest year with data.

- `year_max` (int) — latest year with data.

- `n_obs` (int) — number of observations.

  Sorted by `location`, then `series`. Empty input or service failure
  returns an empty tibble with the same five columns and the same column
  types.

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

This is a *series-exploration* helper, not an availability precheck. SDG
data is generally complete enough that GHO-style
[`gho_has_data()`](https://shanlong-who.github.io/DSIR/reference/gho_has_data.md)
/
[`gho_count()`](https://shanlong-who.github.io/DSIR/reference/gho_count.md)
analogues add little value, and are intentionally not provided. The more
useful pre-analysis question for SDG is "which series exist, and how is
each covered?", which is what this function answers.

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

[`sdg_data()`](https://shanlong-who.github.io/DSIR/reference/sdg_data.md),
[`sdg_indicators()`](https://shanlong-who.github.io/DSIR/reference/sdg_indicators.md).

## Examples

``` r
if (FALSE) { # \dontrun{
# Vaccine coverage in China and Brazil — four series per country
sdg_coverage("3.b.1", area = c("156", "76"))

# NCD mortality in WPR since 2010
sdg_coverage("3.4.1", area = wpro_cty, year_from = 2010)
} # }
if (FALSE) { # \dontrun{
# Series available for NCD mortality in China and Brazil
sdg_coverage("3.4.1", area = c("156", "076"))

# Filter to a year range
sdg_coverage("3.4.1", area = "156", year_from = 2015)
} # }
```
