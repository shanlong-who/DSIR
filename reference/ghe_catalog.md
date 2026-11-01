# Bundled GHE Cause and Measure Catalog

An offline snapshot of
[`ghe_causes()`](https://shanlong-who.github.io/DSIR/reference/ghe_causes.md)
and
[`ghe_dimensions()`](https://shanlong-who.github.io/DSIR/reference/ghe_dimensions.md)
with `dimension = "measure"`. Causes and measures are separate row
kinds, not a claim that every cause-measure combination has
observations.

## Usage

``` r
ghe_catalog
```

## Format

A tibble with ten columns:

- kind:

  `cause` or `measure`.

- code:

  Cause code or DSIR measure code, interpreted with `kind`.

- label:

  Cause name or measure label.

- backend:

  `xmart`.

- field:

  Provider measure field; missing for causes.

- unit:

  DSIR measure unit; missing for causes.

- level:

  Published cause level; missing for measures.

- cause_group:

  Published cause group, not a parent identifier.

- rankable:

  Published cause flag; missing for measures.

- single_cause:

  Published cause flag; missing for measures.

## Source

WHO public xMart GHE table:
<https://xmart-api-public.who.int/DEX_CMS/GHE_FULL>.

## Details

Cause discovery uses the same latest-year, all-age, both-sex reference
country as
[`ghe_causes()`](https://shanlong-who.github.io/DSIR/reference/ghe_causes.md).
The exact selection is recorded in `dsir_metadata(ghe_catalog)$scope`;
it is not a global coverage audit. Measure labels and units come from
DSIR's adapter, and their provider fields were verified against the
table schema. Reference year, retrieval time, package version and
catalog version are separate concepts. No unreported WHO release or API
version is invented. Refresh through `data-raw/catalogs.R` in the source
repository.

## See also

[gho_catalog](https://shanlong-who.github.io/DSIR/reference/gho_catalog.md),
[sdg_catalog](https://shanlong-who.github.io/DSIR/reference/sdg_catalog.md),
[`ghe_coverage()`](https://shanlong-who.github.io/DSIR/reference/ghe_coverage.md)

## Examples

``` r
ghe_catalog[ghe_catalog$kind == "measure", c("code", "label", "unit")]
dsir_metadata(ghe_catalog)$scope
```
