# List SDG Dimension Codes and Labels

Retrieves the official code lists for each series linked to an SDG
indicator, without downloading its observations. These are available
categories, not evidence that every category occurs in every country's
data. Inspect `unique(df$dimensions)` after
[`sdg_data()`](https://shanlong-who.github.io/DSIR/reference/sdg_data.md)
to see observed strata. Use the `code` column for filters; `sdmx` is an
alternative representation and may differ from the JSON API's
observation codes.

## Usage

``` r
sdg_dimensions(indicator, series = NULL, include_attributes = FALSE)
```

## Arguments

- indicator:

  A single SDG indicator code, e.g. `"3.8.2"`.

- series:

  Optional character vector of series codes linked to the indicator.
  Default `NULL` retrieves all its series.

- include_attributes:

  Logical. Also return attribute code lists, including units and data
  nature? Default `FALSE`.

## Value

A tibble with character columns `indicator`, `series`, `kind`
(`"dimension"` or `"attribute"`), `dimension` (the original field name),
`code`, `label`, and `sdmx`. Missing source labels stay `NA`. Sorted by
series, kind, dimension, and code. If any required request fails or its
structure is invalid, warns and returns a typed empty tibble instead of
a partial code list.

## See also

[`sdg_data()`](https://shanlong-who.github.io/DSIR/reference/sdg_data.md),
[`sdg_clean()`](https://shanlong-who.github.io/DSIR/reference/sdg_clean.md),
[`sdg_indicators()`](https://shanlong-who.github.io/DSIR/reference/sdg_indicators.md).

## Examples

``` r
# \donttest{
sdg_dimensions("3.8.2")
#> Fetching:
#> <https://unstats.un.org/sdgs/UNSDGAPIV5/v1/sdg/Indicator/3.8.2/Series/List>
#> Fetching:
#> <https://unstats.un.org/sdgs/UNSDGAPIV5/v1/sdg/Series/SH_OOP_XPD_EARNNET40/Dimensions>
#> # A tibble: 24 × 7
#>    indicator series               kind      dimension code    label        sdmx 
#>    <chr>     <chr>                <chr>     <chr>     <chr>   <chr>        <chr>
#>  1 3.8.2     SH_OOP_XPD_EARNNET40 dimension Age       0-59    under 59 ye… Y0T59
#>  2 3.8.2     SH_OOP_XPD_EARNNET40 dimension Age       60+     60 years ol… Y_GE…
#>  3 3.8.2     SH_OOP_XPD_EARNNET40 dimension Age       ALLAGE  All age ran… _T   
#>  4 3.8.2     SH_OOP_XPD_EARNNET40 dimension Location  ALLAREA All areas    _T   
#>  5 3.8.2     SH_OOP_XPD_EARNNET40 dimension Location  RURAL   Rural        R    
#>  6 3.8.2     SH_OOP_XPD_EARNNET40 dimension Location  URBAN   Urban        U    
#>  7 3.8.2     SH_OOP_XPD_EARNNET40 dimension Quantile  Q1      Quantile 1 … Q1   
#>  8 3.8.2     SH_OOP_XPD_EARNNET40 dimension Quantile  Q2      Quantile 2   Q2   
#>  9 3.8.2     SH_OOP_XPD_EARNNET40 dimension Quantile  Q3      Quantile 3   Q3   
#> 10 3.8.2     SH_OOP_XPD_EARNNET40 dimension Quantile  Q4      Quantile 4   Q4   
#> # ℹ 14 more rows
sdg_dimensions("3.8.2", include_attributes = TRUE)
#> Fetching:
#> <https://unstats.un.org/sdgs/UNSDGAPIV5/v1/sdg/Indicator/3.8.2/Series/List>
#> Fetching:
#> <https://unstats.un.org/sdgs/UNSDGAPIV5/v1/sdg/Series/SH_OOP_XPD_EARNNET40/Dimensions>
#> Fetching:
#> <https://unstats.un.org/sdgs/UNSDGAPIV5/v1/sdg/Series/SH_OOP_XPD_EARNNET40/Attributes>
#> # A tibble: 32 × 7
#>    indicator series               kind      dimension code    label        sdmx 
#>    <chr>     <chr>                <chr>     <chr>     <chr>   <chr>        <chr>
#>  1 3.8.2     SH_OOP_XPD_EARNNET40 attribute Nature    C       Country data C    
#>  2 3.8.2     SH_OOP_XPD_EARNNET40 attribute Nature    CA      Country adj… CA   
#>  3 3.8.2     SH_OOP_XPD_EARNNET40 attribute Nature    E       Estimated d… E    
#>  4 3.8.2     SH_OOP_XPD_EARNNET40 attribute Nature    G       Global moni… G    
#>  5 3.8.2     SH_OOP_XPD_EARNNET40 attribute Nature    M       Modeled data M    
#>  6 3.8.2     SH_OOP_XPD_EARNNET40 attribute Nature    N       Non-relevant N    
#>  7 3.8.2     SH_OOP_XPD_EARNNET40 attribute Nature    NA      Data nature… _X   
#>  8 3.8.2     SH_OOP_XPD_EARNNET40 attribute Units     PERCENT Percentage   PT   
#>  9 3.8.2     SH_OOP_XPD_EARNNET40 dimension Age       0-59    under 59 ye… Y0T59
#> 10 3.8.2     SH_OOP_XPD_EARNNET40 dimension Age       60+     60 years ol… Y_GE…
#> # ℹ 22 more rows
# }
```
