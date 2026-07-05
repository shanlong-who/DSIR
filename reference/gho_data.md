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
  dim3 = NULL
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
  (no filtering).

## Value

A [tibble](https://tibble.tidyverse.org/reference/tibble.html) of
indicator observations, or an empty tibble when the service is
unreachable.

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
#> # A tibble: 12,210 × 25
#>        Id IndicatorCode SpatialDimType SpatialDim ParentLocationCode TimeDimType
#>     <int> <chr>         <chr>          <chr>      <chr>              <chr>      
#>  1 5.50e6 NCDMORT3070   COUNTRY        PAK        EMR                YEAR       
#>  2 5.50e6 NCDMORT3070   COUNTRY        VNM        WPR                YEAR       
#>  3 5.50e6 NCDMORT3070   COUNTRY        LCA        AMR                YEAR       
#>  4 5.50e6 NCDMORT3070   COUNTRY        TGO        AFR                YEAR       
#>  5 5.50e6 NCDMORT3070   COUNTRY        COD        AFR                YEAR       
#>  6 5.50e6 NCDMORT3070   COUNTRY        VNM        WPR                YEAR       
#>  7 5.50e6 NCDMORT3070   COUNTRY        COL        AMR                YEAR       
#>  8 5.50e6 NCDMORT3070   COUNTRY        MUS        AFR                YEAR       
#>  9 5.50e6 NCDMORT3070   COUNTRY        NLD        EUR                YEAR       
#> 10 5.50e6 NCDMORT3070   COUNTRY        MWI        AFR                YEAR       
#> # ℹ 12,200 more rows
#> # ℹ 19 more variables: ParentLocation <chr>, Dim1Type <chr>, TimeDim <int>,
#> #   Dim1 <chr>, Dim2Type <chr>, Dim2 <chr>, Dim3Type <lgl>, Dim3 <lgl>,
#> #   DataSourceDimType <lgl>, DataSourceDim <lgl>, Value <chr>,
#> #   NumericValue <dbl>, Low <dbl>, High <dbl>, Comments <chr>, Date <chr>,
#> #   TimeDimensionValue <chr>, TimeDimensionBegin <chr>, TimeDimensionEnd <chr>

# Specific countries and years
gho_data("WHOSIS_000001", area = c("FRA", "DEU"), year_from = 2015)
#> Assuming `spatial_type` = "country" since `area` was given.
#> ℹ Pass `spatial_type` explicitly to silence this message.
#> Fetching:
#> <https://ghoapi.azureedge.net/api/WHOSIS_000001?$filter=SpatialDimType%20eq%20%27COUNTRY%27%20and%20SpatialDim%20in%20%28%27FRA%27%2C%27DEU%27%29%20and%20TimeDim%20ge%202015>
#> # A tibble: 42 × 25
#>        Id IndicatorCode SpatialDimType SpatialDim TimeDimType ParentLocationCode
#>     <int> <chr>         <chr>          <chr>      <chr>       <chr>             
#>  1 5.60e6 WHOSIS_000001 COUNTRY        FRA        YEAR        EUR               
#>  2 5.75e6 WHOSIS_000001 COUNTRY        FRA        YEAR        EUR               
#>  3 5.82e6 WHOSIS_000001 COUNTRY        FRA        YEAR        EUR               
#>  4 6.15e5 WHOSIS_000001 COUNTRY        DEU        YEAR        EUR               
#>  5 7.01e5 WHOSIS_000001 COUNTRY        DEU        YEAR        EUR               
#>  6 1.24e6 WHOSIS_000001 COUNTRY        FRA        YEAR        EUR               
#>  7 1.33e6 WHOSIS_000001 COUNTRY        DEU        YEAR        EUR               
#>  8 1.47e6 WHOSIS_000001 COUNTRY        FRA        YEAR        EUR               
#>  9 1.57e6 WHOSIS_000001 COUNTRY        FRA        YEAR        EUR               
#> 10 1.88e6 WHOSIS_000001 COUNTRY        FRA        YEAR        EUR               
#> # ℹ 32 more rows
#> # ℹ 19 more variables: ParentLocation <chr>, Dim1Type <chr>, Dim1 <chr>,
#> #   TimeDim <int>, Dim2Type <lgl>, Dim2 <lgl>, Dim3Type <lgl>, Dim3 <lgl>,
#> #   DataSourceDimType <lgl>, DataSourceDim <lgl>, Value <chr>,
#> #   NumericValue <dbl>, Low <dbl>, High <dbl>, Comments <lgl>, Date <chr>,
#> #   TimeDimensionValue <chr>, TimeDimensionBegin <chr>, TimeDimensionEnd <chr>

# Keep only the both-sexes breakdown, filtered server-side
gho_data("NCDMORT3070", spatial_type = "country", dim1 = "SEX_BTSX")
#> Fetching:
#> <https://ghoapi.azureedge.net/api/NCDMORT3070?$filter=SpatialDimType%20eq%20%27COUNTRY%27%20and%20Dim1%20in%20%28%27SEX_BTSX%27%29>
#> # A tibble: 4,070 × 25
#>        Id IndicatorCode SpatialDimType SpatialDim ParentLocationCode TimeDimType
#>     <int> <chr>         <chr>          <chr>      <chr>              <chr>      
#>  1 5.50e6 NCDMORT3070   COUNTRY        PAK        EMR                YEAR       
#>  2 5.50e6 NCDMORT3070   COUNTRY        VNM        WPR                YEAR       
#>  3 5.50e6 NCDMORT3070   COUNTRY        COD        AFR                YEAR       
#>  4 5.50e6 NCDMORT3070   COUNTRY        COL        AMR                YEAR       
#>  5 5.50e6 NCDMORT3070   COUNTRY        MUS        AFR                YEAR       
#>  6 5.51e6 NCDMORT3070   COUNTRY        SOM        EMR                YEAR       
#>  7 5.52e6 NCDMORT3070   COUNTRY        NPL        SEAR               YEAR       
#>  8 5.52e6 NCDMORT3070   COUNTRY        TCD        AFR                YEAR       
#>  9 5.52e6 NCDMORT3070   COUNTRY        ZMB        AFR                YEAR       
#> 10 5.52e6 NCDMORT3070   COUNTRY        ECU        AMR                YEAR       
#> # ℹ 4,060 more rows
#> # ℹ 19 more variables: ParentLocation <chr>, Dim1Type <chr>, TimeDim <int>,
#> #   Dim1 <chr>, Dim2Type <chr>, Dim2 <chr>, Dim3Type <lgl>, Dim3 <lgl>,
#> #   DataSourceDimType <lgl>, DataSourceDim <lgl>, Value <chr>,
#> #   NumericValue <dbl>, Low <dbl>, High <dbl>, Comments <chr>, Date <chr>,
#> #   TimeDimensionValue <chr>, TimeDimensionBegin <chr>, TimeDimensionEnd <chr>
# }
```
