# Auditable GHO data snapshots

[`data_snapshot()`](https://shanlong-who.github.io/DSIR/reference/data_snapshot.md)
records an extract that you already have.
[`compare_snapshots()`](https://shanlong-who.github.io/DSIR/reference/compare_snapshots.md)
compares two such extracts without calling an API. The first snapshot
schema supports one GHO indicator and one backend. It does not schedule
queries, maintain a database or automatically rebuild reports. The
existing
[`snapshot()`](https://shanlong-who.github.io/DSIR/reference/snapshot.md)
function remains an expression cache.

The [WHO OData guide](https://www.who.int/data/gho/info/gho-odata-api)
describes dimension and time filters. These helpers retain the supplied
extract rather than fetching another view of the source.

## Start from a complete query

Use raw
[`gho_data()`](https://shanlong-who.github.io/DSIR/reference/gho_data.md)
output so every returned dimension and metadata column is retained.
Repeat the same query with the same backend later. These network
examples are displayed without execution:

``` r

old_data <- gho_data("WHS4_100", spatial_type = "country", area = "PHL",
                     year_from = 2020, backend = "xmart")
data_snapshot(old_data, file = "snapshots/gho_old.rds")

# Later, repeat exactly the same selection.
new_data <- gho_data("WHS4_100", spatial_type = "country", area = "PHL",
                     year_from = 2020, backend = "xmart")
data_snapshot(new_data, file = "snapshots/gho_new.rds")

result <- compare_snapshots("snapshots/gho_old.rds", "snapshots/gho_new.rds")
result$summary
result$modified
```

The legacy backend is also supported; choose it explicitly in both
queries. Explicit backends do not switch providers. A failed or
incomplete retrieval cannot silently replace a good file. Existing paths
cause an error unless `overwrite = TRUE` is explicitly requested.

For cleaned data, use
`gho_clean(data, keep_dimensions = TRUE, keep_metadata = TRUE)`. The
default 15-column cleaned schema does not retain all identity
information and is rejected. Fields discarded before snapshot creation
cannot be recovered. In particular, the snapshot preserves the data
returned by DSIR; it cannot add publication-state or release evidence
absent from the supplied frame.

## A reproducible offline comparison

This synthetic example includes male and female observations for the
same country and year. Matching only country and year would be
ambiguous.

``` r

old_data <- data.frame(
  IndicatorCode = "EXAMPLE", SpatialDimType = "COUNTRY",
  SpatialDim = "PHL", TimeDimType = "YEAR",
  TimeDim = c(2020L, 2020L, 2021L, 2021L),
  Dim1Type = "SEX", Dim1 = rep(c("SEX_MLE", "SEX_FMLE"), 2),
  Dim2Type = "AGEGROUP", Dim2 = "AGEGROUP_YEARS15-49",
  Dim3Type = NA_character_, Dim3 = NA_character_,
  NumericValue = c(10, 12, 20, 22),
  Comments = NA_character_
)
scope <- list(spatial_type = "country", area = "PHL",
              year_from = 2020, year_to = NULL)
old_path <- tempfile(fileext = ".rds")
new_path <- tempfile(fileext = ".rds")
data_snapshot(old_data, old_path, backend = "legacy", scope = scope)
```

An imported frame has no recorded request, so this example declares its
complete scope. `year_to = NULL` means the query has no upper year
limit; an additional year can therefore be an addition under the same
selection.

``` r

# Keep three old observations; omit the female observation from 2021.
new_data <- old_data[1:3, ]
new_data$NumericValue[1] <- 11
new_data$Comments[3] <- "Updated explanatory note"

# Add an observation in a later year.
new_row <- old_data[1, ]
new_row$TimeDim <- 2022L
new_row$NumericValue <- 30
new_data <- rbind(new_data, new_row)
data_snapshot(new_data, new_path, backend = "legacy", scope = scope)

result <- compare_snapshots(old_path, new_path)
result$summary[, c("n_old", "n_new", "n_added", "n_removed", "n_modified",
                  "n_unchanged", "n_value_modified", "n_metadata_only")]
#> # A tibble: 1 × 8
#>   n_old n_new n_added n_removed n_modified n_unchanged n_value_modified
#>   <int> <int>   <int>     <int>      <int>       <int>            <int>
#> 1     4     4       1         1          2           1                1
#> # ℹ 1 more variable: n_metadata_only <int>
result$modified[, c("TimeDim", "Dim1", "old_value", "new_value",
                   "absolute_change", "relative_change", "change_type")]
#> # A tibble: 2 × 7
#>   TimeDim Dim1   old_value new_value absolute_change relative_change change_type
#>     <int> <chr>      <dbl>     <dbl>           <dbl>           <dbl> <chr>      
#> 1    2020 SEX_M…        10        11               1             0.1 value      
#> 2    2021 SEX_M…        20        20               0             0   metadata_o…
```

The result has one added observation, one removed observation, one value
modification, one metadata-only modification, and one unchanged
observation. The historical value changes from 10 to 11, an absolute
change of +1 and a relative change of 0.1 (10%). The primary value
remains 20 for the note-only modification. `modified$changed_fields`
names the fields that changed; `modified$old` and `modified$new` are
data-frame columns retaining the complete old/new tables in the same
order as the modified observations. For example, `modified$old[1, ]`
retrieves the first corresponding old row. `added`, `removed` and
`unchanged` also contain complete observations.

``` r

saved <- readRDS(old_path)
saved$schema_version
#> [1] 1
saved$key
#>  [1] "IndicatorCode"  "SpatialDimType" "SpatialDim"     "TimeDimType"   
#>  [5] "TimeDim"        "Dim1Type"       "Dim1"           "Dim2Type"      
#>  [9] "Dim2"           "Dim3Type"       "Dim3"
identical(saved$data, old_data)
#> [1] TRUE
```

## Identity and compatibility

Default matching includes the indicator, geographical type/code,
temporal type/value, positional dimension type/code pairs, all available
named dimensions, detailed temporal coordinates, unit and measure
family. Legacy data-source dimensions also participate. Record IDs and
provider-reported timestamps are metadata. Duplicate keys or a populated
dimension code without its type cause an error. Add a genuinely
additional semantic dimension through `key`; do not add a row number or
record ID merely to hide duplicates.

The two snapshots must have the same source, backend, indicator, layout,
origin, complete query scope and identity specification. Unit and
measure-family context must also agree. A PHL-only query cannot be
compared with a WPR query as though the additional countries were source
revisions. Raw and cleaned representations must not be mixed.

Recorded scope comes from the existing `who_provenance` request
information. After filtering locally, pass a named `scope` covering
**all** filters. The helper rejects stale row counts when scope is
inferred, but cannot detect local edits that leave row count unchanged.
A declared scope is the caller’s auditable assertion; the helper cannot
verify what a manually imported or edited frame originally represented.
Scope strings are compared conservatively: equivalent requests with
differently written filter expressions may be rejected. Equal keys and
scope do not independently establish scientific equivalence.

## Values, metadata and precision

By default, numeric value, uncertainty bounds and the original display
value are value fields. All other non-key columns are metadata fields. A
changed label, note, service ID or provider timestamp can therefore
produce a metadata-only modification. Snapshot and retrieval times do
not.

NA matches NA; NA versus a known value is a change. Integer/double
numeric representation and JSON’s null-only logical columns are handled
without false changes. Missing optional metadata is treated as missing,
with column additions, removals and type changes also reported in
`schema_changes`. List-note order is preserved. Unsupported non-missing
type conversions stop comparison instead of guessing.

The default numerical tolerance is zero. To compare only numeric values
with a chosen absolute tolerance:

``` r

compare_snapshots(old_path, new_path, fields = "NumericValue",
                  tolerance = 1e-8)$summary$n_modified
#> [1] 1
```

Selecting `fields` restricts which changes count; this example
deliberately ignores the note change. Character display strings are
exact even when numeric values are within tolerance. Absolute change
means signed `new - old`. Relative change is `(new - old) / old`, and is
NA for zero/missing old values or non-finite calculations.

## Four different times and decisions about reports

- **Source modification time:** retain a provider-reported field if
  available. Its semantics may be uncertain. Legacy `Date` and xMart
  system commit dates do not by themselves prove an official observation
  revision or publication.
- **Retrieval time:** when DSIR fetched the extract, if recorded in
  provenance. Creating a snapshot from an older in-memory frame does not
  change that time.
- **Snapshot creation time:** when the RDS wrapper was created,
  explicitly UTC.
- **Latest observation year:** the latest period represented in the
  data. It is not a timestamp for retrieval, creation or revision.

Saved extracts demonstrate differences observed in those extracts. They
cannot establish the exact date or reason for a source revision. To
review an existing report, inspect additions, removals and value
modifications within the countries, periods and dimensions that the
report actually used. Also review metadata-only changes if notes, labels
or annotations appear in outputs. The helpers do not track a report’s
dependencies and make no automatic decision to regenerate it.

Snapshots are plain local RDS files, not a cryptographic audit trail. No
hash is based on serialized bytes: reordering rows does not create a
change. No credentials or environment settings are collected. Check your
own free-text data for sensitive information before saving or sharing a
file.
