# Tidy an SDG Data Frame

Selects, renames, and type-casts the most useful columns from an SDG
observation table returned by
[`sdg_data()`](https://shanlong-who.github.io/DSIR/reference/sdg_data.md),
producing a compact tibble in the **unified DSIR cleaned-indicator
schema** — the same schema produced by
[`gho_clean()`](https://shanlong-who.github.io/DSIR/reference/gho_clean.md),
so the two outputs can be combined directly with
[`bind_indicators()`](https://shanlong-who.github.io/DSIR/reference/bind_indicators.md).

## Usage

``` r
sdg_clean(
  df,
  keep_dimensions = FALSE,
  keep_metadata = FALSE,
  output = c("dsir_data", "tibble")
)
```

## Arguments

- df:

  A data frame returned by
  [`sdg_data()`](https://shanlong-who.github.io/DSIR/reference/sdg_data.md).

- keep_dimensions:

  Logical. Append the named SDG dimensions as character columns? Default
  `FALSE` preserves the 15-column format. With `TRUE`, names are
  converted to snake_case and prefixed with `dim_`, e.g. `Age` becomes
  `dim_age`, `Reporting Type` becomes `dim_reporting_type`, and
  `Type_of_household` becomes `dim_type_of_household`. Codes are kept
  unchanged; absent values remain `NA`. Conflicting names after
  conversion cause an error. No dimensions, total-population codes, or
  GHO component codes are inferred. Use
  [`sdg_dimensions()`](https://shanlong-who.github.io/DSIR/reference/sdg_dimensions.md)
  to look up official codes and labels.

- keep_metadata:

  Logical. Retain observation attributes and source context? Default
  `FALSE`. With `TRUE`, all returned attributes become character columns
  prefixed with `attr_` (e.g. `attr_units`, `attr_nature`). Also appends
  `data_source`, `time_detail`, `time_coverage`, `base_period`,
  `value_type`, and `geo_info_url` as character columns. `footnotes`,
  `indicator_codes`, `goal_codes`, and `target_codes` are list-columns
  of character vectors, preserving all entries rather than just the
  first. Missing scalar fields are `NA`; missing list fields are empty
  character vectors. This option is independent of `keep_dimensions` and
  makes no extra network requests.

- output:

  Return a `"dsir_data"` tibble subclass (default) or a plain
  `"tibble"`. Both carry acquisition and cleaning metadata as
  attributes; inspect them with
  [`dsir_metadata()`](https://shanlong-who.github.io/DSIR/reference/dsir_metadata.md).
  This does not add table columns.

## Value

A
[dsir_data](https://shanlong-who.github.io/DSIR/reference/as_dsir_data.md)
tibble, or a plain tibble when requested, with 15 core columns: `source`
(always `"sdg"`), `id`, `indicator`, `location`, `iso3`,
`location_name`, `year`, `value`, `value_num`, `low`, `high`, `series`,
`dim1` (`NA`), `dim2` (`NA`), `dim3` (`NA`). Sorted by `location` then
`year`. Empty input returns an empty tibble with the same columns and
types. With `keep_dimensions = TRUE`, available named dimensions follow
the core columns, including on zero-row subsets of raw data. With
`keep_metadata = TRUE`, source context follows those columns.

## Details

The mapping (SDG source → unified column) is:

- `indicator` (list-column, flattened) → `id` (e.g. `"3.4.1"`)

- `seriesDescription` → `indicator` (human-readable label; `NA` if the
  API response does not include it)

- `geoAreaCode` → `location` (UN M49 numeric, as character); also `iso3`
  via
  [`m49_to_iso3()`](https://shanlong-who.github.io/DSIR/reference/m49_to_iso3.md)
  for WHO Member States — region / world aggregates and non-Member areas
  get `iso3 = NA`

- `location_name` is resolved by looking up `iso3` against
  [`who_countries`](https://shanlong-who.github.io/DSIR/reference/who_countries.md)
  (so a WHO Member State has the same `location_name` here and in
  [`gho_clean()`](https://shanlong-who.github.io/DSIR/reference/gho_clean.md)
  output), with a fallback to the SDG API's raw `geoAreaName` for
  non-Member-State rows (e.g. regional / world aggregates)

- `timePeriodStart` → `year` (integer)

- `value` → `value` (character; raw) and `value_num` (numeric; `NA` for
  non-numeric entries like `"<0.1"` or aggregate notes)

- `lowerBound`, `upperBound` → `low`, `high` (numeric)

- `series` → `series`

Three columns are always present but never populated for SDG output:
`dim1`, `dim2`, `dim3` (GHO-only positions). SDG uses named dimensions,
potentially more than three, with no general mapping to those positions.
Set `keep_dimensions = TRUE` to retain all observed SDG dimensions as
additional columns. The default compact output omits them, so filter to
the required strata before using it for analysis.

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
[`gho_clean()`](https://shanlong-who.github.io/DSIR/reference/gho_clean.md),
[`bind_indicators()`](https://shanlong-who.github.io/DSIR/reference/bind_indicators.md),
[`sdg_dimensions()`](https://shanlong-who.github.io/DSIR/reference/sdg_dimensions.md),
[`m49_to_iso3()`](https://shanlong-who.github.io/DSIR/reference/m49_to_iso3.md).

## Examples

``` r
# \donttest{
sdg_data("3.2.1", area = "156", year_from = 2015) |>
  sdg_clean(keep_dimensions = TRUE)
# }
```
