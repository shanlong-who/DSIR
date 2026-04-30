# Pacific Island Country ISO3 codes

Character vector of ISO3 codes for the 14 WHO Member States classified
as Pacific Island Countries (PICs). Sorted alphabetically.

## Usage

``` r
pic_cty
```

## Format

A character vector of 14 ISO 3166-1 alpha-3 codes.

## Details

All 14 PICs are within the Western Pacific Region, so
`all(pic_cty %in% wpro_cty)` is `TRUE`. Non-Member Pacific areas (e.g.
New Caledonia, French Polynesia, American Samoa, Tokelau) are not
included.

The 14 PIC Member States are: Cook Islands, Fiji, Kiribati, Marshall
Islands, Micronesia (Federated States of), Nauru, Niue, Palau, Papua New
Guinea, Samoa, Solomon Islands, Tonga, Tuvalu, and Vanuatu.

## See also

[`who_countries`](https://shanlong-who.github.io/DSIR/reference/who_countries.md),
[`wpro_cty`](https://shanlong-who.github.io/DSIR/reference/who_region_vectors.md).

## Examples

``` r
length(pic_cty)              # 14
#> [1] 14
all(pic_cty %in% wpro_cty)   # TRUE
#> [1] TRUE
```
