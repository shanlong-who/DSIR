# List GHO Indicators

Fetches the catalog of indicators from the WHO Global Health Observatory
(GHO) OData API.

## Usage

``` r
gho_indicators(search = NULL)
```

## Arguments

- search:

  Optional character string. If supplied, only indicators whose name
  contains `search` (case-insensitive) are returned.

## Value

A [tibble](https://tibble.tidyverse.org/reference/tibble.html) with
columns `IndicatorCode`, `IndicatorName` and `Language`. Returns an
empty tibble (with a message) when the service is unreachable.

## See also

[`gho_data()`](https://shanlong-who.github.io/DSIR/reference/gho_data.md),
[`gho_dimensions()`](https://shanlong-who.github.io/DSIR/reference/gho_dimensions.md).

## Examples

``` r
if (FALSE) { # \dontrun{
# All indicators
inds <- gho_indicators()

# Search by keyword
gho_indicators("mortality")
} # }
```
