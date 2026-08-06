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
#> Waiting 2s for retry backoff ■■■■■■■■■■■■■■■                 
#> Waiting 2s for retry backoff ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■  
#> Waiting 4s for retry backoff ■■■■■■■■                        
#> Waiting 4s for retry backoff ■■■■■■■■■■                      
#> Waiting 4s for retry backoff ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■  
#> Warning: SDG request failed.
#> ℹ URL: <https://unstats.un.org/sdgs/UNSDGAPIV5/v1/sdg/Indicator/List>
#> ✖ Failed to perform HTTP request. Caused by error in
#>   `curl::curl_fetch_memory()`: ! Timeout was reached [unstats.un.org]:
#>   Operation timed out after 30000 milliseconds with 0 bytes received
#> NULL

# Single keyword
sdg_indicators("mortality")
#> Fetching: <https://unstats.un.org/sdgs/UNSDGAPIV5/v1/sdg/Indicator/List>
#> Waiting 2s for retry backoff ■■■■■■■■■■■■■■■                 
#> Waiting 2s for retry backoff ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■  
#> Waiting 4s for retry backoff ■■■■■■■■                        
#> Waiting 4s for retry backoff ■■■■■■■■■                       
#> Waiting 4s for retry backoff ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■  
#> Warning: SDG request failed.
#> ℹ URL: <https://unstats.un.org/sdgs/UNSDGAPIV5/v1/sdg/Indicator/List>
#> ✖ Failed to perform HTTP request. Caused by error in
#>   `curl::curl_fetch_memory()`: ! Timeout was reached [unstats.un.org]:
#>   Operation timed out after 30001 milliseconds with 0 bytes received
#> NULL

# Multi-keyword — AND semantics
sdg_indicators("mortality cancer")
#> Fetching: <https://unstats.un.org/sdgs/UNSDGAPIV5/v1/sdg/Indicator/List>
#> Waiting 2s for retry backoff ■■■■■■■■■■■■■■■                 
#> Waiting 2s for retry backoff ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■  
#> Waiting 4s for retry backoff ■■■■■■■■                        
#> Waiting 4s for retry backoff ■■■■■■■■■                       
#> Waiting 4s for retry backoff ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■  
#> Warning: SDG request failed.
#> ℹ URL: <https://unstats.un.org/sdgs/UNSDGAPIV5/v1/sdg/Indicator/List>
#> ✖ Failed to perform HTTP request. Caused by error in
#>   `curl::curl_fetch_memory()`: ! Timeout was reached [unstats.un.org]:
#>   Operation timed out after 30002 milliseconds with 0 bytes received
#> NULL
sdg_indicators(c("maternal", "mortality"))
#> Fetching: <https://unstats.un.org/sdgs/UNSDGAPIV5/v1/sdg/Indicator/List>
#> Waiting 2s for retry backoff ■■■■■■■■■■■■■■■                 
#> Waiting 2s for retry backoff ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■  
#> Waiting 4s for retry backoff ■■■■■■■■                        
#> Waiting 4s for retry backoff ■■■■■■■■■                       
#> Waiting 4s for retry backoff ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■  
#> Warning: SDG request failed.
#> ℹ URL: <https://unstats.un.org/sdgs/UNSDGAPIV5/v1/sdg/Indicator/List>
#> ✖ Failed to perform HTTP request. Caused by error in
#>   `curl::curl_fetch_memory()`: ! Timeout was reached [unstats.un.org]:
#>   Operation timed out after 30002 milliseconds with 0 bytes received
#> NULL
# }
```
