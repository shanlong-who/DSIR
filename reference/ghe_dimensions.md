# Explore Global Health Estimates Dimensions

Retrieves official references and small, filtered code-list slices from
WHO's public xMart GHE table. Results are cached in memory for ten
minutes.

## Usage

``` r
ghe_dimensions(dimension = "measure")
```

## Arguments

- dimension:

  One of `"area"`, `"year"`, `"sex"`, `"age"`, `"cause"`, or
  `"measure"`. Default `"measure"`.

## Value

A tibble of `code` and `label`. Cause results include hierarchy fields.
Measures include their provider field and unit. Missing official labels
remain `NA`. Countries, ages and causes describe the latest GHE year;
use
[`ghe_coverage()`](https://shanlong-who.github.io/DSIR/reference/ghe_coverage.md)
to verify a specific selection.

## See also

[`ghe_data()`](https://shanlong-who.github.io/DSIR/reference/ghe_data.md),
[`ghe_causes()`](https://shanlong-who.github.io/DSIR/reference/ghe_causes.md),
[`ghe_coverage()`](https://shanlong-who.github.io/DSIR/reference/ghe_coverage.md)

## Examples

``` r
# \donttest{
ghe_dimensions('sex')
#> # A tibble: 3 × 2
#>   code   label 
#>   <chr>  <chr> 
#> 1 MALE   Male  
#> 2 FEMALE Female
#> 3 TOTAL  Total 
ghe_dimensions('age')
#> # A tibble: 22 × 2
#>    code   label         
#>    <chr>  <chr>         
#>  1 D0T27  NA            
#>  2 M1T11  NA            
#>  3 TOTAL  All ages      
#>  4 Y0T1   Under 1 year  
#>  5 Y10T14 10 to 14 years
#>  6 Y15T19 15 to 19 years
#>  7 Y1T4   1 to 4 years  
#>  8 Y20T24 20 to 24 years
#>  9 Y25T29 25 to 29 years
#> 10 Y30T34 30 to 34 years
#> # ℹ 12 more rows
ghe_dimensions('measure')
#> # A tibble: 11 × 4
#>    code           field                     label                          unit 
#>    <chr>          <chr>                     <chr>                          <chr>
#>  1 deaths         VAL_DTHS_COUNT_NUMERIC    Deaths                         deat…
#>  2 death_rate     VAL_DTHS_RATE100K_NUMERIC Death rate                     per …
#>  3 yll            VAL_YLL_COUNT_NUMERIC     Years of life lost             years
#>  4 yll_rate       VAL_YLL_RATE100K_NUMERIC  YLL rate                       per …
#>  5 yld            VAL_YLD_COUNT_NUMERIC     Years lived with disability    years
#>  6 yld_rate       VAL_YLD_RATE100K_NUMERIC  YLD rate                       per …
#>  7 daly           VAL_DALY_COUNT_NUMERIC    Disability-adjusted life years years
#>  8 daly_rate      VAL_DALY_RATE100K_NUMERIC DALY rate                      per …
#>  9 deaths_percent VAL_PROP_DTHS_PERCENT     Share of deaths                perc…
#> 10 yld_percent    VAL_PROP_YLD_PERCENT      Share of YLD                   perc…
#> 11 daly_percent   VAL_PROP_DALY_PERCENT     Share of DALY                  perc…
# }
```
