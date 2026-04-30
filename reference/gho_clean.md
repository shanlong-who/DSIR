# Tidy a GHO Data Frame

Selects and renames the most useful columns from a GHO observation table
returned by
[`gho_data()`](https://shanlong-who.github.io/DSIR/reference/gho_data.md),
producing a compact tibble suitable for downstream analysis.

## Usage

``` r
gho_clean(df)
```

## Arguments

- df:

  A data frame returned by
  [`gho_data()`](https://shanlong-who.github.io/DSIR/reference/gho_data.md).

## Value

A [tibble](https://tibble.tidyverse.org/reference/tibble.html) with
columns `indicator`, `location`, `year`, `dim1`, `dim2`, `dim3`,
`value`, `low`, `high`, sorted by `location` then `year`. An empty input
returns an empty tibble with the same columns.

## Details

The mapping is:

- `IndicatorCode` -\> `indicator`

- `SpatialDim` -\> `location`

- `TimeDim` -\> `year`

- `Dim1`, `Dim2`, `Dim3` -\> `dim1`, `dim2`, `dim3`

- `NumericValue` -\> `value`

- `Low`, `High` -\> `low`, `high`

Source columns that are absent from `df` (for example `Low` / `High` on
indicators without confidence intervals) are filled with `NA`, so the
output always has the same nine columns.

## See also

[`gho_data()`](https://shanlong-who.github.io/DSIR/reference/gho_data.md).

## Examples

``` r
if (FALSE) { # \dontrun{
gho_data("NCDMORT3070", spatial_type = "country") |>
  gho_clean()
} # }
```
