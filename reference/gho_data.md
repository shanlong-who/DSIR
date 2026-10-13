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
#> # A tibble: 12,210 × 26
#>        Id IndicatorCode SpatialDimType SpatialDim ParentLocationCode TimeDimType
#>     <int> <chr>         <chr>          <chr>      <chr>              <chr>      
#>  1 1.39e6 NCDMORT3070   COUNTRY        HRV        EUR                YEAR       
#>  2 1.40e6 NCDMORT3070   COUNTRY        SLV        AMR                YEAR       
#>  3 1.40e6 NCDMORT3070   COUNTRY        BGR        EUR                YEAR       
#>  4 1.40e6 NCDMORT3070   COUNTRY        BRB        AMR                YEAR       
#>  5 1.40e6 NCDMORT3070   COUNTRY        GNQ        AFR                YEAR       
#>  6 1.40e6 NCDMORT3070   COUNTRY        PAN        AMR                YEAR       
#>  7 1.40e6 NCDMORT3070   COUNTRY        SGP        WPR                YEAR       
#>  8 1.40e6 NCDMORT3070   COUNTRY        CAF        AFR                YEAR       
#>  9 1.40e6 NCDMORT3070   COUNTRY        EGY        EMR                YEAR       
#> 10 1.40e6 NCDMORT3070   COUNTRY        TUN        EMR                YEAR       
#> # ℹ 12,200 more rows
#> # ℹ 20 more variables: ParentLocation <chr>, Dim1Type <chr>, Dim1 <chr>,
#> #   TimeDim <int>, Dim2Type <chr>, Dim2 <chr>, Dim3Type <lgl>, Dim3 <lgl>,
#> #   DataSourceDimType <lgl>, DataSourceDim <lgl>, Value <chr>,
#> #   NumericValue <dbl>, Low <dbl>, High <dbl>, Comments <chr>, Date <chr>,
#> #   TimeDimensionValue <chr>, TimeDimensionBegin <chr>, TimeDimensionEnd <chr>,
#> #   Provider <chr>

# Specific countries and years
gho_data("WHOSIS_000001", area = c("FRA", "DEU"), year_from = 2015)
#> Assuming `spatial_type` = "country" since `area` was given.
#> ℹ Pass `spatial_type` explicitly to silence this message.
#> Fetching:
#> <https://ghoapi.azureedge.net/api/WHOSIS_000001?$filter=SpatialDimType%20eq%20%27COUNTRY%27%20and%20SpatialDim%20in%20%28%27FRA%27%2C%27DEU%27%29%20and%20TimeDim%20ge%202015>
#> # A tibble: 54 × 26
#>        Id IndicatorCode SpatialDimType SpatialDim TimeDimType ParentLocationCode
#>     <int> <chr>         <chr>          <chr>      <chr>       <chr>             
#>  1 1.25e6 WHOSIS_000001 COUNTRY        DEU        YEAR        EUR               
#>  2 1.25e6 WHOSIS_000001 COUNTRY        DEU        YEAR        EUR               
#>  3 1.25e6 WHOSIS_000001 COUNTRY        FRA        YEAR        EUR               
#>  4 1.25e6 WHOSIS_000001 COUNTRY        FRA        YEAR        EUR               
#>  5 1.48e6 WHOSIS_000001 COUNTRY        DEU        YEAR        EUR               
#>  6 2.03e6 WHOSIS_000001 COUNTRY        FRA        YEAR        EUR               
#>  7 2.11e6 WHOSIS_000001 COUNTRY        DEU        YEAR        EUR               
#>  8 2.24e6 WHOSIS_000001 COUNTRY        FRA        YEAR        EUR               
#>  9 2.61e6 WHOSIS_000001 COUNTRY        DEU        YEAR        EUR               
#> 10 2.86e6 WHOSIS_000001 COUNTRY        FRA        YEAR        EUR               
#> # ℹ 44 more rows
#> # ℹ 20 more variables: ParentLocation <chr>, Dim1Type <chr>, Dim1 <chr>,
#> #   TimeDim <int>, Dim2Type <lgl>, Dim2 <lgl>, Dim3Type <lgl>, Dim3 <lgl>,
#> #   DataSourceDimType <lgl>, DataSourceDim <lgl>, Value <chr>,
#> #   NumericValue <dbl>, Low <dbl>, High <dbl>, Comments <lgl>, Date <chr>,
#> #   TimeDimensionValue <chr>, TimeDimensionBegin <chr>, TimeDimensionEnd <chr>,
#> #   Provider <chr>

# Keep only the both-sexes breakdown, filtered server-side
gho_data("NCDMORT3070", spatial_type = "country", dim1 = "SEX_BTSX")
#> Fetching:
#> <https://ghoapi.azureedge.net/api/NCDMORT3070?$filter=SpatialDimType%20eq%20%27COUNTRY%27%20and%20Dim1%20in%20%28%27SEX_BTSX%27%29>
#> # A tibble: 4,070 × 26
#>        Id IndicatorCode SpatialDimType SpatialDim ParentLocationCode TimeDimType
#>     <int> <chr>         <chr>          <chr>      <chr>              <chr>      
#>  1 1.40e6 NCDMORT3070   COUNTRY        PAN        AMR                YEAR       
#>  2 1.40e6 NCDMORT3070   COUNTRY        TUN        EMR                YEAR       
#>  3 1.40e6 NCDMORT3070   COUNTRY        TZA        AFR                YEAR       
#>  4 1.41e6 NCDMORT3070   COUNTRY        HTI        AMR                YEAR       
#>  5 1.41e6 NCDMORT3070   COUNTRY        TZA        AFR                YEAR       
#>  6 1.41e6 NCDMORT3070   COUNTRY        CAN        AMR                YEAR       
#>  7 1.41e6 NCDMORT3070   COUNTRY        IRN        EMR                YEAR       
#>  8 1.41e6 NCDMORT3070   COUNTRY        IDN        WPR                YEAR       
#>  9 1.42e6 NCDMORT3070   COUNTRY        TUR        EUR                YEAR       
#> 10 1.42e6 NCDMORT3070   COUNTRY        GHA        AFR                YEAR       
#> # ℹ 4,060 more rows
#> # ℹ 20 more variables: ParentLocation <chr>, Dim1Type <chr>, Dim1 <chr>,
#> #   TimeDim <int>, Dim2Type <chr>, Dim2 <chr>, Dim3Type <lgl>, Dim3 <lgl>,
#> #   DataSourceDimType <lgl>, DataSourceDim <lgl>, Value <chr>,
#> #   NumericValue <dbl>, Low <dbl>, High <dbl>, Comments <chr>, Date <chr>,
#> #   TimeDimensionValue <chr>, TimeDimensionBegin <chr>, TimeDimensionEnd <chr>,
#> #   Provider <chr>

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
