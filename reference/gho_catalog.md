# Bundled GHO Indicator Catalog from Both Backends

An offline union of the legacy and xMart
[`gho_indicators()`](https://shanlong-who.github.io/DSIR/reference/gho_indicators.md)
directories. A code present in both backends has two rows. Names are
kept as supplied; matching codes do not establish equivalent definitions
or releases.

## Usage

``` r
gho_catalog
```

## Format

A tibble with four character columns:

- IndicatorCode:

  Provider indicator code.

- IndicatorName:

  Provider indicator name.

- Language:

  Provider language code.

- backend:

  `legacy` or `xmart`.

## Source

WHO legacy GHO and public xMart indicator directories:
<https://www.who.int/data/gho/info/gho-odata-api> and
<https://xmart-api-public.who.int/DATA_/IND_DIRECTORY_WIDE>.

## Details

Use
[`dsir_metadata()`](https://shanlong-who.github.io/DSIR/reference/dsir_metadata.md)
for the catalog version, DSIR build version, bundling time and separate
source retrieval times and statuses. These are snapshot records, not the
current availability of observations. A `bundled_snapshot` source
retains its historical retrieval time when the live catalog was
unavailable. The xMart side follows the existing English-language
directory and code deduplication in
[`gho_indicators()`](https://shanlong-who.github.io/DSIR/reference/gho_indicators.md).
This dataset does not change live discovery or backend fallback rules.
Refresh through `data-raw/catalogs.R` in the source repository.

## See also

[sdg_catalog](https://shanlong-who.github.io/DSIR/reference/sdg_catalog.md),
[ghe_catalog](https://shanlong-who.github.io/DSIR/reference/ghe_catalog.md),
[`dsir_metadata()`](https://shanlong-who.github.io/DSIR/reference/dsir_metadata.md)

## Examples

``` r
head(gho_catalog)
table(gho_catalog$backend)
dsir_metadata(gho_catalog)$sources
```
