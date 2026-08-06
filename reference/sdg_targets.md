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
#> Waiting 2s for retry backoff ■■■■■■■■■■■■■■■                 
#> Waiting 2s for retry backoff ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■  
#> Waiting 4s for retry backoff ■■■■■■■■                        
#> Waiting 4s for retry backoff ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■   
#> Waiting 4s for retry backoff ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■  
#> Warning: SDG request failed.
#> ℹ URL:
#>   <https://unstats.un.org/sdgs/UNSDGAPIV5/v1/sdg/Target/List?includechildren=false>
#> ✖ Failed to perform HTTP request. Caused by error in
#>   `curl::curl_fetch_memory()`: ! Timeout was reached [unstats.un.org]:
#>   Operation timed out after 30001 milliseconds with 0 bytes received
#> NULL
# }
```
