# Explore Global Health Estimates Dimensions

Retrieves official references and small, filtered code-list slices from
WHO's public xMart GHE table. Results are cached in memory for ten
minutes.

## Usage

``` r
ghe_dimensions(dimension = "measure")
```

## Arguments

- dimension:

  One of `"area"`, `"year"`, `"sex"`, `"age"`, `"cause"`, or
  `"measure"`. Default `"measure"`.

## Value

A tibble of `code` and `label`. Cause results include hierarchy fields.
Measures include their provider field and unit. Missing official labels
remain `NA`. Countries, ages and causes describe the latest GHE year;
use
[`ghe_coverage()`](https://shanlong-who.github.io/DSIR/reference/ghe_coverage.md)
to verify a specific selection.

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

## See also

[`ghe_data()`](https://shanlong-who.github.io/DSIR/reference/ghe_data.md),
[`ghe_causes()`](https://shanlong-who.github.io/DSIR/reference/ghe_causes.md),
[`ghe_coverage()`](https://shanlong-who.github.io/DSIR/reference/ghe_coverage.md)

## Examples

``` r
# \donttest{
ghe_dimensions('sex')
ghe_dimensions('age')
ghe_dimensions('measure')
# }
```
