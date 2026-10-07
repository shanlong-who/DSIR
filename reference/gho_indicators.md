# List GHO Indicators

Fetches the catalog of indicators from the WHO Global Health Observatory
(GHO) OData API.

## Usage

``` r
gho_indicators(search = NULL, backend = NULL)
```

## Arguments

- search:

  Optional character. Search keywords matched against `IndicatorName`
  (case-insensitive). All terms must match (AND semantics). Accepts
  either:

  - a single string, which is split on whitespace into terms (e.g.
    `"child mortality"` matches indicators containing both "child" and
    "mortality"), or

  - a character vector, whose elements are used as terms verbatim
    (whitespace inside an element is treated as part of the term).

  Search terms are matched literally; they are not download identifiers.

- backend:

  Character scalar. `"legacy"` or `"xmart"`. Default `NULL` uses the
  `DSIR.who_backend` option, or `"legacy"` when that option is unset. An
  explicit argument overrides the option for this call without changing
  it. Use the same backend for discovery and retrieval.

## Value

A [tibble](https://tibble.tidyverse.org/reference/tibble.html) with
columns `IndicatorCode`, `IndicatorName` and `Language`. Returns an
empty tibble (with a warning) when the service is unreachable.

## See also

[`gho_data()`](https://shanlong-who.github.io/DSIR/reference/gho_data.md),
[`gho_dimensions()`](https://shanlong-who.github.io/DSIR/reference/gho_dimensions.md).

## Examples

``` r
# \donttest{
# All indicators
inds <- gho_indicators()
#> Fetching: <https://ghoapi.azureedge.net/api/Indicator>

# Single keyword
gho_indicators("mortality")
#> Fetching:
#> <https://ghoapi.azureedge.net/api/Indicator?$filter=contains%28tolower%28IndicatorName%29%2C%27mortality%27%29>
#> Waiting 2s for retry backoff ■■■■■■■■■■■■■■■                 
#> Waiting 2s for retry backoff ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■  
#> Waiting 4s for retry backoff ■■■■■■■■                        
#> Waiting 4s for retry backoff ■■■■■■■■■■■■■■■■■■■■■■■■■       
#> Waiting 4s for retry backoff ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■  
#> Warning: GHO request failed.
#> ℹ URL:
#>   <https://ghoapi.azureedge.net/api/Indicator?$filter=contains%28tolower%28IndicatorName%29%2C%27mortality%27%29>
#> ✖ HTTP 502 Bad Gateway.
#> # A tibble: 0 × 3
#> # ℹ 3 variables: IndicatorCode <chr>, IndicatorName <chr>, Language <chr>

# Multiple keywords from one string (AND): both terms must appear
gho_indicators("child mortality")
#> Fetching:
#> <https://ghoapi.azureedge.net/api/Indicator?$filter=contains%28tolower%28IndicatorName%29%2C%27child%27%29%20and%20contains%28tolower%28IndicatorName%29%2C%27mortality%27%29>
#> Waiting 2s for retry backoff ■■■■■■■■■■■■■■■                 
#> Waiting 2s for retry backoff ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■  
#> Waiting 4s for retry backoff ■■■■■■■■■■■                     
#> Waiting 4s for retry backoff ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■  
#> Warning: GHO request failed.
#> ℹ URL:
#>   <https://ghoapi.azureedge.net/api/Indicator?$filter=contains%28tolower%28IndicatorName%29%2C%27child%27%29%20and%20contains%28tolower%28IndicatorName%29%2C%27mortality%27%29>
#> ✖ HTTP 502 Bad Gateway.
#> # A tibble: 0 × 3
#> # ℹ 3 variables: IndicatorCode <chr>, IndicatorName <chr>, Language <chr>

# Or pass terms as a vector
gho_indicators(c("child", "mortality"))
#> Fetching:
#> <https://ghoapi.azureedge.net/api/Indicator?$filter=contains%28tolower%28IndicatorName%29%2C%27child%27%29%20and%20contains%28tolower%28IndicatorName%29%2C%27mortality%27%29>
#> Waiting 2s for retry backoff ■■■■■■■■■■■■■■■                 
#> Waiting 2s for retry backoff ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■  
#> Waiting 4s for retry backoff ■■■■■■■■                        
#> Waiting 4s for retry backoff ■■■■■■■■■■■■■■■■■■■■            
#> Waiting 4s for retry backoff ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■  
#> Warning: GHO request failed.
#> ℹ URL:
#>   <https://ghoapi.azureedge.net/api/Indicator?$filter=contains%28tolower%28IndicatorName%29%2C%27child%27%29%20and%20contains%28tolower%28IndicatorName%29%2C%27mortality%27%29>
#> ✖ HTTP 502 Bad Gateway.
#> # A tibble: 0 × 3
#> # ℹ 3 variables: IndicatorCode <chr>, IndicatorName <chr>, Language <chr>
# }
```
