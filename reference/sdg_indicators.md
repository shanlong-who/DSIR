# List SDG Indicators

Fetches the list of SDG indicators from the UN SDG API, with optional
keyword filtering on the indicator description.

## Usage

``` r
sdg_indicators(search = NULL)
```

## Arguments

- search:

  Optional character. Search keywords matched against the `description`
  column (case-insensitive). All terms must match (AND semantics).
  Accepts either:

  - a single string, which is split on whitespace into terms (e.g.
    `"mortality cancer"` keeps rows whose description contains both
    "mortality" and "cancer"), or

  - a character vector, whose elements are used as terms verbatim (so a
    term may itself contain whitespace, e.g.
    `c("mortality rate", "attributed")`).

  The filter is applied client-side using
  [`grepl()`](https://rdrr.io/r/base/grep.html) with `fixed = TRUE`
  because the UN SDG `/Indicator/List` endpoint is not OData and exposes
  no server-side search parameter; the full list is small (~250 rows) so
  this is cheap.

## Value

A list (or [tibble](https://tibble.tidyverse.org/reference/tibble.html))
of SDG indicators, or `NULL` when the service is unreachable. When
`search` matches no rows, an empty tibble with the same columns as the
unfiltered response is returned.

## See also

[`sdg_targets()`](https://shanlong-who.github.io/DSIR/reference/sdg_targets.md),
[`sdg_data()`](https://shanlong-who.github.io/DSIR/reference/sdg_data.md).

## Examples

``` r
if (FALSE) { # \dontrun{
# Full list
sdg_indicators()

# Single keyword
sdg_indicators("mortality")

# Multi-keyword — AND semantics
sdg_indicators("mortality cancer")
sdg_indicators(c("maternal", "mortality"))
} # }
```
