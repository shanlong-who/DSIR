# Fetch GHO Data

Retrieves observations for a specific indicator from the WHO GHO OData
API, with optional filters by spatial level, country / region and year
range.

## Usage

``` r
gho_data(
  indicator,
  spatial_type = NULL,
  area = NULL,
  year_from = NULL,
  year_to = NULL,
  dim1 = NULL,
  dim2 = NULL,
  dim3 = NULL,
  dimensions = NULL,
  backend = NULL,
  clean = TRUE,
  keep_dimensions = FALSE,
  keep_metadata = FALSE
)
```

## Arguments

- indicator:

  Character scalar. The indicator code (e.g. `"NCDMORT3070"`). Use
  [`gho_indicators()`](https://shanlong-who.github.io/DSIR/reference/gho_indicators.md)
  to find codes.

- spatial_type:

  Character. Spatial dimension to filter on: one of `"country"`,
  `"region"`, `"global"`, or `NULL` (all levels, the default).

- area:

  Character vector of country or region codes (e.g. `c("FRA", "DEU")`).
  Default `NULL` returns all areas.

- year_from:

  Numeric. Start year filter (inclusive). Default `NULL`.

- year_to:

  Numeric. End year filter (inclusive). Default `NULL`.

- dim1, dim2, dim3:

  Character vector of values to keep for the `Dim1` / `Dim2` / `Dim3`
  breakdown columns, filtered server-side (e.g. `dim1 = "SEX_BTSX"` for
  both-sexes rows only, or `dim1 = c("SEX_MLE", "SEX_FMLE")`). The
  meaning of each dimension varies by indicator (`Dim1` is sex for one
  indicator, an age group for another); use
  [`gho_dimensions()`](https://shanlong-who.github.io/DSIR/reference/gho_dimensions.md)
  to discover the values available for a given indicator. Rows where the
  dimension is empty (`null`) are excluded by the filter. Default `NULL`
  (no filtering). On xMart wide tables, positions follow named
  dimensions in the source table schema (sex, age, then alphabetical).
  These positions can differ from the legacy API. Prefer `dimensions`.
  Canonical sex codes and the `AGEGROUP_` namespace remain supported in
  positional filters. Named filters use the provider's exact native
  codes.

- dimensions:

  Optional named list of exact xMart dimension fields and values, e.g.
  `list(DIM_SEX = 'TOTAL')`. Requires xMart; automatic selection never
  translates these filters to legacy.

- backend:

  Character scalar. `"auto"`, `"xmart"` or `"legacy"`. Default `NULL`
  uses the `DSIR.who_backend` option, or `"auto"` when that option is
  unset. An explicit argument overrides the option for this call without
  changing it. Use the same backend for discovery and retrieval.

- clean:

  Logical. Return cleaned observations as a `dsir_data` tibble by
  default. Use `FALSE` for the original observation columns.

- keep_dimensions:

  Logical. Append `dim1_type`, `dim2_type`, and `dim3_type` from the
  source's `Dim1Type`, `Dim2Type`, and `Dim3Type`? Default `FALSE`.
  Types are kept per row: one indicator can use the same position for
  different dimensions. No type is guessed from a code's spelling, and
  missing types remain `NA`. xMart output also retains all named source
  dimensions as `dim_*` character columns.

- keep_metadata:

  Logical. Retain source context? Default `FALSE`. With `TRUE`, appends
  `provider` (`"legacy"` or `"xmart"`) from recorded retrieval
  provenance; unknown origins remain `NA`, never the current session
  setting. Also appends character columns `observation_id`,
  `spatial_type`, `time_type`, `data_source_type`, `data_source`,
  `updated`, `parent_location`, `parent_location_name`, `time_detail`,
  `time_start`, and `time_end`, copied from the raw API fields. Raw
  `Comments` are kept as `footnotes`, a list-column of character
  vectors. Missing scalar fields are `NA`; missing list fields are empty
  character vectors. This option is independent of `keep_dimensions`.
  Unit and dimension labels are not inferred. xMart output also retains
  `unit`, `measure_field`, and `spatial_type_source`. Both backends
  preserve acquisition provenance in the object metadata, including with
  the default 15-column output. Plain tibble output also keeps
  `who_provenance`. Retaining these fields makes no extra network
  requests beyond the usual indicator-name lookup.

## Value

A cleaned
[dsir_data](https://shanlong-who.github.io/DSIR/reference/as_dsir_data.md)
table, or the raw observation tibble with `clean = FALSE`. Empty cleaned
results have the same core schema. The raw `Provider` column records
`"legacy"` or `"xmart"` per row. Raw output stores the selected backend
in `who_provenance`. For cleaned output, use
`dsir_metadata(x)$provenance$retrieval`. Successful downloads also
record the request context and retrieval time. Automatic queries also
record `requested_backend = "auto"` and, when fallback is attempted,
`fallback_reason` (`"directory_not_listed"` or `"indicator_empty"`). The
same selection metadata is attached to automatic counts, availability,
coverage, dimension and timestamp results, including scalar results.
Failed selection records the attempted xMart backend.

## Details

Since 0.13.0, automatic selection prefers the public WHO xMart service.
It first checks the directory and, for a listed code, requests at most
one observation with a row count for the entire indicator, before
applying user filters. Only a code absent from a successfully read,
non-empty directory or a verified zero-row indicator can trigger legacy
fallback. This adds a small availability request to each automatic
indicator query; that decision is not cached. An HTTP/transport/parsing
failure, unsupported schema/route, or a valid empty filtered result
never triggers fallback. Partial xMart coverage is not filled from
legacy. Each call uses a single provider.

Fallback warns and preserves country/region and year filters. It
requires known WHO ISO3 or region codes. M49/native area codes, named
dimensions and positional `dim1`-`dim3` filters block automatic fallback
because equivalent interpretation cannot be guaranteed. For dimension
discovery, only `SpatialDim`, `SpatialDimType`, `TimeDim` and
`TimeDimType` allow fallback. Incompatible fallback warns and returns
the operation's failed empty/NA result without dropping any filters.
Select a provider explicitly to use its own dimension and geography
conventions.

Explicit `backend = "xmart"` or `"legacy"` fixes the provider and avoids
the automatic availability request. `gho_indicators(backend = "auto")`
searches the xMart catalog only. GHE always uses xMart.
`DSIR.who_base_url` selects another compatible HTTPS xMart origin.
Public directory coverage differs from the legacy catalog, and published
estimates can differ. Unknown xMart directory codes warn; legacy HTTP
404 responses are checked against its directory before being classified
as absent codes. A successful query with no matching observations emits
an informational message. Request or parsing failures warn, and do not
establish that no data exist. Reference lookups are cached only in
memory; no credentials or startup requests are required.

## Retrieval metadata

Raw downloads and directories carry acquisition records. GHO and SDG
observation downloads also carry cleaning records unless
`clean = FALSE`. `dsir_metadata(x)$sources` records the actual backend,
endpoint, UTC `retrieved_at`, retrieval status, cache use, source record
count, reported API version and release. Unknown versions and times
remain `NA`. Each source row includes its own server query. `query`
records the public selection, including local filters and
reference-country/year restrictions. `result` describes the function's
original return; `current` is computed from the supplied object. Source
counts precede local filtering and GHE measure pivoting, so they can
differ from returned row counts.

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
missing count and its constant value, if any. From 0.15.0,
`cleaning$dimension_values` stores the distinct observed codes for each
named dimension at cleaning time. Per-row membership is available only
for retained dimensions. Recorded aliases link equivalent core and named
dimensions. Cleaning time never substitutes for retrieval time. These
records describe the cleaning input; current coverage and subsequent
field status remain separate.

## See also

[`gho_indicators()`](https://shanlong-who.github.io/DSIR/reference/gho_indicators.md),
[`gho_dimensions()`](https://shanlong-who.github.io/DSIR/reference/gho_dimensions.md).

## Examples

``` r
# \donttest{
# Country-level data for one indicator
gho_data("NCDMORT3070", spatial_type = "country")

# Specific countries and years
gho_data("WHOSIS_000001", area = c("FRA", "DEU"), year_from = 2015)

# Keep only the both-sexes breakdown, filtered server-side
gho_data("NCDMORT3070", spatial_type = "country", dim1 = "SEX_BTSX")

# Select xMart for one call without changing the session default
gho_data("NCDMORT3070", area = "PHL", year_from = 2020, year_to = 2021,
         dimensions = list(DIM_SEX = "TOTAL"), backend = "xmart")
# }
```
