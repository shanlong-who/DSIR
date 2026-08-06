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
#> Waiting 2s for retry backoff ■■■■■■■■■■■■■■■                 
#> Waiting 2s for retry backoff ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■  
#> Waiting 4s for retry backoff ■■■■■■■■                        
#> Waiting 4s for retry backoff ■■■■■■■■■■■■■■■■■■■             
#> Waiting 4s for retry backoff ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■  
#> Warning: SDG request failed.
#> ℹ URL: <https://unstats.un.org/sdgs/UNSDGAPIV5/v1/sdg/GeoArea/List>
#> ✖ Failed to perform HTTP request. Caused by error in
#>   `curl::curl_fetch_memory()`: ! Timeout was reached [unstats.un.org]:
#>   Operation timed out after 30001 milliseconds with 0 bytes received
#> NULL
# }
```
