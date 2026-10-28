# Compare Two Local GHO Data Snapshots

Matches observations by their full semantic key and reports additions,
removals, value changes and metadata changes. Everything runs offline.

## Usage

``` r
compare_snapshots(old, new, fields = NULL, tolerance = 0)
```

## Arguments

- old, new:

  Objects returned by
  [`data_snapshot()`](https://shanlong-who.github.io/DSIR/reference/data_snapshot.md),
  or local RDS paths containing such objects. Plain data frames and
  [`snapshot()`](https://shanlong-who.github.io/DSIR/reference/snapshot.md)
  cache files do not carry the required comparison contract.

- fields:

  Optional character vector of non-key fields to compare. Default `NULL`
  compares the union of all non-key data columns, including labels,
  notes, service record IDs and provider-reported timestamps. Snapshot
  and retrieval times are context, not observation changes.

- tolerance:

  A single non-negative, finite absolute numeric tolerance. Default `0`
  compares numbers exactly. It applies to numeric fields, not dates,
  times, character strings or matching keys. Original values remain
  unrounded. A display string can still change when numbers are within
  tolerance; use `fields` explicitly to compare numeric fields alone.

## Value

A list, classed `dsir_snapshot_comparison`, containing:

- summary:

  A one-row tibble with old/new snapshot and retrieval times, source,
  backend, indicator, query scope, observation counts, `n_added`,
  `n_removed`, `n_modified`, `n_unchanged`, `n_value_modified`,
  `n_metadata_only`, `n_metadata_modified`, selected fields and
  tolerance.

- added,removed:

  Complete new-only and old-only observation rows.

- modified:

  Key columns, primary `old_value` and `new_value`, absolute/relative
  changes, change flags, `change_type`, a `changed_fields` list-column,
  and `old` / `new` data-frame columns containing complete old/new
  tables aligned with the modified rows. For example,
  `modified$old[1, ]` is the first original old row.

- unchanged:

  Complete new rows whose selected fields are unchanged.

- schema_changes:

  Non-key fields added, removed or changed in type, independent of
  whether their values changed.

- key,fields,value_fields:

  The identity and selected comparison fields.

## Details

Comparison stops when source, backend, indicator, layout, origin, query
scope, key columns or value definitions differ. Changes in the available
unit or measure-family codes also stop comparison: these can change the
meaning of a quantity. Equal scope is necessary, not sufficient proof of
scientific comparability. Imported data and local subsets require an
explicit, honest scope declaration when making their snapshots.

Matching ignores row order, column order and row names. Missing values
match missing values. An entirely missing logical column from JSON can
be compared with a later typed column; integer and double numbers are
compatible. Other incompatible field types cause an actionable error.
Missing optional metadata columns are compared as missing values, with
their schema differences reported separately. List-column note order is
retained; NULL, an empty vector and a scalar NA denote an absent note.

A matched observation is `modified` when at least one selected field
changes. `value_changed` concerns selected `value_fields`; other
selected fields determine `metadata_changed`. A modification with no
selected value change is labelled `"metadata_only"`. Selecting `fields`
restricts every change classification; unselected differences are not
counted.

`absolute_change` is the signed difference `new_value - old_value` in
the primary numeric field's units. `relative_change` is that difference
divided by the old value, a fraction rather than a percentage. It is NA
for zero/missing old values, missing new values or non-finite
calculations. These convenience columns concern the primary value even
when another field triggered the modification.

This establishes differences between two saved extracts. It does not
establish their exact change date, revision reason or official WHO
publication status. Counts of added, removed and value-modified rows can
inform whether to review existing outputs; the caller decides whether
those rows or changed labels/notes affect a particular report.

## See also

[`data_snapshot()`](https://shanlong-who.github.io/DSIR/reference/data_snapshot.md),
[`gho_last_updated()`](https://shanlong-who.github.io/DSIR/reference/gho_last_updated.md).

## Examples

``` r
# See data_snapshot() for a complete offline example.
if (FALSE) { # \dontrun{
result <- compare_snapshots("snapshots/gho_old.rds",
                            "snapshots/gho_new.rds")
result$summary
result$modified
# For a report using numeric values and bounds only:
compare_snapshots("snapshots/gho_old.rds", "snapshots/gho_new.rds",
                  fields = c("NumericValue", "Low", "High"))
} # }
```
