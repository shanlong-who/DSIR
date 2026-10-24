# List SDG Dimension Codes and Labels

Retrieves the official code lists for each series linked to an SDG
indicator, without downloading its observations. These are available
categories, not evidence that every category occurs in every country's
data. Inspect `unique(df$dimensions)` after
[`sdg_data()`](https://shanlong-who.github.io/DSIR/reference/sdg_data.md)
to see observed strata. Use the `code` column for filters; `sdmx` is an
alternative representation and may differ from the JSON API's
observation codes.

## Usage

``` r
sdg_dimensions(indicator, series = NULL, include_attributes = FALSE)
```

## Arguments

- indicator:

  A single SDG indicator code, e.g. `"3.8.2"`.

- series:

  Optional character vector of series codes linked to the indicator.
  Default `NULL` retrieves all its series.

- include_attributes:

  Logical. Also return attribute code lists, including units and data
  nature? Default `FALSE`.

## Value

A tibble with character columns `indicator`, `series`, `kind`
(`"dimension"` or `"attribute"`), `dimension` (the original field name),
`code`, `label`, and `sdmx`. Missing source labels stay `NA`. Sorted by
series, kind, dimension, and code. If any required request fails or its
structure is invalid, warns and returns a typed empty tibble instead of
a partial code list.

## See also

[`sdg_data()`](https://shanlong-who.github.io/DSIR/reference/sdg_data.md),
[`sdg_clean()`](https://shanlong-who.github.io/DSIR/reference/sdg_clean.md),
[`sdg_indicators()`](https://shanlong-who.github.io/DSIR/reference/sdg_indicators.md).

## Examples

``` r
# \donttest{
sdg_dimensions("3.8.2")
sdg_dimensions("3.8.2", include_attributes = TRUE)
# }
```
