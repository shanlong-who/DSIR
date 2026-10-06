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
  dimensions = NULL
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

## Value

A [tibble](https://tibble.tidyverse.org/reference/tibble.html) of
indicator observations, or an empty tibble when the service is
unreachable.

## Details

Uses the public production xMart backend by default. Advanced users may
set `DSIR.who_backend = "legacy"` for explicit comparisons, or set
`DSIR.who_base_url` to another compatible HTTPS origin. Failures never
trigger a silent fallback. Public directory coverage differs from the
legacy catalog; unknown codes warn instead of substituting another code.
Reference lookups are cached only in memory; no credentials or startup
requests are required.

## See also

[`gho_indicators()`](https://shanlong-who.github.io/DSIR/reference/gho_indicators.md),
[`gho_dimensions()`](https://shanlong-who.github.io/DSIR/reference/gho_dimensions.md).

## Examples

``` r
# \donttest{
# Country-level data for one indicator
gho_data("NCDMORT3070", spatial_type = "country")
#> Fetching WHO: "DATA_/RELAY_WHS"
#> Fetching WHO: "DATA_/RELAY_WHS"
#> Fetching WHO: "DATA_/RELAY_WHS"
#> # A tibble: 12,208 × 49
#>    Id                      IndicatorCode IndicatorName SpatialDim SpatialDimType
#>    <chr>                   <chr>         <chr>         <chr>      <chr>         
#>  1 776b0b46-f1dc-86b0-906… NCDMORT3070   Probability … AFG        COUNTRY       
#>  2 edf1459a-be91-88d7-906… NCDMORT3070   Probability … AFG        COUNTRY       
#>  3 aa638549-26ae-842d-906… NCDMORT3070   Probability … AFG        COUNTRY       
#>  4 4088a1b8-09ef-8bf7-906… NCDMORT3070   Probability … ALB        COUNTRY       
#>  5 3a53530e-1059-8cc6-906… NCDMORT3070   Probability … ALB        COUNTRY       
#>  6 c75b8750-eef1-8098-906… NCDMORT3070   Probability … ALB        COUNTRY       
#>  7 e60aca22-9feb-8390-906… NCDMORT3070   Probability … DZA        COUNTRY       
#>  8 66b006ab-e581-8d87-907… NCDMORT3070   Probability … DZA        COUNTRY       
#>  9 07a4b550-018e-8067-907… NCDMORT3070   Probability … DZA        COUNTRY       
#> 10 cbecd4bf-db28-8c54-907… NCDMORT3070   Probability … AGO        COUNTRY       
#> # ℹ 12,198 more rows
#> # ℹ 44 more variables: SpatialDimTypeOriginal <chr>, SpatialName <chr>,
#> #   TimeDim <int>, TimeDimType <chr>, TimeDimensionValue <chr>, Value <chr>,
#> #   NumericValue <dbl>, Low <dbl>, High <dbl>, Date <chr>, Unit <chr>,
#> #   MeasureField <chr>, DataSourceDim <chr>, Comments <chr>, Dim1Type <chr>,
#> #   Dim1 <chr>, Dim2Type <chr>, Dim2 <chr>, Dim3Type <chr>, Dim3 <chr>,
#> #   DIM_SEX <chr>, DIM_AGE <chr>, DIM_AMR_GLASS_AWARE <chr>, …

# Specific countries and years
gho_data("WHOSIS_000001", area = c("FRA", "DEU"), year_from = 2015)
#> Assuming `spatial_type` = "country" since `area` was given.
#> Fetching WHO: "DATA_/RELAY_WHS"
#> # A tibble: 42 × 49
#>    Id                      IndicatorCode IndicatorName SpatialDim SpatialDimType
#>    <chr>                   <chr>         <chr>         <chr>      <chr>         
#>  1 d1559bb3-a35c-8f15-820… WHOSIS_000001 Life expecta… FRA        COUNTRY       
#>  2 c51700b5-bb92-8081-820… WHOSIS_000001 Life expecta… DEU        COUNTRY       
#>  3 60501b58-04e9-8bbc-8d3… WHOSIS_000001 Life expecta… DEU        COUNTRY       
#>  4 37853978-1351-8e0e-8a8… WHOSIS_000001 Life expecta… FRA        COUNTRY       
#>  5 4703d3d5-4fdf-8d7b-871… WHOSIS_000001 Life expecta… DEU        COUNTRY       
#>  6 3e2efe26-0cd4-88d8-811… WHOSIS_000001 Life expecta… FRA        COUNTRY       
#>  7 34c96dc7-1c80-8cdd-836… WHOSIS_000001 Life expecta… DEU        COUNTRY       
#>  8 9ef2600f-03ec-8cf4-83a… WHOSIS_000001 Life expecta… FRA        COUNTRY       
#>  9 bb5388ef-2413-8871-907… WHOSIS_000001 Life expecta… DEU        COUNTRY       
#> 10 3ecebba1-f438-80b0-968… WHOSIS_000001 Life expecta… FRA        COUNTRY       
#> # ℹ 32 more rows
#> # ℹ 44 more variables: SpatialDimTypeOriginal <chr>, SpatialName <chr>,
#> #   TimeDim <int>, TimeDimType <chr>, TimeDimensionValue <chr>, Value <chr>,
#> #   NumericValue <dbl>, Low <dbl>, High <dbl>, Date <chr>, Unit <chr>,
#> #   MeasureField <chr>, DataSourceDim <chr>, Comments <chr>, Dim1Type <chr>,
#> #   Dim1 <chr>, Dim2Type <chr>, Dim2 <chr>, Dim3Type <chr>, Dim3 <chr>,
#> #   DIM_SEX <chr>, DIM_AGE <chr>, DIM_AMR_GLASS_AWARE <chr>, …

# Keep only the both-sexes breakdown, filtered server-side
gho_data("NCDMORT3070", spatial_type = "country", dim1 = "SEX_BTSX")
#> Fetching WHO: "DATA_/RELAY_WHS"
#> # A tibble: 4,068 × 49
#>    Id                      IndicatorCode IndicatorName SpatialDim SpatialDimType
#>    <chr>                   <chr>         <chr>         <chr>      <chr>         
#>  1 aa638549-26ae-842d-906… NCDMORT3070   Probability … AFG        COUNTRY       
#>  2 c75b8750-eef1-8098-906… NCDMORT3070   Probability … ALB        COUNTRY       
#>  3 07a4b550-018e-8067-907… NCDMORT3070   Probability … DZA        COUNTRY       
#>  4 fb25255f-433e-840a-907… NCDMORT3070   Probability … AGO        COUNTRY       
#>  5 63d93527-7b21-8e2a-907… NCDMORT3070   Probability … ATG        COUNTRY       
#>  6 f231bb3d-5806-8e55-805… NCDMORT3070   Probability … AZE        COUNTRY       
#>  7 d45a826c-8f4b-822a-805… NCDMORT3070   Probability … ARG        COUNTRY       
#>  8 9c0bb9dd-1410-8c65-806… NCDMORT3070   Probability … AUS        COUNTRY       
#>  9 4fc7fad3-bf2d-805f-806… NCDMORT3070   Probability … AUT        COUNTRY       
#> 10 2b82447c-09b6-8489-806… NCDMORT3070   Probability … BHS        COUNTRY       
#> # ℹ 4,058 more rows
#> # ℹ 44 more variables: SpatialDimTypeOriginal <chr>, SpatialName <chr>,
#> #   TimeDim <int>, TimeDimType <chr>, TimeDimensionValue <chr>, Value <chr>,
#> #   NumericValue <dbl>, Low <dbl>, High <dbl>, Date <chr>, Unit <chr>,
#> #   MeasureField <chr>, DataSourceDim <chr>, Comments <chr>, Dim1Type <chr>,
#> #   Dim1 <chr>, Dim2Type <chr>, Dim2 <chr>, Dim3Type <chr>, Dim3 <chr>,
#> #   DIM_SEX <chr>, DIM_AGE <chr>, DIM_AMR_GLASS_AWARE <chr>, …
# }
```
