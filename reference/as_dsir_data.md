# Explicitly Create an Experimental DSIR Data Object

Adds a `dsir_data` tibble subclass to an already cleaned indicator
table. Cleaners return this subclass by default; `output = "tibble"`
opts out. Downloads and directory functions retain their existing return
types. This experimental interface and its metadata schema may change.

## Usage

``` r
as_dsir_data(x)

# S3 method for class 'dsir_data'
print(x, ...)

# S3 method for class 'dsir_data'
summary(object, ...)
```

## Arguments

- x:

  A data frame with the typed 15-column schema returned by
  [`gho_clean()`](https://shanlong-who.github.io/DSIR/reference/gho_clean.md),
  [`ghe_clean()`](https://shanlong-who.github.io/DSIR/reference/ghe_clean.md)
  or
  [`sdg_clean()`](https://shanlong-who.github.io/DSIR/reference/sdg_clean.md).
  Optional columns are kept.

- ...:

  Arguments passed to the underlying tibble printer, or reserved for
  future summary options.

- object:

  A `dsir_data` object.

## Value

A tibble inheriting from `dsir_data`, with a `dsir_metadata` attribute.
Use
[`dsir_metadata()`](https://shanlong-who.github.io/DSIR/reference/dsir_metadata.md)
to inspect it.

## Details

Conversion does not retrieve data or recover discarded fields. Retain
dimensions and metadata when cleaning if they are needed for analysis.
Recorded `who_provenance` is moved into the metadata, not duplicated.
Unknown retrieval times and definitions remain unknown. The initial
`as_supplied` status describes the input; it does not certify its
origin, completeness, units or statistical validity.

Row selection and ordering preserve the class. Column modifications,
including
[`dplyr::mutate()`](https://dplyr.tidyverse.org/reference/mutate.html)
and base replacement, preserve it while the core schema remains valid.
New columns are marked derived. Changes to input fields mark their
metadata as needing review; changes to values, units or identifiers also
flag related interpretation. This records field changes, not an
executable transformation history or inferred formulas. Deleting a core
column or changing its required type returns a plain tibble. Removing
optional input columns records the loss of information.

Joins, row binding, persistent grouping and explicit conversion with
[`tibble::as_tibble()`](https://tibble.tidyverse.org/reference/as_tibble.html)
or [`as.data.frame()`](https://rdrr.io/r/base/as.data.frame.html) return
ordinary tables without object-level provenance. Per-row source and
dimension columns remain. Use `.by` for transient dplyr grouping.
Summary operations create new ordinary tables. Direct manipulation of
attributes is outside this experimental contract.

[`data_snapshot()`](https://shanlong-who.github.io/DSIR/reference/data_snapshot.md)
accepts an unchanged GHO object with the required detailed fields and
original provenance. Row-selected objects need an explicit query scope.
Objects whose metadata needs review are rejected; retain the original
observations for reproducible source snapshots.

[`summary()`](https://rdrr.io/r/base/summary.html) returns a structured
list with current coverage, indicator identities, dimension values,
per-column missing counts and provenance. Numeric diagnostics count
missing and non-finite `value_num` entries. This first version does not
pool numerical statistics across indicators, countries, units or
demographic groups. Empty list entries and entries containing only
missing values count as missing in list columns.

## See also

[`dsir_metadata()`](https://shanlong-who.github.io/DSIR/reference/dsir_metadata.md),
[`plot.dsir_data()`](https://shanlong-who.github.io/DSIR/reference/plot.dsir_data.md),
[gho_catalog](https://shanlong-who.github.io/DSIR/reference/gho_catalog.md)

## Examples

``` r
raw <- tibble::tibble(
  IndicatorCode = "EXAMPLE", IndicatorName = "Example indicator",
  SpatialDim = c("PHL", "LAO"), TimeDim = c(2022L, 2023L),
  NumericValue = c(10, 20), Value = c("10", "20")
)
x <- as_dsir_data(gho_clean(raw))
x
summary(x)
x$value_num <- x$value_num / 100
dsir_metadata(x)$processing
```
