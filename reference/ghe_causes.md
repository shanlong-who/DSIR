# Explore Global Health Estimates Causes

Lists causes from an all-age, both-sex reference slice in the latest GHE
year. The reference country is the first available WHO Member State in
ISO3 order. This avoids grouping the full database. Codes are exact
download identifiers; selection coverage still needs
[`ghe_coverage()`](https://shanlong-who.github.io/DSIR/reference/ghe_coverage.md).

## Usage

``` r
ghe_causes(search = NULL)
```

## Arguments

- search:

  Optional words matched against cause names, ignoring case. All terms
  must match; a single string is split on whitespace.

## Value

A tibble with `cause_code`, `cause_name`, `level`, `cause_group`,
`rankable`, and `single_cause`. The provider has no parent-code field;
`cause_group` is retained as published and is not a parent identifier.

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

[`ghe_data()`](https://shanlong-who.github.io/DSIR/reference/ghe_data.md),
[`ghe_dimensions()`](https://shanlong-who.github.io/DSIR/reference/ghe_dimensions.md)

## Examples

``` r
# \donttest{
ghe_causes('diabetes')
ghe_causes('stroke')
# }
```
