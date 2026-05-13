# Convert UN M49 Numeric Codes to ISO3 Codes

Maps UN M49 numeric area codes to ISO 3166-1 alpha-3 country codes using
the
[`who_countries`](https://shanlong-who.github.io/DSIR/reference/who_countries.md)
dataset shipped with DSIR. Counterpart to
[`iso3_to_m49()`](https://shanlong-who.github.io/DSIR/reference/iso3_to_m49.md)
and used internally by
[`sdg_clean()`](https://shanlong-who.github.io/DSIR/reference/sdg_clean.md)
to populate the `iso3` column on SDG output.

## Usage

``` r
m49_to_iso3(m49)
```

## Arguments

- m49:

  Character vector of M49 codes.

## Value

A character vector the same length as `m49`. Non-Member codes (region
aggregates, non-Member areas) return `NA`.

## Details

M49 codes that do not correspond to a WHO Member State return `NA`. This
includes region / world aggregates (e.g. `"900"` for World, `"001"` for
World, `"419"` for Latin America and the Caribbean) and codes for
non-Member areas (e.g. Puerto Rico, Tokelau).

Input accepts either the zero-padded form (`"076"`) or the bare form
(`"76"`); both are normalised before lookup. Non-numeric input returns
`NA` (with a single warning from the underlying
[`as.integer()`](https://rdrr.io/r/base/integer.html) coercion).

## See also

[`who_countries`](https://shanlong-who.github.io/DSIR/reference/who_countries.md),
[`iso3_to_m49()`](https://shanlong-who.github.io/DSIR/reference/iso3_to_m49.md),
[`sdg_clean()`](https://shanlong-who.github.io/DSIR/reference/sdg_clean.md).

## Examples

``` r
m49_to_iso3(c("608", "250", "392"))
#> [1] "PHL" "FRA" "JPN"
# "PHL" "FRA" "JPN"

# Zero-padded and bare forms both accepted
m49_to_iso3(c("076", "76"))
#> [1] "BRA" "BRA"
# "BRA" "BRA"

# Non-Member areas / aggregates return NA
m49_to_iso3(c("900", "608"))
#> [1] NA    "PHL"
# NA "PHL"
```
