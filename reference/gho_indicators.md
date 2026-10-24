# List GHO Indicators

Fetches the catalog of indicators from the WHO Global Health Observatory
(GHO) OData API.

## Usage

``` r
gho_indicators(search = NULL, backend = NULL)
```

## Arguments

- search:

  Optional character. Search keywords matched against `IndicatorName`
  (case-insensitive). All terms must match (AND semantics). Accepts
  either:

  - a single string, which is split on whitespace into terms (e.g.
    `"child mortality"` matches indicators containing both "child" and
    "mortality"), or

  - a character vector, whose elements are used as terms verbatim
    (whitespace inside an element is treated as part of the term).

  Search terms are matched literally; they are not download identifiers.

- backend:

  Character scalar. `"legacy"` or `"xmart"`. Default `NULL` uses the
  `DSIR.who_backend` option, or `"legacy"` when that option is unset. An
  explicit argument overrides the option for this call without changing
  it. Use the same backend for discovery and retrieval.

## Value

A [tibble](https://tibble.tidyverse.org/reference/tibble.html) with
columns `IndicatorCode`, `IndicatorName` and `Language`. Returns an
empty tibble (with a warning) when the service is unreachable.

## See also

[`gho_data()`](https://shanlong-who.github.io/DSIR/reference/gho_data.md),
[`gho_dimensions()`](https://shanlong-who.github.io/DSIR/reference/gho_dimensions.md).

## Examples

``` r
# \donttest{
# All indicators
inds <- gho_indicators()

# Single keyword
gho_indicators("mortality")

# Multiple keywords from one string (AND): both terms must appear
gho_indicators("child mortality")

# Or pass terms as a vector
gho_indicators(c("child", "mortality"))
# }
```
