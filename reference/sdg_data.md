# Fetch SDG Data

Retrieves data for one or more SDG indicators from the UN SDG API, with
optional filters by area and year.

## Usage

``` r
sdg_data(
  indicator,
  area = NULL,
  year_from = NULL,
  year_to = NULL,
  page_size = 1000L
)
```

## Arguments

- indicator:

  Character vector of indicator codes (e.g. `"1.1.1"`). Use
  [`sdg_indicators()`](https://shanlong-who.github.io/DSIR/reference/sdg_indicators.md)
  to find codes.

- area:

  Character vector of country/area codes. Accepts either ISO3 codes
  (e.g. `c("PHL", "FRA")`) — converted automatically via
  [`iso3_to_m49()`](https://shanlong-who.github.io/DSIR/reference/iso3_to_m49.md)
  — or UN M49 numeric codes (e.g. `c("608", "250")`) as returned by
  [`sdg_areas()`](https://shanlong-who.github.io/DSIR/reference/sdg_areas.md).
  Do not mix the two formats in a single call. Default `NULL` returns
  all areas.

- year_from:

  Numeric. Start year filter (inclusive). Default `NULL`.

- year_to:

  Numeric. End year filter (inclusive). Default `NULL`.

- page_size:

  Integer. Number of records per page. Default `1000`, maximum `10000`.

## Value

A [tibble](https://tibble.tidyverse.org/reference/tibble.html) of
indicator observations, or an empty tibble when the service is
unreachable or there are no matching rows.

## See also

[`sdg_indicators()`](https://shanlong-who.github.io/DSIR/reference/sdg_indicators.md),
[`sdg_areas()`](https://shanlong-who.github.io/DSIR/reference/sdg_areas.md),
[`iso3_to_m49()`](https://shanlong-who.github.io/DSIR/reference/iso3_to_m49.md).

## Examples

``` r
# \donttest{
# One indicator, one country — the typical entry point
sdg_data("1.1.1", area = "PHL")
#> Fetching:
#> <https://unstats.un.org/sdgs/UNSDGAPIV5/v1/sdg/Indicator/Data?indicator=1.1.1&pageSize=1000&areaCode=608&page=1>
#> # A tibble: 123 × 21
#>    goal      target indicator series   seriesDescription seriesCount geoAreaCode
#>    <list>    <list> <list>    <chr>    <chr>             <chr>       <chr>      
#>  1 <chr [1]> <chr>  <chr [1]> SI_POV_… Proportion of po… 11407       608        
#>  2 <chr [1]> <chr>  <chr [1]> SI_POV_… Proportion of po… 11407       608        
#>  3 <chr [1]> <chr>  <chr [1]> SI_POV_… Proportion of po… 11407       608        
#>  4 <chr [1]> <chr>  <chr [1]> SI_POV_… Proportion of po… 11407       608        
#>  5 <chr [1]> <chr>  <chr [1]> SI_POV_… Proportion of po… 11407       608        
#>  6 <chr [1]> <chr>  <chr [1]> SI_POV_… Proportion of po… 11407       608        
#>  7 <chr [1]> <chr>  <chr [1]> SI_POV_… Proportion of po… 11407       608        
#>  8 <chr [1]> <chr>  <chr [1]> SI_POV_… Proportion of po… 11407       608        
#>  9 <chr [1]> <chr>  <chr [1]> SI_POV_… Proportion of po… 11407       608        
#> 10 <chr [1]> <chr>  <chr [1]> SI_POV_… Proportion of po… 11407       608        
#> # ℹ 113 more rows
#> # ℹ 14 more variables: geoAreaName <chr>, timePeriodStart <int>, value <chr>,
#> #   valueType <chr>, time_detail <lgl>, timeCoverage <lgl>, upperBound <lgl>,
#> #   lowerBound <lgl>, basePeriod <chr>, source <chr>, geoInfoUrl <lgl>,
#> #   footnotes <list>, attributes <df[,1]>, dimensions <df[,2]>

# Specific area and year range (M49 code)
sdg_data("3.2.1", area = "156", year_from = 2015, year_to = 2023)
#> Fetching:
#> <https://unstats.un.org/sdgs/UNSDGAPIV5/v1/sdg/Indicator/Data?indicator=3.2.1&pageSize=1000&areaCode=156&page=1>
#> # A tibble: 108 × 21
#>    goal      target indicator series   seriesDescription seriesCount geoAreaCode
#>    <list>    <list> <list>    <chr>    <chr>             <chr>       <chr>      
#>  1 <chr [1]> <chr>  <chr [1]> SH_DYN_… Infant deaths (n… 16575       156        
#>  2 <chr [1]> <chr>  <chr [1]> SH_DYN_… Infant deaths (n… 16575       156        
#>  3 <chr [1]> <chr>  <chr [1]> SH_DYN_… Infant deaths (n… 16575       156        
#>  4 <chr [1]> <chr>  <chr [1]> SH_DYN_… Infant deaths (n… 16575       156        
#>  5 <chr [1]> <chr>  <chr [1]> SH_DYN_… Infant deaths (n… 16575       156        
#>  6 <chr [1]> <chr>  <chr [1]> SH_DYN_… Infant deaths (n… 16575       156        
#>  7 <chr [1]> <chr>  <chr [1]> SH_DYN_… Infant deaths (n… 16575       156        
#>  8 <chr [1]> <chr>  <chr [1]> SH_DYN_… Infant deaths (n… 16575       156        
#>  9 <chr [1]> <chr>  <chr [1]> SH_DYN_… Infant deaths (n… 16575       156        
#> 10 <chr [1]> <chr>  <chr [1]> SH_DYN_… Infant deaths (n… 16575       156        
#> # ℹ 98 more rows
#> # ℹ 14 more variables: geoAreaName <chr>, timePeriodStart <int>, value <chr>,
#> #   valueType <chr>, time_detail <lgl>, timeCoverage <lgl>, upperBound <chr>,
#> #   lowerBound <chr>, basePeriod <lgl>, source <chr>, geoInfoUrl <lgl>,
#> #   footnotes <list>, attributes <df[,1]>, dimensions <df[,1]>

# ISO3 codes work directly — DSIR's regional vectors can be passed in
sdg_data("3.4.1", area = c("PHL", "FRA", "JPN"))
#> Fetching:
#> <https://unstats.un.org/sdgs/UNSDGAPIV5/v1/sdg/Indicator/Data?indicator=3.4.1&pageSize=1000&areaCode=608&areaCode=250&areaCode=392&page=1>
#> # A tibble: 63 × 21
#>    goal      target indicator series   seriesDescription seriesCount geoAreaCode
#>    <list>    <list> <list>    <chr>    <chr>             <chr>       <chr>      
#>  1 <chr [1]> <chr>  <chr [1]> SH_DTH_… Mortality rate a… 4326        250        
#>  2 <chr [1]> <chr>  <chr [1]> SH_DTH_… Mortality rate a… 4326        250        
#>  3 <chr [1]> <chr>  <chr [1]> SH_DTH_… Mortality rate a… 4326        250        
#>  4 <chr [1]> <chr>  <chr [1]> SH_DTH_… Mortality rate a… 4326        250        
#>  5 <chr [1]> <chr>  <chr [1]> SH_DTH_… Mortality rate a… 4326        250        
#>  6 <chr [1]> <chr>  <chr [1]> SH_DTH_… Mortality rate a… 4326        250        
#>  7 <chr [1]> <chr>  <chr [1]> SH_DTH_… Mortality rate a… 4326        250        
#>  8 <chr [1]> <chr>  <chr [1]> SH_DTH_… Mortality rate a… 4326        250        
#>  9 <chr [1]> <chr>  <chr [1]> SH_DTH_… Mortality rate a… 4326        250        
#> 10 <chr [1]> <chr>  <chr [1]> SH_DTH_… Mortality rate a… 4326        250        
#> # ℹ 53 more rows
#> # ℹ 14 more variables: geoAreaName <chr>, timePeriodStart <int>, value <chr>,
#> #   valueType <chr>, time_detail <lgl>, timeCoverage <lgl>, upperBound <chr>,
#> #   lowerBound <chr>, basePeriod <lgl>, source <chr>, geoInfoUrl <lgl>,
#> #   footnotes <list>, attributes <df[,1]>, dimensions <df[,1]>
# }
```
