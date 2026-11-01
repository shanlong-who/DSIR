# List SDG Goals

Fetches the list of Sustainable Development Goals from the UN SDG API.

## Usage

``` r
sdg_goals(include_children = FALSE)
```

## Arguments

- include_children:

  Logical. Include targets and indicators nested under each goal?
  Default `FALSE`.

## Value

A list (or [tibble](https://tibble.tidyverse.org/reference/tibble.html))
of SDG goals, or `NULL` when the service is unreachable.

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
[`sdg_indicators()`](https://shanlong-who.github.io/DSIR/reference/sdg_indicators.md),
[`sdg_data()`](https://shanlong-who.github.io/DSIR/reference/sdg_data.md).

## Examples

``` r
# \donttest{
sdg_goals()
sdg_goals(include_children = TRUE)
# }
```
