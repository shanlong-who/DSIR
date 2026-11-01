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

## Retrieval metadata

Downloads and directories retain their existing classes and columns.
`dsir_metadata(x)$sources` records the actual backend, endpoint, UTC
`retrieved_at`, retrieval status, cache use, source record count,
reported API version and release. Unknown versions and times remain
`NA`. Each source row includes its own server query. `query` records the
public selection, including local filters and reference-country/year
restrictions. `result` describes the function's original return;
`current` is computed from the supplied object. Source counts precede
local filtering and GHE measure pivoting, so they can differ from
returned row counts.

Result status distinguishes `success`, `empty`, `failed`, `incomplete`,
`invalid`, `partial` and `unverified`. Completeness concerns the
requested retrieval, not global indicator coverage. It is `NA` when the
response lacks sufficient completeness information. A successful HTTP
response alone does not establish completeness of an observation
download.

Cached records retain their original retrieval time and set `cache_hit`.
A historical fallback uses `retrieval_status = "bundled_snapshot"` and
retains the original collection date. It does not prove live
availability. Failed SDG list requests still return `NULL` with a
warning; `NULL` cannot carry metadata. Other empty failure results
record no successful retrieval time. Existing WHO `who_provenance` and
`catalog_snapshot` attributes remain available for compatibility.

Cleaners preserve acquisition metadata even for empty input. This is
independent of `keep_metadata`, which controls optional data columns.
[`as_dsir_data()`](https://shanlong-who.github.io/DSIR/reference/as_dsir_data.md)
also retains `sources`, `query` and `result`. These are historical
acquisition records, not an audit of arbitrary changes to a plain
tibble. Use the S3 object's processing status to track supported
transformations. [`saveRDS()`](https://rdrr.io/r/base/readRDS.html)
preserves attributes; CSV does not.

Cleaning records live in `cleaning`, also for `output = "tibble"` and
user-supplied input without acquisition records. They contain the
cleaner, package version, UTC cleaning time, input/output sizes and
columns, options, and a profile of semantic fields. Each profile records
its retained column (or `NA`), distinct count including missing values,
missing count and its constant value, if any. Varying omitted values are
not stored row by row. Recorded aliases link equivalent core and named
dimensions. Cleaning time never substitutes for retrieval time. These
records describe the cleaning input; current coverage and subsequent
field status remain separate.

## See also

[`sdg_targets()`](https://shanlong-who.github.io/DSIR/reference/sdg_targets.md),
[`sdg_data()`](https://shanlong-who.github.io/DSIR/reference/sdg_data.md).

## Examples

``` r
# \donttest{
# Full list
sdg_indicators()

# Single keyword
sdg_indicators("mortality")

# Multi-keyword — AND semantics
sdg_indicators("mortality cancer")
sdg_indicators(c("maternal", "mortality"))
# }
```
