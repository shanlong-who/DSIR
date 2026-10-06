# Check Whether a GHO Indicator Has Data for a Filter

Sends a minimal request (`$top=1` with a row count) to the WHO GHO OData
API to find out whether any observations exist for the given indicator
and filter combination, without downloading the full result set. Useful
as a quick precheck before
[`gho_data()`](https://shanlong-who.github.io/DSIR/reference/gho_data.md).

## Usage

``` r
gho_has_data(
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

A logical scalar:

- `TRUE` if at least one observation exists for the filter.

- `FALSE` if the server returns an empty result.

- `NA` if the request fails (network failure, unreachable host, or the
  indicator code does not exist and the server returns an HTTP error). A
  warning is emitted in the failure case.

## See also

[`gho_data()`](https://shanlong-who.github.io/DSIR/reference/gho_data.md),
[`gho_count()`](https://shanlong-who.github.io/DSIR/reference/gho_count.md),
[`gho_coverage()`](https://shanlong-who.github.io/DSIR/reference/gho_coverage.md).

## Examples

``` r
# \donttest{
# Does WHO have life-expectancy data for France?
gho_has_data("WHOSIS_000001", area = "FRA")
#> Assuming `spatial_type` = "country" since `area` was given.
#> Fetching WHO: "DATA_/RELAY_WHS"
#> [1] TRUE

# Quickly screen a list of indicators before downloading any data
inds <- c("WHOSIS_000001", "NCDMORT3070")
vapply(inds, gho_has_data, logical(1), area = "FRA")
#> Assuming `spatial_type` = "country" since `area` was given.
#> Fetching WHO: "DATA_/RELAY_WHS"
#> Assuming `spatial_type` = "country" since `area` was given.
#> Fetching WHO: "DATA_/RELAY_WHS"
#> WHOSIS_000001   NCDMORT3070 
#>          TRUE          TRUE 
# }
```
