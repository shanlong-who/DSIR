# Convert ISO3 Codes to UN M49 Numeric Codes

Maps ISO 3166-1 alpha-3 country codes to UN M49 numeric area codes using
the
[`who_countries`](https://shanlong-who.github.io/DSIR/reference/who_countries.md)
dataset shipped with DSIR. Useful when moving from data sources keyed by
ISO3 (e.g. the WHO GHO API) to sources keyed by M49 (e.g. the UN SDG
API).

## Usage

``` r
iso3_to_m49(iso3)
```

## Arguments

- iso3:

  Character vector of ISO3 codes. Case-insensitive; values are
  upper-cased before lookup.

## Value

A character vector the same length as `iso3`, with M49 codes in the same
format as `who_countries$m49_code` (three- character zero-padded
strings, e.g. `"076"`). Non-Member areas return `NA`.

## Details

Codes that do not correspond to a WHO Member State return `NA`. This
includes Associate Members (e.g. Puerto Rico) and other non-Member areas
that some indicator data sets cover.

Most users will not need to call this function directly:
[`sdg_data()`](https://shanlong-who.github.io/DSIR/reference/sdg_data.md)
and
[`sdg_coverage()`](https://shanlong-who.github.io/DSIR/reference/sdg_coverage.md)
accept ISO3 codes for their `area` argument and convert internally. This
helper is exported for cases where you want to inspect or manipulate the
conversion yourself.

## See also

[`who_countries`](https://shanlong-who.github.io/DSIR/reference/who_countries.md),
[`iso3_to_region()`](https://shanlong-who.github.io/DSIR/reference/iso3_to_region.md),
[`sdg_data()`](https://shanlong-who.github.io/DSIR/reference/sdg_data.md).

## Examples

``` r
iso3_to_m49(c("PHL", "FRA", "JPN"))
#> [1] "608" "250" "392"
# "608" "250" "392"

# Case-insensitive
iso3_to_m49("phl")
#> [1] "608"
# "608"

# Non-Member areas return NA
iso3_to_m49(c("PRI", "PHL"))
#> [1] NA    "608"
# NA "608"
```
