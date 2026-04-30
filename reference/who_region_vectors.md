# WHO regional Member State ISO3 vectors

Convenience character vectors of ISO3 codes for the WHO Member States in
each region. Each vector is the regional subset of
[`who_countries`](https://shanlong-who.github.io/DSIR/reference/who_countries.md)'s
`iso3` column, sorted alphabetically.

## Usage

``` r
afro_cty

amro_cty

searo_cty

euro_cty

emro_cty

wpro_cty
```

## Format

Character vectors of ISO 3166-1 alpha-3 codes.

An object of class `character` of length 47.

An object of class `character` of length 35.

An object of class `character` of length 10.

An object of class `character` of length 53.

An object of class `character` of length 21.

An object of class `character` of length 28.

## Details

These are derived directly from
[`who_countries`](https://shanlong-who.github.io/DSIR/reference/who_countries.md)
and exist for ergonomic filtering, e.g.
`dplyr::filter(data, iso3 %in% wpro_cty)`. If you need to update group
membership, edit `data-raw/who_countries.R` and re-run that script — the
vectors regenerate from the master table.

- `afro_cty`:

  47 Member States in the WHO African Region.

- `amro_cty`:

  35 Member States in the WHO Region of the Americas.

- `searo_cty`:

  10 Member States in the WHO South-East Asia Region.

- `euro_cty`:

  53 Member States in the WHO European Region.

- `emro_cty`:

  21 Member States in the WHO Eastern Mediterranean Region.

- `wpro_cty`:

  28 Member States in the WHO Western Pacific Region. Includes Indonesia
  from May 2025 (per WHO EB156).

## See also

[`who_countries`](https://shanlong-who.github.io/DSIR/reference/who_countries.md),
[`pic_cty`](https://shanlong-who.github.io/DSIR/reference/pic_cty.md).

## Examples

``` r
length(wpro_cty)        # 28
#> [1] 28
"IDN" %in% wpro_cty     # TRUE — Indonesia in WPR since May 2025
#> [1] TRUE
```
