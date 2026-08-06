# List SDG Goals

Fetches the list of Sustainable Development Goals from the UN SDG API.

## Usage

``` r
sdg_goals(include_children = FALSE)
```

## Arguments

- include_children:

  Logical. Include targets and indicators nested under each goal?
  Default `FALSE`.

## Value

A list (or [tibble](https://tibble.tidyverse.org/reference/tibble.html))
of SDG goals, or `NULL` when the service is unreachable.

## See also

[`sdg_targets()`](https://shanlong-who.github.io/DSIR/reference/sdg_targets.md),
[`sdg_indicators()`](https://shanlong-who.github.io/DSIR/reference/sdg_indicators.md),
[`sdg_data()`](https://shanlong-who.github.io/DSIR/reference/sdg_data.md).

## Examples

``` r
# \donttest{
sdg_goals()
#> Fetching:
#> <https://unstats.un.org/sdgs/UNSDGAPIV5/v1/sdg/Goal/List?includechildren=false>
#> Waiting 2s for retry backoff ■■■■■■■■■■■■■■■                 
#> Waiting 2s for retry backoff ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■  
#> Waiting 4s for retry backoff ■■■■■■■■                        
#> Waiting 4s for retry backoff ■■■■■■■■■■■■                    
#> Waiting 4s for retry backoff ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■  
#> Warning: SDG request failed.
#> ℹ URL:
#>   <https://unstats.un.org/sdgs/UNSDGAPIV5/v1/sdg/Goal/List?includechildren=false>
#> ✖ Failed to perform HTTP request. Caused by error in
#>   `curl::curl_fetch_memory()`: ! Timeout was reached [unstats.un.org]:
#>   Operation timed out after 30002 milliseconds with 0 bytes received
#> NULL
sdg_goals(include_children = TRUE)
#> Fetching:
#> <https://unstats.un.org/sdgs/UNSDGAPIV5/v1/sdg/Goal/List?includechildren=true>
#> Waiting 2s for retry backoff ■■■■■■■■■■■■■■■                 
#> Waiting 2s for retry backoff ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■  
#> Waiting 4s for retry backoff ■■■■■■■■                        
#> Waiting 4s for retry backoff ■■■■■■■■■■■                     
#> Waiting 4s for retry backoff ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■  
#> Warning: SDG request failed.
#> ℹ URL:
#>   <https://unstats.un.org/sdgs/UNSDGAPIV5/v1/sdg/Goal/List?includechildren=true>
#> ✖ Failed to perform HTTP request. Caused by error in
#>   `curl::curl_fetch_memory()`: ! Timeout was reached [unstats.un.org]:
#>   Operation timed out after 30001 milliseconds with 0 bytes received
#> NULL
# }
```
