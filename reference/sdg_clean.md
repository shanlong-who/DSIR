# Tidy an SDG Data Frame

Selects, renames, and type-casts the most useful columns from an SDG
observation table returned by
[`sdg_data()`](https://shanlong-who.github.io/DSIR/reference/sdg_data.md),
producing a compact tibble in the **unified DSIR cleaned-indicator
schema** — the same schema produced by
[`gho_clean()`](https://shanlong-who.github.io/DSIR/reference/gho_clean.md),
so the two outputs can be combined directly with
[`bind_indicators()`](https://shanlong-who.github.io/DSIR/reference/bind_indicators.md).

## Usage

``` r
sdg_clean(df, keep_dimensions = FALSE, keep_metadata = FALSE)
```

## Arguments

- df:

  A data frame returned by
  [`sdg_data()`](https://shanlong-who.github.io/DSIR/reference/sdg_data.md).

- keep_dimensions:

  Logical. Append the named SDG dimensions as character columns? Default
  `FALSE` preserves the 15-column format. With `TRUE`, names are
  converted to snake_case and prefixed with `dim_`, e.g. `Age` becomes
  `dim_age`, `Reporting Type` becomes `dim_reporting_type`, and
  `Type_of_household` becomes `dim_type_of_household`. Codes are kept
  unchanged; absent values remain `NA`. Conflicting names after
  conversion cause an error. No dimensions, total-population codes, or
  GHO component codes are inferred. Use
  [`sdg_dimensions()`](https://shanlong-who.github.io/DSIR/reference/sdg_dimensions.md)
  to look up official codes and labels.

- keep_metadata:

  Logical. Retain observation attributes and source context? Default
  `FALSE`. With `TRUE`, all returned attributes become character columns
  prefixed with `attr_` (e.g. `attr_units`, `attr_nature`). Also appends
  `data_source`, `time_detail`, `time_coverage`, `base_period`,
  `value_type`, and `geo_info_url` as character columns. `footnotes`,
  `indicator_codes`, `goal_codes`, and `target_codes` are list-columns
  of character vectors, preserving all entries rather than just the
  first. Missing scalar fields are `NA`; missing list fields are empty
  character vectors. This option is independent of `keep_dimensions` and
  makes no extra network requests.

## Value

A [tibble](https://tibble.tidyverse.org/reference/tibble.html) with 15
core columns: `source` (always `"sdg"`), `id`, `indicator`, `location`,
`iso3`, `location_name`, `year`, `value`, `value_num`, `low`, `high`,
`series`, `dim1` (`NA`), `dim2` (`NA`), `dim3` (`NA`). Sorted by
`location` then `year`. Empty input returns an empty tibble with the
same columns and types. With `keep_dimensions = TRUE`, available named
dimensions follow the core columns, including on zero-row subsets of raw
data. With `keep_metadata = TRUE`, source context follows those columns.

## Details

The mapping (SDG source → unified column) is:

- `indicator` (list-column, flattened) → `id` (e.g. `"3.4.1"`)

- `seriesDescription` → `indicator` (human-readable label; `NA` if the
  API response does not include it)

- `geoAreaCode` → `location` (UN M49 numeric, as character); also `iso3`
  via
  [`m49_to_iso3()`](https://shanlong-who.github.io/DSIR/reference/m49_to_iso3.md)
  for WHO Member States — region / world aggregates and non-Member areas
  get `iso3 = NA`

- `location_name` is resolved by looking up `iso3` against
  [`who_countries`](https://shanlong-who.github.io/DSIR/reference/who_countries.md)
  (so a WHO Member State has the same `location_name` here and in
  [`gho_clean()`](https://shanlong-who.github.io/DSIR/reference/gho_clean.md)
  output), with a fallback to the SDG API's raw `geoAreaName` for
  non-Member-State rows (e.g. regional / world aggregates)

- `timePeriodStart` → `year` (integer)

- `value` → `value` (character; raw) and `value_num` (numeric; `NA` for
  non-numeric entries like `"<0.1"` or aggregate notes)

- `lowerBound`, `upperBound` → `low`, `high` (numeric)

- `series` → `series`

Three columns are always present but never populated for SDG output:
`dim1`, `dim2`, `dim3` (GHO-only positions). SDG uses named dimensions,
potentially more than three, with no general mapping to those positions.
Set `keep_dimensions = TRUE` to retain all observed SDG dimensions as
additional columns. The default compact output omits them, so filter to
the required strata before using it for analysis.

## See also

[`sdg_data()`](https://shanlong-who.github.io/DSIR/reference/sdg_data.md),
[`gho_clean()`](https://shanlong-who.github.io/DSIR/reference/gho_clean.md),
[`bind_indicators()`](https://shanlong-who.github.io/DSIR/reference/bind_indicators.md),
[`sdg_dimensions()`](https://shanlong-who.github.io/DSIR/reference/sdg_dimensions.md),
[`m49_to_iso3()`](https://shanlong-who.github.io/DSIR/reference/m49_to_iso3.md).

## Examples

``` r
# \donttest{
sdg_data("3.2.1", area = "156", year_from = 2015) |>
  sdg_clean(keep_dimensions = TRUE)
#> Fetching:
#> <https://unstats.un.org/sdgs/UNSDGAPIV5/v1/sdg/Indicator/Data?indicator=3.2.1&pageSize=1000&areaCode=156&page=1>
#> # A tibble: 120 × 18
#>    source id    indicator     location iso3  location_name  year value value_num
#>    <chr>  <chr> <chr>         <chr>    <chr> <chr>         <int> <chr>     <dbl>
#>  1 sdg    3.2.1 Infant death… 156      CHN   China          2015 84118  84118   
#>  2 sdg    3.2.1 Infant death… 156      CHN   China          2015 64505  64505   
#>  3 sdg    3.2.1 Infant death… 156      CHN   China          2015 1486… 148623   
#>  4 sdg    3.2.1 Under-five m… 156      CHN   China          2015 11.3…     11.3 
#>  5 sdg    3.2.1 Under-five m… 156      CHN   China          2015 10.0…     10.1 
#>  6 sdg    3.2.1 Under-five m… 156      CHN   China          2015 10.7…     10.7 
#>  7 sdg    3.2.1 Infant morta… 156      CHN   China          2015 7.68…      7.69
#>  8 sdg    3.2.1 Infant morta… 156      CHN   China          2015 8.69…      8.70
#>  9 sdg    3.2.1 Infant morta… 156      CHN   China          2015 8.20…      8.21
#> 10 sdg    3.2.1 Under-five d… 156      CHN   China          2015 1100… 110048   
#> # ℹ 110 more rows
#> # ℹ 9 more variables: low <dbl>, high <dbl>, series <chr>, dim1 <chr>,
#> #   dim2 <chr>, dim3 <chr>, dim_age <chr>, dim_sex <chr>,
#> #   dim_reporting_type <chr>
# }
```
