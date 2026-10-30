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
columns `IndicatorCode`, `IndicatorName` and `Language`. On a legacy
request or parsing failure, searches a bundled catalog snapshot and
warns with its collection date. The `catalog_snapshot` attribute records
its `backend`, `source` URL and `retrieved` UTC time. The xMart backend
still returns an empty tibble with a warning when its service is
unreachable.

## Details

Online results are preferred. The bundled legacy catalog is refreshed
with package releases and may omit new indicators or contain outdated
names and codes. It is used only after a failed or malformed response,
not after a successful search with no matches. Fallback searches
preserve literal, case-insensitive AND matching on indicator names;
abbreviations such as `"SCI"` are not expanded to
`"Service Coverage Index"`.

The snapshot is not used for xMart or to verify observation
availability. Downloading observations still requires a working online
service. Snapshot results are not cached as a successful online catalog,
so later calls can retry. Rebuild the snapshot using
`data-raw/gho_indicators.R` in the source repository before a package
release.

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
