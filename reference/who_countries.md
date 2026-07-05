# WHO Member States with regional and Pacific classifications

A tibble of the 194 World Health Organization (WHO) Member States, with
standard country identifiers and WHO/Pacific groupings used across DSIR
analytical workflows.

## Usage

``` r
who_countries
```

## Format

A tibble with 194 rows and 8 columns:

- iso3:

  ISO 3166-1 alpha-3 code (3-letter, e.g. `"PHL"`).

- iso2:

  ISO 3166-1 alpha-2 code (2-letter, e.g. `"PH"`).

- m49_code:

  UN M49 numeric code, stored as a 3-character string with leading zeros
  where present (e.g. `"008"` for Albania). Stored as character because
  some downstream APIs (notably the UN SDG API) expect the leading-zero
  form.

- name_official:

  WHO official English name (e.g. `"Iran (Islamic Republic of)"`). Use
  for formal documents and reports.

- name_short:

  A shorter form suitable for charts and tables (e.g. `"Iran"`). Equal
  to `name_official` for countries whose official name is already
  concise. See Details.

- who_region:

  WHO region code: one of `"AFR"`, `"AMR"`, `"SEAR"`, `"EUR"`, `"EMR"`,
  `"WPR"`.

- is_pic:

  Logical. `TRUE` for the 14 Pacific Island Country (PIC) Member States
  in WPR, `FALSE` otherwise.

- wb_income_group:

  World Bank income classification: `"High income"`,
  `"Upper middle income"`, `"Lower middle income"`, or `"Low income"`.
  `NA` for Cook Islands and Niue, which are not World Bank economies.
  See Details for the vintage.

## Source

- WHO official region listing: <https://www.who.int/countries>

- ISO 3166-1 codes and UN M49 numeric codes: UN Statistics Division
  <https://unstats.un.org/unsd/methodology/m49/>

- World Bank income classification (FY2027):
  <https://datahelpdesk.worldbank.org/knowledgebase/articles/906519>

## Details

**Scope.** WHO has 194 Member States plus 2 Associate Members (Puerto
Rico, Tokelau) and reports on additional non-Member areas (e.g. West
Bank and Gaza Strip). This dataset includes only the 194 Member States.
Cook Islands and Niue are full WHO Member States and are included even
though they are not UN member states.

**Region coverage** (as of May 2025, after WHO EB156 reassignment of
Indonesia from SEAR to WPR):

- AFR (African Region): 47

- AMR (Region of the Americas): 35

- SEAR (South-East Asia Region): 10

- EUR (European Region): 53

- EMR (Eastern Mediterranean Region): 21

- WPR (Western Pacific Region): 28

**Short names.** `name_short` differs from `name_official` for 13
countries where the official name is a parenthetical descriptor or is
otherwise long. Examples: `"DPR Korea"`, `"DR Congo"`, `"Lao PDR"`,
`"United Kingdom"`. These short forms follow conventions used in WHO
regional reports and OECD Health at a Glance: Asia/Pacific.

**PICs.** The Pacific Island Countries flag (`is_pic`) marks the 14 WHO
Member States in the Pacific sub-region: Cook Islands, Fiji, Kiribati,
Marshall Islands, Micronesia (Federated States of), Nauru, Niue, Palau,
Papua New Guinea, Samoa, Solomon Islands, Tonga, Tuvalu, and Vanuatu.
Non-Member Pacific areas (e.g. New Caledonia, French Polynesia, American
Samoa) are not included in this dataset.

**Income groups.** `wb_income_group` carries the World Bank
classification of fiscal year 2027 (released 1 July 2026; based on 2025
GNI per capita, Atlas method). The classification is revised every 1
July, so this column reflects the vintage current at the package release
date — for a historical vintage (e.g. reproducing an older analysis),
join your own copy of the World Bank OGHIST table instead. Cook Islands
and Niue are WHO Member States but not World Bank economies and are
`NA`.

## Examples

``` r
# All WPR Member States, sorted alphabetically by short name
wpr <- who_countries[who_countries$who_region == "WPR", ]
wpr <- wpr[order(wpr$name_short), c("iso3", "name_short")]
head(wpr)
#> # A tibble: 6 × 2
#>   iso3  name_short       
#>   <chr> <chr>            
#> 1 AUS   Australia        
#> 2 BRN   Brunei Darussalam
#> 3 KHM   Cambodia         
#> 4 CHN   China            
#> 5 COK   Cook Islands     
#> 6 FJI   Fiji             

# Filter a data frame to PIC member states
# df_pic <- subset(my_data, country_iso3 %in% who_countries$iso3[who_countries$is_pic])

# Income-group composition of each WHO region
table(who_countries$who_region, who_countries$wb_income_group)
#>       
#>        High income Low income Lower middle income Upper middle income
#>   AFR            1         19                  20                   7
#>   AMR           12          0                   5                  18
#>   EMR            6          5                   6                   4
#>   EUR           36          0                   3                  14
#>   SEAR           0          1                   6                   3
#>   WPR            8          0                   6                  12
```
