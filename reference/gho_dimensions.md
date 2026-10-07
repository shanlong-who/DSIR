# List Dimensions of a GHO Indicator

Returns the unique values of a given dimension across all observations
of a GHO indicator. Useful for discovering which ages, sexes, regions,
or other breakdowns are available before calling
[`gho_data()`](https://shanlong-who.github.io/DSIR/reference/gho_data.md).

## Usage

``` r
gho_dimensions(indicator, dimension = "SpatialDimType", backend = NULL)
```

## Arguments

- indicator:

  Character scalar. The indicator code (e.g. `"NCDMORT3070"`).

- dimension:

  Character. Name of the dimension column in the indicator data. Common
  values include `"SpatialDim"`, `"SpatialDimType"`, `"TimeDim"`,
  `"Dim1"`, `"Dim2"`, and `"Dim3"`. Case-sensitive (it is sent to the
  server as an OData `$select` field name). xMart also accepts exact
  named fields such as `"DIM_SEX"` or `"DIM_AGE"`. Default
  `"SpatialDimType"`.

- backend:

  Character scalar. `"legacy"` or `"xmart"`. Default `NULL` uses the
  `DSIR.who_backend` option, or `"legacy"` when that option is unset. An
  explicit argument overrides the option for this call without changing
  it. Use the same backend for discovery and retrieval.

## Value

A character vector of unique, sorted dimension values, or an empty
character vector when the service is unreachable or the dimension is
missing.

## Details

Only the requested column is downloaded (via the OData `$select` query
option), so this is a lightweight metadata query even for indicators
with hundreds of thousands of observations. A `dimension` that is not a
column of the GHO data table (e.g. a misspelling) makes the server
reject the request; the failure surfaces as a warning and an empty
character vector.

## See also

[`gho_data()`](https://shanlong-who.github.io/DSIR/reference/gho_data.md),
[`gho_indicators()`](https://shanlong-who.github.io/DSIR/reference/gho_indicators.md).

## Examples

``` r
# \donttest{
gho_dimensions("NCDMORT3070")
#> Fetching: <https://ghoapi.azureedge.net/api/NCDMORT3070?$select=SpatialDimType>
#> Waiting 2s for retry backoff ■■■■■■■■■■■■■■■                 
#> Waiting 2s for retry backoff ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■  
#> Waiting 4s for retry backoff ■■■■■■■■                        
#> Waiting 4s for retry backoff ■■■■■■■■■■■■■■■■■■■■■■          
#> Waiting 4s for retry backoff ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■  
#> Warning: GHO request failed.
#> ℹ URL: <https://ghoapi.azureedge.net/api/NCDMORT3070?$select=SpatialDimType>
#> ✖ HTTP 502 Bad Gateway.
#> character(0)
gho_dimensions("NCDMORT3070", dimension = "Dim1")
#> Fetching: <https://ghoapi.azureedge.net/api/NCDMORT3070?$select=Dim1>
#> Waiting 2s for retry backoff ■■■■■■■■■■■■■■■                 
#> Waiting 2s for retry backoff ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■  
#> Waiting 4s for retry backoff ■■■■■■■■■■                      
#> Waiting 4s for retry backoff ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■  
#> Warning: GHO request failed.
#> ℹ URL: <https://ghoapi.azureedge.net/api/NCDMORT3070?$select=Dim1>
#> ✖ HTTP 502 Bad Gateway.
#> character(0)
# }
```
