# List Dimensions of a GHO Indicator

Returns the unique values of a given dimension across all observations
of a GHO indicator. Useful for discovering which ages, sexes, regions,
or other breakdowns are available before calling
[`gho_data()`](https://shanlong-who.github.io/DSIR/reference/gho_data.md).

## Usage

``` r
gho_dimensions(indicator, dimension = "SpatialDimType")
```

## Arguments

- indicator:

  Character scalar. The indicator code (e.g. `"NCDMORT3070"`).

- dimension:

  Character. Name of the dimension column in the indicator data. Common
  values include `"SpatialDim"`, `"SpatialDimType"`, `"TimeDim"`,
  `"Dim1"`, `"Dim2"`, and `"Dim3"`. Default `"SpatialDimType"`.

## Value

A character vector of unique, sorted dimension values, or an empty
character vector when the service is unreachable or the dimension is
missing.

## See also

[`gho_data()`](https://shanlong-who.github.io/DSIR/reference/gho_data.md),
[`gho_indicators()`](https://shanlong-who.github.io/DSIR/reference/gho_indicators.md).

## Examples

``` r
if (FALSE) { # \dontrun{
gho_dimensions("NCDMORT3070")
gho_dimensions("NCDMORT3070", dimension = "Dim1")
} # }
```
