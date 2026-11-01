# Put GHE Estimates in the Unified DSIR Schema

Converts
[`ghe_data()`](https://shanlong-who.github.io/DSIR/reference/ghe_data.md)
output for
[`bind_indicators()`](https://shanlong-who.github.io/DSIR/reference/bind_indicators.md).
A GHE cause is `id`, the selected measure is `series`, sex is `dim1`,
and age is `dim2`. Use `keep_dimensions = TRUE` to retain named sex/age,
cause hierarchy and unit, preventing information loss when combining
multiple measures.

## Usage

``` r
ghe_clean(df, keep_dimensions = FALSE, output = c("dsir_data", "tibble"))
```

## Arguments

- df:

  A data frame from
  [`ghe_data()`](https://shanlong-who.github.io/DSIR/reference/ghe_data.md).

- keep_dimensions:

  Append `dim_sex`, `dim_age`, `cause_name`, `cause_group`,
  `cause_level`, `rankable`, `unit`, and `population`? Default `FALSE`
  keeps the 15-column core.

- output:

  Return a `"dsir_data"` tibble subclass (default) or a plain
  `"tibble"`. Both carry acquisition and cleaning metadata as
  attributes; inspect them with
  [`dsir_metadata()`](https://shanlong-who.github.io/DSIR/reference/dsir_metadata.md).
  This does not add table columns.

## Value

A
[dsir_data](https://shanlong-who.github.io/DSIR/reference/as_dsir_data.md)
tibble in the unified schema, with `source = "ghe"`, or a plain tibble
when `output = "tibble"`.

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

## Examples

``` r
# \donttest{
ghe_data('PHL', year = 2023, age = 'TOTAL', sex = 'TOTAL', cause = 0,
         measure = 'deaths') |> ghe_clean(keep_dimensions = TRUE)
# }
```
