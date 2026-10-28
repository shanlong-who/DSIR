# Save GHO Observations as an Auditable Data Snapshot

Wraps an already retrieved GHO data frame with its identity, query
context and creation time. It makes no network requests and never fills,
rounds, aggregates or otherwise changes observations.

## Usage

``` r
data_snapshot(
  data,
  file = NULL,
  source = NULL,
  indicator = NULL,
  backend = NULL,
  scope = NULL,
  key = NULL,
  value_fields = NULL,
  overwrite = FALSE
)
```

## Arguments

- data:

  A data frame returned by
  [`gho_data()`](https://shanlong-who.github.io/DSIR/reference/gho_data.md),
  or by `gho_clean(..., keep_dimensions = TRUE, keep_metadata = TRUE)`.
  The default 15-column cleaned output has insufficient identity
  context. The first schema supports one GHO indicator and one backend
  per snapshot.

- file:

  Optional local RDS path. Parent directories are created as needed.
  With `NULL`, return an in-memory snapshot without writing a file.

- source:

  Optional source identifier. Currently only `"gho"` is supported.
  Recorded source information must agree with this argument.

- indicator:

  Optional indicator code, normally read from the data. Supply it for an
  explicitly declared, empty selection.

- backend:

  Optional `"legacy"` or `"xmart"`, normally read from `Provider` /
  `provider` or `who_provenance`. Session options are never used to
  guess an imported data frame's origin.

- scope:

  Optional, non-empty named list describing the complete query and any
  local filtering, for example
  `list(area = "PHL", year_from = 2020, year_to = NULL)`. Names and sets
  of values are canonicalized for comparison. With `NULL`, use the
  recorded request URL or xMart table/filter from a complete DSIR
  retrieval whose recorded row count still matches `data`. After local
  subsetting, supply an explicit scope; do not infer query limits from
  observed coverage.

- key:

  Optional additional semantic identity columns. Required GHO identity
  and dimension columns are always included. This argument can resolve a
  genuinely additional dimension, not hide duplicate observations.

- value_fields:

  Optional fields classified as values. Defaults to numeric value,
  bounds and the original display value, when present. The primary
  numeric field is always required.

- overwrite:

  Logical. Replace an existing file? Default `FALSE`.

## Value

The snapshot, invisibly when written to `file` and visibly otherwise.

## Details

The result is an ordinary R list, classed `dsir_data_snapshot`, with
`schema_version = 1L`, `created_at` (UTC POSIXct), `source`, `backend`,
`indicator`, `layout`, `origin`, `scope`, `provenance`, `retrieved_at`,
`source_timestamp_fields`, `key`, `value_fields`, `primary_value`,
`context_fields` and the complete, unmodified `data` frame. Read a saved
snapshot with [`readRDS()`](https://rdrr.io/r/base/readRDS.html). This
is distinct from
[`snapshot()`](https://shanlong-who.github.io/DSIR/reference/snapshot.md),
which caches an expression and returns its value without this comparison
contract.

Default identity includes indicator, geographical type/code, temporal
type/value, all positional dimension type/code pairs and every named
`DIM_*` (or cleaned `dim_*`) column. Available detailed time
coordinates, unit and measure family also participate. A legacy
data-source dimension is identity; xMart's free-text source provenance
is metadata. Row numbers, service record IDs and modification timestamps
are not matching keys. Duplicate keys, untyped active dimensions and
missing core identifiers are errors. An inactive dimension may have both
type and code missing.

Four different times must remain separate:

- Source modification time: a provider-reported field, if supplied.
  `Date` / `updated` is preserved verbatim. Its presence does not
  establish an authoritative observation revision time; xMart system
  commits can reflect processing.

- Retrieval time: the original DSIR `who_provenance$retrieved` string
  (recorded in UTC by the clients), or `NA` when unavailable.

- Snapshot creation time: when this wrapper was made, explicitly UTC.

- Latest observation year: a property of the data, never an update time.

Only information present in the supplied frame and declared arguments is
recorded. No credentials, environment variables, session options or HTTP
request objects are collected. Credential-like field names,
authenticated URLs and unsupported objects are rejected. Callers remain
responsible for checking their own free-text observations and metadata
before saving.

A declared scope is an auditable caller assertion, not proof of
completeness. Local edits that preserve the original row count cannot be
detected from provenance alone. Always declare a new scope after
changing selection. Snapshots record what DSIR returned; fields already
discarded upstream or by a cleaner cannot be recovered. No content hash
is used: comparison operates on keys and values rather than R
serialization bytes.

## See also

[`compare_snapshots()`](https://shanlong-who.github.io/DSIR/reference/compare_snapshots.md),
[`snapshot()`](https://shanlong-who.github.io/DSIR/reference/snapshot.md),
[`gho_data()`](https://shanlong-who.github.io/DSIR/reference/gho_data.md),
[`gho_last_updated()`](https://shanlong-who.github.io/DSIR/reference/gho_last_updated.md).

## Examples

``` r
x <- data.frame(
  IndicatorCode = "EXAMPLE", SpatialDimType = "COUNTRY",
  SpatialDim = "PHL", TimeDimType = "YEAR", TimeDim = 2020L,
  Dim1Type = "SEX", Dim1 = "SEX_BTSX",
  Dim2Type = NA_character_, Dim2 = NA_character_,
  Dim3Type = NA_character_, Dim3 = NA_character_, NumericValue = 10
)
old <- data_snapshot(x, backend = "legacy",
                     scope = list(area = "PHL", year_from = 2020))
x$NumericValue <- 12
new <- data_snapshot(x, backend = "legacy",
                     scope = list(area = "PHL", year_from = 2020))
compare_snapshots(old, new)$modified

if (FALSE) { # \dontrun{
old_data <- gho_data("WHS4_100")
data_snapshot(old_data, file = "snapshots/gho_old.rds")

# Later, repeat exactly the same query using the same backend.
new_data <- gho_data("WHS4_100")
data_snapshot(new_data, file = "snapshots/gho_new.rds")
result <- compare_snapshots("snapshots/gho_old.rds",
                            "snapshots/gho_new.rds")
result$summary
result$modified
} # }
```
