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
