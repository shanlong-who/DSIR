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

  Single quotes in any term are escaped for the OData filter.

## Value

A [tibble](https://tibble.tidyverse.org/reference/tibble.html) with
columns `IndicatorCode`, `IndicatorName` and `Language`. Returns an
empty tibble (with a message) when the service is unreachable.

## See also

[`gho_data()`](https://shanlong-who.github.io/DSIR/reference/gho_data.md),
[`gho_dimensions()`](https://shanlong-who.github.io/DSIR/reference/gho_dimensions.md).

## Examples

``` r
# \donttest{
# All indicators
inds <- gho_indicators()
#> Fetching: <https://ghoapi.azureedge.net/api/Indicator>

# Single keyword
gho_indicators("mortality")
#> Fetching:
#> <https://ghoapi.azureedge.net/api/Indicator?$filter=contains%28tolower%28IndicatorName%29%2C%27mortality%27%29>
#> # A tibble: 32 × 3
#>    IndicatorCode  IndicatorName                                         Language
#>    <chr>          <chr>                                                 <chr>   
#>  1 imr            Infant mortality rate (deaths per 1000 live births)   EN      
#>  2 CHILDMORT5TO14 Mortality rate for 5-14 year-olds (probability of dy… EN      
#>  3 MDG_0000000007 Under-five mortality rate (probability of dying by a… EN      
#>  4 MDG_0000000026 Maternal mortality ratio (per 100 000 live births)    EN      
#>  5 MORTADO        Adolescent mortality rate (per 1 000 age specific co… EN      
#>  6 MDG_0000000001 Infant mortality rate (probability of dying between … EN      
#>  7 MDG_0000000032 Maternal mortality ratio (per 100 000 live births) -… EN      
#>  8 nmr            Neonatal mortality rate (deaths per 1000 live births) EN      
#>  9 SA_0000001472  Alcohol-related injury mortality, per 1,000           EN      
#> 10 SA_0000001473  Alcohol-related disease mortality, per 100,000 (15+ … EN      
#> # ℹ 22 more rows

# Multiple keywords from one string (AND): both terms must appear
gho_indicators("child mortality")
#> Fetching:
#> <https://ghoapi.azureedge.net/api/Indicator?$filter=contains%28tolower%28IndicatorName%29%2C%27child%27%29%20and%20contains%28tolower%28IndicatorName%29%2C%27mortality%27%29>
#> # A tibble: 4 × 3
#>   IndicatorCode              IndicatorName                              Language
#>   <chr>                      <chr>                                      <chr>   
#> 1 CHILDMORT5TO14             Mortality rate for 5-14 year-olds (probab… EN      
#> 2 WHS10_4                    Number of national population surveys - c… EN      
#> 3 WHOSIS_000016              Mortality rate among children ages 5 to 9… EN      
#> 4 CHILDMORT_MORTALITY_10TO14 Mortality rate among children ages 10 to … EN      

# Or pass terms as a vector
gho_indicators(c("child", "mortality"))
#> Fetching:
#> <https://ghoapi.azureedge.net/api/Indicator?$filter=contains%28tolower%28IndicatorName%29%2C%27child%27%29%20and%20contains%28tolower%28IndicatorName%29%2C%27mortality%27%29>
#> # A tibble: 4 × 3
#>   IndicatorCode              IndicatorName                              Language
#>   <chr>                      <chr>                                      <chr>   
#> 1 CHILDMORT5TO14             Mortality rate for 5-14 year-olds (probab… EN      
#> 2 WHS10_4                    Number of national population surveys - c… EN      
#> 3 WHOSIS_000016              Mortality rate among children ages 5 to 9… EN      
#> 4 CHILDMORT_MORTALITY_10TO14 Mortality rate among children ages 10 to … EN      
# }
```
