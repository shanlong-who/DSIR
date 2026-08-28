# List SDG Targets

Fetches the list of SDG targets from the UN SDG API.

## Usage

``` r
sdg_targets(include_children = FALSE)
```

## Arguments

- include_children:

  Logical. Include indicators nested under each target? Default `FALSE`.

## Value

A list (or [tibble](https://tibble.tidyverse.org/reference/tibble.html))
of SDG targets, or `NULL` when the service is unreachable.

## See also

[`sdg_goals()`](https://shanlong-who.github.io/DSIR/reference/sdg_goals.md),
[`sdg_indicators()`](https://shanlong-who.github.io/DSIR/reference/sdg_indicators.md).

## Examples

``` r
# \donttest{
sdg_targets()
#> Fetching:
#> <https://unstats.un.org/sdgs/UNSDGAPIV5/v1/sdg/Target/List?includechildren=false>
#> # A tibble: 169 × 6
#>    goal  code  title                                description uri   indicators
#>    <chr> <chr> <chr>                                <chr>       <chr> <lgl>     
#>  1 1     1.1   By 2030, eradicate extreme poverty … By 2030, e… /v1/… NA        
#>  2 1     1.2   By 2030, reduce at least by half th… By 2030, r… /v1/… NA        
#>  3 1     1.3   Implement nationally appropriate so… Implement … /v1/… NA        
#>  4 1     1.4   By 2030, ensure that all men and wo… By 2030, e… /v1/… NA        
#>  5 1     1.5   By 2030, build the resilience of th… By 2030, b… /v1/… NA        
#>  6 1     1.a   Ensure significant mobilization of … Ensure sig… /v1/… NA        
#>  7 1     1.b   Create sound policy frameworks at t… Create sou… /v1/… NA        
#>  8 2     2.1   By 2030, end hunger and ensure acce… By 2030, e… /v1/… NA        
#>  9 2     2.2   By 2030, end all forms of malnutrit… By 2030, e… /v1/… NA        
#> 10 2     2.3   By 2030, double the agricultural pr… By 2030, d… /v1/… NA        
#> # ℹ 159 more rows
# }
```
