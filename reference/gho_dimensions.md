# List Dimensions of a GHO Indicator

Returns the unique values of a given dimension across all observations
of a GHO indicator. Useful for discovering which ages, sexes, regions,
or other breakdowns are available before calling
[`gho_data()`](https://shanlong-who.github.io/DSIR/reference/gho_data.md).

## Usage

``` r
gho_dimensions(indicator, dimension = "SpatialDimType", backend = NULL)
```

## Arguments

- indicator:

  Character scalar. The indicator code (e.g. `"NCDMORT3070"`).

- dimension:

  Character. Name of the dimension column in the indicator data. Common
  values include `"SpatialDim"`, `"SpatialDimType"`, `"TimeDim"`,
  `"Dim1"`, `"Dim2"`, and `"Dim3"`. Case-sensitive (it is sent to the
  server as an OData `$select` field name). xMart also accepts exact
  named fields such as `"DIM_SEX"` or `"DIM_AGE"`. Default
  `"SpatialDimType"`.

- backend:

  Character scalar. `"auto"`, `"xmart"` or `"legacy"`. Default `NULL`
  uses the `DSIR.who_backend` option, or `"auto"` when that option is
  unset. An explicit argument overrides the option for this call without
  changing it. Use the same backend for discovery and retrieval.

## Value

A character vector of unique, sorted dimension values, or an empty
character vector when the service is unreachable or the dimension is
missing.

## Details

Only the requested column is downloaded (via the OData `$select` query
option), so this is a lightweight metadata query even for indicators
with hundreds of thousands of observations. A `dimension` that is not a
column of the GHO data table (e.g. a misspelling) makes the server
reject the request; the failure surfaces as a warning and an empty
character vector.

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

[`gho_data()`](https://shanlong-who.github.io/DSIR/reference/gho_data.md),
[`gho_indicators()`](https://shanlong-who.github.io/DSIR/reference/gho_indicators.md).

## Examples

``` r
# \donttest{
gho_dimensions("NCDMORT3070")
gho_dimensions("NCDMORT3070", dimension = "Dim1")
# }
```
