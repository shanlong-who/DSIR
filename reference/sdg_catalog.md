# Bundled SDG Indicator and Series Catalog

An offline snapshot of
[`sdg_indicators()`](https://shanlong-who.github.io/DSIR/reference/sdg_indicators.md),
preserving the API's nested indicator-to-series relationships and
provider release labels.

## Usage

``` r
sdg_catalog
```

## Format

A tibble with eight columns:

- goal:

  SDG goal code.

- target:

  SDG target code.

- code:

  SDG indicator code.

- description:

  Indicator description.

- tier:

  Provider tier code.

- uri:

  Provider-relative indicator URI.

- series:

  List of data frames containing the linked series and their original
  `code`, `description`, `release` and other fields.

- backend:

  `unsdg`.

## Source

UN SDG V5 indicator directory:
<https://unstats.un.org/sdgs/UNSDGAPIV5/v1/sdg/Indicator/List>.

## Details

[`dsir_metadata()`](https://shanlong-who.github.io/DSIR/reference/dsir_metadata.md)
distinguishes the DSIR catalog snapshot version, package build version,
API version and provider release labels. A release label is recorded as
supplied, not inferred from retrieval time. Catalog membership does not
establish country/year observation coverage. Refresh through
`data-raw/catalogs.R` in the source repository.

## See also

[gho_catalog](https://shanlong-who.github.io/DSIR/reference/gho_catalog.md),
[ghe_catalog](https://shanlong-who.github.io/DSIR/reference/ghe_catalog.md),
[`sdg_dimensions()`](https://shanlong-who.github.io/DSIR/reference/sdg_dimensions.md)

## Examples

``` r
sdg_catalog[sdg_catalog$goal == "3", c("code", "description")]
dsir_metadata(sdg_catalog)$sources
```
