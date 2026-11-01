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

  Character scalar. `"auto"`, `"xmart"` or `"legacy"`. Default `NULL`
  uses the `DSIR.who_backend` option, or `"auto"` when that option is
  unset. An explicit argument overrides the option for this call without
  changing it. Use the same backend for discovery and retrieval.

## Value

A [tibble](https://tibble.tidyverse.org/reference/tibble.html) with
columns `IndicatorCode`, `IndicatorName` and `Language`. On a legacy
request or parsing failure, searches a bundled catalog snapshot and
warns with its collection date. The `catalog_snapshot` attribute records
its `backend`, `source` URL and `retrieved` UTC time. The xMart backend
still returns an empty tibble with a warning when its service is
unreachable.

## Details

With `backend = "auto"`, discovery searches the xMart directory only. A
keyword search cannot prove that an individual indicator is absent. Use
`backend = "legacy"` to inspect legacy-only codes or use the bundled
legacy catalog during an outage. Neither an empty xMart search nor an
xMart request failure switches the catalog source.

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
