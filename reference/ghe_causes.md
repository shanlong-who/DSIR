# Explore Global Health Estimates Causes

Lists causes from an all-age, both-sex reference slice in the latest GHE
year. The reference country is the first available WHO Member State in
ISO3 order. This avoids grouping the full database. Codes are exact
download identifiers; selection coverage still needs
[`ghe_coverage()`](https://shanlong-who.github.io/DSIR/reference/ghe_coverage.md).

## Usage

``` r
ghe_causes(search = NULL)
```

## Arguments

- search:

  Optional words matched against cause names, ignoring case. All terms
  must match; a single string is split on whitespace.

## Value

A tibble with `cause_code`, `cause_name`, `level`, `cause_group`,
`rankable`, and `single_cause`. The provider has no parent-code field;
`cause_group` is retained as published and is not a parent identifier.

## See also

[`ghe_data()`](https://shanlong-who.github.io/DSIR/reference/ghe_data.md),
[`ghe_dimensions()`](https://shanlong-who.github.io/DSIR/reference/ghe_dimensions.md)

## Examples

``` r
# \donttest{
ghe_causes('diabetes')
#> Fetching WHO: "DEX_CMS/REF_YEAR_COD"
#> Fetching WHO: "DEX_CMS/GHE_FULL"
#> Fetching WHO: "DEX_CMS/GHE_FULL"
#> # A tibble: 2 × 6
#>   cause_code cause_name                  level cause_group rankable single_cause
#>   <chr>      <chr>                       <int> <chr>       <lgl>    <lgl>       
#> 1 800        Diabetes mellitus               2 2           TRUE     TRUE        
#> 2 1272       Chronic kidney disease due…     4 2           FALSE    TRUE        
ghe_causes('stroke')
#> # A tibble: 3 × 6
#>   cause_code cause_name          level cause_group rankable single_cause
#>   <chr>      <chr>               <int> <chr>       <lgl>    <lgl>       
#> 1 1140       Stroke                  3 2           TRUE     FALSE       
#> 2 1141       Ischaemic stroke        4 2           FALSE    TRUE        
#> 3 1142       Haemorrhagic stroke     4 2           FALSE    TRUE        
# }
```
