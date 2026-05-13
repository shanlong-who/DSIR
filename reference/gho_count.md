# Count Observations for a GHO Indicator Filter

Sends a `$top=0&$count=true` request to the WHO GHO OData API, which
returns the matching row count without transferring any observations.
Useful for sizing a download before issuing it.

## Usage

``` r
gho_count(
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

An integer scalar — the number of observations the server would return
for the same filter via
[`gho_data()`](https://shanlong-who.github.io/DSIR/reference/gho_data.md).
Returns `NA_integer_` (with a warning) if the request fails.

## See also

[`gho_data()`](https://shanlong-who.github.io/DSIR/reference/gho_data.md),
[`gho_has_data()`](https://shanlong-who.github.io/DSIR/reference/gho_has_data.md),
[`gho_coverage()`](https://shanlong-who.github.io/DSIR/reference/gho_coverage.md).

## Examples

``` r
# \donttest{
# How many rows would gho_data() pull for France?
gho_count("WHOSIS_000001", area = "FRA")
#> Assuming `spatial_type` = "country" since `area` was given.
#> ℹ Pass `spatial_type` explicitly to silence this message.
#> Fetching:
#> <https://ghoapi.azureedge.net/api/WHOSIS_000001?$filter=SpatialDimType%20eq%20%27COUNTRY%27%20and%20SpatialDim%20in%20%28%27FRA%27%29&$top=0&$count=true>
#> [1] 66

# Compare coverage across regions
gho_count("NCDMORT3070", spatial_type = "country")
#> Fetching:
#> <https://ghoapi.azureedge.net/api/NCDMORT3070?$filter=SpatialDimType%20eq%20%27COUNTRY%27&$top=0&$count=true>
#> [1] 12210
gho_count("NCDMORT3070", spatial_type = "region")
#> Fetching:
#> <https://ghoapi.azureedge.net/api/NCDMORT3070?$filter=SpatialDimType%20eq%20%27REGION%27&$top=0&$count=true>
#> [1] 396
# }
```
