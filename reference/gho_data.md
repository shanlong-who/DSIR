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
  year_to = NULL
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
#>  1 9.12e6 NCDMORT3070   COUNTRY        AFG        EMR                YEAR       
#>  2 9.12e6 NCDMORT3070   COUNTRY        JAM        AMR                YEAR       
#>  3 9.13e6 NCDMORT3070   COUNTRY        PRY        AMR                YEAR       
#>  4 9.13e6 NCDMORT3070   COUNTRY        SWE        EUR                YEAR       
#>  5 9.13e6 NCDMORT3070   COUNTRY        HRV        EUR                YEAR       
#>  6 9.13e6 NCDMORT3070   COUNTRY        MDV        SEAR               YEAR       
#>  7 9.13e6 NCDMORT3070   COUNTRY        ERI        AFR                YEAR       
#>  8 9.14e6 NCDMORT3070   COUNTRY        AFG        EMR                YEAR       
#>  9 9.14e6 NCDMORT3070   COUNTRY        COG        AFR                YEAR       
#> 10 9.14e6 NCDMORT3070   COUNTRY        BRB        AMR                YEAR       
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
#>  1 9.42e6 WHOSIS_000001 COUNTRY        DEU        YEAR        EUR               
#>  2 9.86e6 WHOSIS_000001 COUNTRY        DEU        YEAR        EUR               
#>  3 2.05e5 WHOSIS_000001 COUNTRY        DEU        YEAR        EUR               
#>  4 2.96e5 WHOSIS_000001 COUNTRY        DEU        YEAR        EUR               
#>  5 8.63e5 WHOSIS_000001 COUNTRY        FRA        YEAR        EUR               
#>  6 9.58e5 WHOSIS_000001 COUNTRY        DEU        YEAR        EUR               
#>  7 1.11e6 WHOSIS_000001 COUNTRY        FRA        YEAR        EUR               
#>  8 1.21e6 WHOSIS_000001 COUNTRY        FRA        YEAR        EUR               
#>  9 1.54e6 WHOSIS_000001 COUNTRY        FRA        YEAR        EUR               
#> 10 1.54e6 WHOSIS_000001 COUNTRY        DEU        YEAR        EUR               
#> # ℹ 32 more rows
#> # ℹ 19 more variables: ParentLocation <chr>, Dim1Type <chr>, Dim1 <chr>,
#> #   TimeDim <int>, Dim2Type <lgl>, Dim2 <lgl>, Dim3Type <lgl>, Dim3 <lgl>,
#> #   DataSourceDimType <lgl>, DataSourceDim <lgl>, Value <chr>,
#> #   NumericValue <dbl>, Low <dbl>, High <dbl>, Comments <lgl>, Date <chr>,
#> #   TimeDimensionValue <chr>, TimeDimensionBegin <chr>, TimeDimensionEnd <chr>
# }
```
