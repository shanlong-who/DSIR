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
sdg_clean(df)
```

## Arguments

- df:

  A data frame returned by
  [`sdg_data()`](https://shanlong-who.github.io/DSIR/reference/sdg_data.md).

## Value

A [tibble](https://tibble.tidyverse.org/reference/tibble.html) with 15
columns: `source` (always `"sdg"`), `id`, `indicator`, `location`,
`iso3`, `location_name`, `year`, `value`, `value_num`, `low`, `high`,
`series`, `dim1` (`NA`), `dim2` (`NA`), `dim3` (`NA`). Sorted by
`location` then `year`. Empty input returns an empty tibble with the
same columns and types.

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

- `geoAreaName` → `location_name`

- `timePeriodStart` → `year` (integer)

- `value` → `value` (character; raw) and `value_num` (numeric; `NA` for
  non-numeric entries like `"<0.1"` or aggregate notes)

- `lowerBound`, `upperBound` → `low`, `high` (numeric)

- `series` → `series`

Three columns are always present but never populated for SDG output:
`dim1`, `dim2`, `dim3` (GHO-only concepts).

## See also

[`sdg_data()`](https://shanlong-who.github.io/DSIR/reference/sdg_data.md),
[`gho_clean()`](https://shanlong-who.github.io/DSIR/reference/gho_clean.md),
[`bind_indicators()`](https://shanlong-who.github.io/DSIR/reference/bind_indicators.md),
[`m49_to_iso3()`](https://shanlong-who.github.io/DSIR/reference/m49_to_iso3.md).

## Examples

``` r
# \donttest{
sdg_data("3.2.1", area = "156", year_from = 2015) |>
  sdg_clean()
#> Fetching:
#> <https://unstats.un.org/sdgs/UNSDGAPIV5/v1/sdg/Indicator/Data?indicator=3.2.1&pageSize=1000&areaCode=156&page=1>
#> # A tibble: 120 × 15
#>    source id    indicator     location iso3  location_name  year value value_num
#>    <chr>  <chr> <chr>         <chr>    <chr> <chr>         <int> <chr>     <dbl>
#>  1 sdg    3.2.1 Infant death… 156      CHN   China          2015 64505  64505   
#>  2 sdg    3.2.1 Infant death… 156      CHN   China          2015 84118  84118   
#>  3 sdg    3.2.1 Infant death… 156      CHN   China          2015 1486… 148623   
#>  4 sdg    3.2.1 Under-five m… 156      CHN   China          2015 10.0…     10.1 
#>  5 sdg    3.2.1 Under-five m… 156      CHN   China          2015 11.3…     11.3 
#>  6 sdg    3.2.1 Under-five m… 156      CHN   China          2015 10.7…     10.7 
#>  7 sdg    3.2.1 Infant morta… 156      CHN   China          2015 7.68…      7.69
#>  8 sdg    3.2.1 Infant morta… 156      CHN   China          2015 8.69…      8.70
#>  9 sdg    3.2.1 Infant morta… 156      CHN   China          2015 8.20…      8.21
#> 10 sdg    3.2.1 Under-five d… 156      CHN   China          2015 84820  84820   
#> # ℹ 110 more rows
#> # ℹ 6 more variables: low <dbl>, high <dbl>, series <chr>, dim1 <chr>,
#> #   dim2 <chr>, dim3 <chr>
# }
```
