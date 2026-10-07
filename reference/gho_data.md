# Fetch GHO Data

Retrieves observations for a specific indicator from the WHO GHO OData
API, with optional filters by spatial level, country / region and year
range.

## Usage

``` r
gho_data(
  indicator,
  spatial_type = NULL,
  area = NULL,
  year_from = NULL,
  year_to = NULL,
  dim1 = NULL,
  dim2 = NULL,
  dim3 = NULL,
  dimensions = NULL,
  backend = NULL
)
```

## Arguments

- indicator:

  Character scalar. The indicator code (e.g. `"NCDMORT3070"`). Use
  [`gho_indicators()`](https://shanlong-who.github.io/DSIR/reference/gho_indicators.md)
  to find codes.

- spatial_type:

  Character. Spatial dimension to filter on: one of `"country"`,
  `"region"`, `"global"`, or `NULL` (all levels, the default).

- area:

  Character vector of country or region codes (e.g. `c("FRA", "DEU")`).
  Default `NULL` returns all areas.

- year_from:

  Numeric. Start year filter (inclusive). Default `NULL`.

- year_to:

  Numeric. End year filter (inclusive). Default `NULL`.

- dim1, dim2, dim3:

  Character vector of values to keep for the `Dim1` / `Dim2` / `Dim3`
  breakdown columns, filtered server-side (e.g. `dim1 = "SEX_BTSX"` for
  both-sexes rows only, or `dim1 = c("SEX_MLE", "SEX_FMLE")`). The
  meaning of each dimension varies by indicator (`Dim1` is sex for one
  indicator, an age group for another); use
  [`gho_dimensions()`](https://shanlong-who.github.io/DSIR/reference/gho_dimensions.md)
  to discover the values available for a given indicator. Rows where the
  dimension is empty (`null`) are excluded by the filter. Default `NULL`
  (no filtering). On xMart wide tables, positions follow named
  dimensions in the source table schema (sex, age, then alphabetical).
  These positions can differ from the legacy API. Prefer `dimensions`.
  Canonical sex codes and the `AGEGROUP_` namespace remain supported in
  positional filters. Named filters use the provider's exact native
  codes.

- dimensions:

  Optional named list of exact xMart dimension fields and values, e.g.
  `list(DIM_SEX = 'TOTAL')`. Requires the xMart backend.

- backend:

  Character scalar. `"legacy"` or `"xmart"`. Default `NULL` uses the
  `DSIR.who_backend` option, or `"legacy"` when that option is unset. An
  explicit argument overrides the option for this call without changing
  it. Use the same backend for discovery and retrieval.

## Value

A [tibble](https://tibble.tidyverse.org/reference/tibble.html) of
indicator observations, or an empty tibble when the service is
unreachable or no observations match. The raw `Provider` column records
`"legacy"` or `"xmart"` per row. A `who_provenance` attribute records
the selected backend and, for successful downloads, the request context
and retrieval time.

## Details

Uses the legacy GHO OData backend by default for compatibility. Select
`backend = "xmart"` to use the public production WHO xMart service, or
set `options(DSIR.who_backend = "xmart")` as a session default.
`DSIR.who_base_url` selects another compatible HTTPS xMart origin.
Failures never trigger a silent fallback. Public directory coverage
differs from the legacy catalog, and published estimates can differ.
Unknown xMart directory codes warn; legacy HTTP 404 responses are
checked against its directory before being classified as absent codes. A
successful query with no matching observations emits an informational
message. Request or parsing failures warn, and do not establish that no
data exist. Reference lookups are cached only in memory; no credentials
or startup requests are required.

## See also

[`gho_indicators()`](https://shanlong-who.github.io/DSIR/reference/gho_indicators.md),
[`gho_dimensions()`](https://shanlong-who.github.io/DSIR/reference/gho_dimensions.md).

## Examples

``` r
# \donttest{
# Country-level data for one indicator
gho_data("NCDMORT3070", spatial_type = "country")
#> Fetching:
#> <https://ghoapi.azureedge.net/api/NCDMORT3070?$filter=SpatialDimType%20eq%20%27COUNTRY%27>
#> Waiting 2s for retry backoff ■■■■■■■■■■■■■■■                 
#> Waiting 2s for retry backoff ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■  
#> Waiting 4s for retry backoff ■■■■■■■■                        
#> Waiting 4s for retry backoff ■■■■■■■■■■■■■■■■■■■■■           
#> Waiting 4s for retry backoff ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■  
#> Warning: GHO request failed.
#> ℹ URL:
#>   <https://ghoapi.azureedge.net/api/NCDMORT3070?$filter=SpatialDimType%20eq%20%27COUNTRY%27>
#> ✖ HTTP 502 Bad Gateway.
#> # A tibble: 0 × 1
#> # ℹ 1 variable: Provider <chr>

# Specific countries and years
gho_data("WHOSIS_000001", area = c("FRA", "DEU"), year_from = 2015)
#> Assuming `spatial_type` = "country" since `area` was given.
#> ℹ Pass `spatial_type` explicitly to silence this message.
#> Fetching:
#> <https://ghoapi.azureedge.net/api/WHOSIS_000001?$filter=SpatialDimType%20eq%20%27COUNTRY%27%20and%20SpatialDim%20in%20%28%27FRA%27%2C%27DEU%27%29%20and%20TimeDim%20ge%202015>
#> Waiting 2s for retry backoff ■■■■■■■■■■■■■■■                 
#> Waiting 2s for retry backoff ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■  
#> Waiting 4s for retry backoff ■■■■■■■■                        
#> Waiting 4s for retry backoff ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■  
#> Warning: GHO request failed.
#> ℹ URL:
#>   <https://ghoapi.azureedge.net/api/WHOSIS_000001?$filter=SpatialDimType%20eq%20%27COUNTRY%27%20and%20SpatialDim%20in%20%28%27FRA%27%2C%27DEU%27%29%20and%20TimeDim%20ge%202015>
#> ✖ HTTP 502 Bad Gateway.
#> # A tibble: 0 × 1
#> # ℹ 1 variable: Provider <chr>

# Keep only the both-sexes breakdown, filtered server-side
gho_data("NCDMORT3070", spatial_type = "country", dim1 = "SEX_BTSX")
#> Fetching:
#> <https://ghoapi.azureedge.net/api/NCDMORT3070?$filter=SpatialDimType%20eq%20%27COUNTRY%27%20and%20Dim1%20in%20%28%27SEX_BTSX%27%29>
#> Waiting 4s for retry backoff ■■■■■■■■                        
#> Waiting 4s for retry backoff ■■■■■■■■■■■■■■■■■■              
#> Waiting 4s for retry backoff ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■  
#> Warning: GHO request failed.
#> ℹ URL:
#>   <https://ghoapi.azureedge.net/api/NCDMORT3070?$filter=SpatialDimType%20eq%20%27COUNTRY%27%20and%20Dim1%20in%20%28%27SEX_BTSX%27%29>
#> ✖ HTTP 502 Bad Gateway.
#> # A tibble: 0 × 1
#> # ℹ 1 variable: Provider <chr>

# Select xMart for one call without changing the session default
gho_data("NCDMORT3070", area = "PHL", year_from = 2020, year_to = 2021,
         dimensions = list(DIM_SEX = "TOTAL"), backend = "xmart")
#> Assuming `spatial_type` = "country" since `area` was given.
#> Fetching WHO: "DATA_/IND_DIRECTORY_WIDE"
#> Fetching WHO: "DATA_/RELAY_WHS"
#> Fetching WHO: "DATA_/REF_GEO"
#> Fetching WHO: "DATA_/RELAY_WHS"
#> # A tibble: 2 × 50
#>   Id                       IndicatorCode IndicatorName SpatialDim SpatialDimType
#>   <chr>                    <chr>         <chr>         <chr>      <chr>         
#> 1 8409c30b-3c53-81d3-8e23… NCDMORT3070   Probability … PHL        COUNTRY       
#> 2 800448d6-5025-8bd8-9264… NCDMORT3070   Probability … PHL        COUNTRY       
#> # ℹ 45 more variables: SpatialDimTypeOriginal <chr>, SpatialName <chr>,
#> #   TimeDim <int>, TimeDimType <chr>, TimeDimensionValue <chr>, Value <chr>,
#> #   NumericValue <dbl>, Low <dbl>, High <dbl>, Date <chr>, Unit <chr>,
#> #   MeasureField <chr>, DataSourceDim <chr>, Comments <chr>, Dim1Type <chr>,
#> #   Dim1 <chr>, Dim2Type <chr>, Dim2 <chr>, Dim3Type <chr>, Dim3 <chr>,
#> #   DIM_SEX <chr>, DIM_AGE <chr>, DIM_AMR_GLASS_AWARE <chr>,
#> #   DIM_ASSISTIVETECHBARRIER <chr>, DIM_ASSISTIVETECHFUNDING <chr>, …
# }
```
