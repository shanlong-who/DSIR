# Inspect DSIR Object or Catalog Metadata

Reads metadata without network requests. For `dsir_data`, indicator
identities, dimension values and coverage describe the current rows;
provenance and input counts describe the original conversion input.

## Usage

``` r
dsir_metadata(x)
```

## Arguments

- x:

  A
  [dsir_data](https://shanlong-who.github.io/DSIR/reference/as_dsir_data.md)
  object or one of the bundled
  [gho_catalog](https://shanlong-who.github.io/DSIR/reference/gho_catalog.md),
  [sdg_catalog](https://shanlong-who.github.io/DSIR/reference/sdg_catalog.md)
  and
  [ghe_catalog](https://shanlong-who.github.io/DSIR/reference/ghe_catalog.md)
  datasets.

## Value

A named list. For an analysis object it contains `schema_version`,
`layout`, `provenance`, `input`, `fields`, `processing`, `current`,
`indicators` and `dimensions`. Current indicator labels and dimension
values are observations from the table, not independently fetched
definitions. Read `processing$semantics` before interpreting them.
Catalog metadata includes its snapshot version, package build version
and source-specific retrieval records. `current` describes the supplied
table; source record counts describe the complete bundled snapshot.

## Examples

``` r
dsir_metadata(gho_catalog)$sources
```
