# List SDG Geographic Areas

Fetches the list of geographic areas available from the UN SDG database.

## Usage

``` r
sdg_areas()
```

## Value

A [tibble](https://tibble.tidyverse.org/reference/tibble.html) with area
codes and names, or `NULL` when the service is unreachable.

## See also

[`sdg_data()`](https://shanlong-who.github.io/DSIR/reference/sdg_data.md).

## Examples

``` r
# \donttest{
sdg_areas()
#> Fetching: <https://unstats.un.org/sdgs/UNSDGAPIV5/v1/sdg/GeoArea/List>
#> # A tibble: 460 × 2
#>    geoAreaCode geoAreaName        
#>    <chr>       <chr>              
#>  1 4           Afghanistan        
#>  2 248         Åland Islands      
#>  3 8           Albania            
#>  4 12          Algeria            
#>  5 16          American Samoa     
#>  6 20          Andorra            
#>  7 24          Angola             
#>  8 660         Anguilla           
#>  9 10          Antarctica         
#> 10 28          Antigua and Barbuda
#> # ℹ 450 more rows
# }
```
