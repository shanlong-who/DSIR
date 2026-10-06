# List GHO Indicators

Fetches the catalog of indicators from the WHO Global Health Observatory
(GHO) OData API.

## Usage

``` r
gho_indicators(search = NULL)
```

## Arguments

- search:

  Optional character. Search keywords matched against `IndicatorName`
  (case-insensitive). All terms must match (AND semantics). Accepts
  either:

  - a single string, which is split on whitespace into terms (e.g.
    `"child mortality"` matches indicators containing both "child" and
    "mortality"), or

  - a character vector, whose elements are used as terms verbatim
    (whitespace inside an element is treated as part of the term).

  Search terms are matched literally; they are not download identifiers.

## Value

A [tibble](https://tibble.tidyverse.org/reference/tibble.html) with
columns `IndicatorCode`, `IndicatorName` and `Language`. Returns an
empty tibble (with a warning) when the service is unreachable.

## See also

[`gho_data()`](https://shanlong-who.github.io/DSIR/reference/gho_data.md),
[`gho_dimensions()`](https://shanlong-who.github.io/DSIR/reference/gho_dimensions.md).

## Examples

``` r
# \donttest{
# All indicators
inds <- gho_indicators()

# Single keyword
gho_indicators("mortality")
#> # A tibble: 25 × 3
#>    IndicatorCode         IndicatorName                                  Language
#>    <chr>                 <chr>                                          <chr>   
#>  1 SDGSUICIDE            Suicide mortality rate (per 100 000 populatio… EN      
#>  2 NCDMORT3070           Probability of premature mortality from NCDs   EN      
#>  3 MDG_0000000007        Under-five mortality rate (per 1000 live birt… EN      
#>  4 VIOLENCE_HOMICIDERATE Mortality rate due to homicide (per 100 000 p… EN      
#>  5 TB_e_mort_100k        HIV-negative TB mortality                      EN      
#>  6 TB_e_mort_agesex_100k TB mortality rate by age and sex per 100 000 … EN      
#>  7 SDGPOISON             Mortality rate from unintentional poisoning (… EN      
#>  8 WHOSIS_000003         Neonatal mortality rate (per 1000 live births) EN      
#>  9 MDG_0000000026        Maternal mortality ratio (per 100 000 live bi… EN      
#> 10 MALARIA_EST_MORTALITY Estimated malaria mortality rate (per 100 000… EN      
#> # ℹ 15 more rows

# Multiple keywords from one string (AND): both terms must appear
gho_indicators("child mortality")
#> # A tibble: 2 × 3
#>   IndicatorCode  IndicatorName                                          Language
#>   <chr>          <chr>                                                  <chr>   
#> 1 CHILDMORT5TO14 Mortality rate among children ages 5 to 14 years of a… EN      
#> 2 WHOSIS_000016  Mortality rate among children ages 5 to 9 years (per … EN      

# Or pass terms as a vector
gho_indicators(c("child", "mortality"))
#> # A tibble: 2 × 3
#>   IndicatorCode  IndicatorName                                          Language
#>   <chr>          <chr>                                                  <chr>   
#> 1 CHILDMORT5TO14 Mortality rate among children ages 5 to 14 years of a… EN      
#> 2 WHOSIS_000016  Mortality rate among children ages 5 to 9 years (per … EN      
# }
```
