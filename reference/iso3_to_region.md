# Look Up the WHO Region for ISO3 Codes

Maps ISO 3166-1 alpha-3 country codes to WHO region codes using the
[`who_countries`](https://shanlong-who.github.io/DSIR/reference/who_countries.md)
dataset shipped with DSIR. Stays in sync with WHO governance changes
reflected in DSIR — for example, Indonesia's reassignment from SEAR to
WPR following EB156 (May 2025).

## Usage

``` r
iso3_to_region(iso3, long = FALSE)
```

## Arguments

- iso3:

  Character vector of ISO3 codes. Case-sensitive (uppercase, as in
  [`who_countries`](https://shanlong-who.github.io/DSIR/reference/who_countries.md)).

- long:

  Logical. If `TRUE`, return long-form region names (e.g.
  `"Western Pacific"`). If `FALSE` (default), return the short codes
  used elsewhere in DSIR: `"AFR"`, `"AMR"`, `"SEAR"`, `"EUR"`, `"EMR"`,
  `"WPR"`.

## Value

A character vector the same length as `iso3`.

## Details

Codes that do not correspond to a WHO Member State return `NA`. This
includes Associate Members (Puerto Rico, Tokelau) and other non-Member
areas that some indicator data sets cover.

## See also

[`who_countries`](https://shanlong-who.github.io/DSIR/reference/who_countries.md),
[`wpro_cty`](https://shanlong-who.github.io/DSIR/reference/who_region_vectors.md).

## Examples

``` r
iso3_to_region(c("PHL", "FRA", "USA", "COK"))
#> [1] "WPR" "EUR" "AMR" "WPR"
# "WPR" "EUR" "AMR" "WPR"

iso3_to_region(c("IDN", "JPN"), long = TRUE)
#> [1] "Western Pacific" "Western Pacific"
# "Western Pacific" "Western Pacific"  (Indonesia in WPR since May 2025)

# Non-Member areas return NA
iso3_to_region(c("PRI", "TKL", "PHL"))
#> [1] NA    NA    "WPR"
# NA NA "WPR"
```
