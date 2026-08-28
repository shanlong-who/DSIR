# List SDG Indicators

Fetches the list of SDG indicators from the UN SDG API, with optional
keyword filtering on the indicator description.

## Usage

``` r
sdg_indicators(search = NULL)
```

## Arguments

- search:

  Optional character. Search keywords matched against the `description`
  column (case-insensitive). All terms must match (AND semantics).
  Accepts either:

  - a single string, which is split on whitespace into terms (e.g.
    `"mortality cancer"` keeps rows whose description contains both
    "mortality" and "cancer"), or

  - a character vector, whose elements are used as terms verbatim (so a
    term may itself contain whitespace, e.g.
    `c("mortality rate", "attributed")`).

  The filter is applied client-side using
  [`grepl()`](https://rdrr.io/r/base/grep.html) with `fixed = TRUE`
  because the UN SDG `/Indicator/List` endpoint is not OData and exposes
  no server-side search parameter; the full list is small (~250 rows) so
  this is cheap.

## Value

A list (or [tibble](https://tibble.tidyverse.org/reference/tibble.html))
of SDG indicators, or `NULL` when the service is unreachable. When
`search` matches no rows, an empty tibble with the same columns as the
unfiltered response is returned.

## See also

[`sdg_targets()`](https://shanlong-who.github.io/DSIR/reference/sdg_targets.md),
[`sdg_data()`](https://shanlong-who.github.io/DSIR/reference/sdg_data.md).

## Examples

``` r
# \donttest{
# Full list
sdg_indicators()
#> Fetching: <https://unstats.un.org/sdgs/UNSDGAPIV5/v1/sdg/Indicator/List>
#> # A tibble: 251 × 7
#>    goal  target code  description                             tier  uri   series
#>    <chr> <chr>  <chr> <chr>                                   <chr> <chr> <list>
#>  1 1     1.1    1.1.1 Proportion of the population living be… 1     /v1/… <df>  
#>  2 1     1.2    1.2.1 Proportion of population living below … 1     /v1/… <df>  
#>  3 1     1.2    1.2.2 Proportion of men, women and children … 2     /v1/… <df>  
#>  4 1     1.3    1.3.1 Proportion of population covered by so… 1     /v1/… <df>  
#>  5 1     1.4    1.4.1 Proportion of population living in hou… 1     /v1/… <df>  
#>  6 1     1.4    1.4.2 Proportion of total adult population w… 2     /v1/… <df>  
#>  7 1     1.5    1.5.1 Number of deaths, missing persons and … 1     /v1/… <df>  
#>  8 1     1.5    1.5.2 Direct economic loss attributed to dis… 1     /v1/… <df>  
#>  9 1     1.5    1.5.3 Number of countries that adopt and imp… 1     /v1/… <df>  
#> 10 1     1.5    1.5.4 Proportion of local governments that a… 2     /v1/… <df>  
#> # ℹ 241 more rows

# Single keyword
sdg_indicators("mortality")
#> Fetching: <https://unstats.un.org/sdgs/UNSDGAPIV5/v1/sdg/Indicator/List>
#> # A tibble: 8 × 7
#>   goal  target code  description                              tier  uri   series
#>   <chr> <chr>  <chr> <chr>                                    <chr> <chr> <list>
#> 1 3     3.1    3.1.1 Maternal mortality ratio                 1     /v1/… <df>  
#> 2 3     3.2    3.2.1 Under‑5 mortality rate                   1     /v1/… <df>  
#> 3 3     3.2    3.2.2 Neonatal mortality rate                  1     /v1/… <df>  
#> 4 3     3.4    3.4.1 Mortality rate attributed to cardiovasc… 1     /v1/… <df>  
#> 5 3     3.4    3.4.2 Suicide mortality rate                   1     /v1/… <df>  
#> 6 3     3.9    3.9.1 Mortality rate attributed to household … 1     /v1/… <df>  
#> 7 3     3.9    3.9.2 Mortality rate attributed to unsafe wat… 1     /v1/… <df>  
#> 8 3     3.9    3.9.3 Mortality rate attributed to unintentio… 1     /v1/… <df>  

# Multi-keyword — AND semantics
sdg_indicators("mortality cancer")
#> Fetching: <https://unstats.un.org/sdgs/UNSDGAPIV5/v1/sdg/Indicator/List>
#> # A tibble: 1 × 7
#>   goal  target code  description                              tier  uri   series
#>   <chr> <chr>  <chr> <chr>                                    <chr> <chr> <list>
#> 1 3     3.4    3.4.1 Mortality rate attributed to cardiovasc… 1     /v1/… <df>  
sdg_indicators(c("maternal", "mortality"))
#> Fetching: <https://unstats.un.org/sdgs/UNSDGAPIV5/v1/sdg/Indicator/List>
#> # A tibble: 1 × 7
#>   goal  target code  description              tier  uri                   series
#>   <chr> <chr>  <chr> <chr>                    <chr> <chr>                 <list>
#> 1 3     3.1    3.1.1 Maternal mortality ratio 1     /v1/sdg/Indicator/3.… <df>  
# }
```
