# Fetch WHO Global Health Estimates

Retrieves current GHE estimates from `DEX_CMS/GHE_FULL` on the public
production xMart host, without credentials. Returns one row per selected
measure and country/year/sex/age/cause combination. Filters run
server-side.

## Usage

``` r
ghe_data(
  area = NULL,
  year = NULL,
  year_from = NULL,
  year_to = NULL,
  sex = NULL,
  age = NULL,
  cause = NULL,
  measure = NULL
)
```

## Arguments

- area:

  ISO3 country/area codes. See
  [`ghe_dimensions()`](https://shanlong-who.github.io/DSIR/reference/ghe_dimensions.md).

- year:

  Integer years; mutually exclusive with a year range.

- year_from, year_to:

  Inclusive scalar year bounds.

- sex:

  Exact codes, e.g. `"TOTAL"`, `"FEMALE"`, `"MALE"`.

- age:

  Exact age codes, e.g. `"TOTAL"`, `"Y40T44"`, `"Y_GE85"`. Totals and
  overlapping age groups must not be summed together.

- cause:

  Exact cause codes from
  [`ghe_causes()`](https://shanlong-who.github.io/DSIR/reference/ghe_causes.md),
  numeric or character. Code `0` is all causes. Hierarchy totals overlap
  with their components.

- measure:

  Codes from
  [`ghe_dimensions()`](https://shanlong-who.github.io/DSIR/reference/ghe_dimensions.md)
  with `dimension = "measure"`: `deaths`, `death_rate`, `yll`,
  `yll_rate`, `yld`, `yld_rate`, `daly`, `daly_rate`, `deaths_percent`,
  `yld_percent`, `daly_percent`. `NULL` returns all supported measures,
  including missing values.

## Value

A tibble with `iso3`, `location_name`, `year`, `sex`, `age`,
`cause_code`, `cause_name`, `measure`, `value`, `low`, `high`,
`population`, `unit`, `level`, `cause_group`, and `rankable`. A
`who_provenance` attribute records the backend, table and retrieval.

## Details

Supply at least one filter. Queries over 1,000,000 source rows warn and
return no rows; narrow the selection or explicitly set
`options(DSIR.who_max_rows = ...)`. This limit applies before pivoting
measures. Completeness is checked across pages; failed or incomplete
downloads return an empty tibble with a warning. No legacy fallback
occurs.

Counts have published lower/upper bounds where available. The API does
not expose bounds for rates or percentages; those remain `NA` and are
not derived from population. Counts are persons or years, not thousands.
Rates are age-specific or all-age crude rates as selected, not newly
age-standardized rates. Published GHE vintages can revise earlier years.

## See also

[`ghe_causes()`](https://shanlong-who.github.io/DSIR/reference/ghe_causes.md),
[`ghe_dimensions()`](https://shanlong-who.github.io/DSIR/reference/ghe_dimensions.md),
[`ghe_coverage()`](https://shanlong-who.github.io/DSIR/reference/ghe_coverage.md),
[`ghe_clean()`](https://shanlong-who.github.io/DSIR/reference/ghe_clean.md),
[`snapshot()`](https://shanlong-who.github.io/DSIR/reference/snapshot.md)

## Examples

``` r
# \donttest{
ghe_data(area = 'PHL', year = 2023, age = 'TOTAL', sex = 'TOTAL',
         cause = 0, measure = 'deaths')
#> Fetching WHO: "DEX_CMS/GHE_FULL"
#> # A tibble: 1 × 16
#>   iso3  location_name  year sex   age   cause_code cause_name measure   value
#>   <chr> <chr>         <int> <chr> <chr> <chr>      <chr>      <chr>     <dbl>
#> 1 PHL   Philippines    2023 TOTAL TOTAL 0          All Causes deaths  692891.
#> # ℹ 7 more variables: low <dbl>, high <dbl>, population <dbl>, unit <chr>,
#> #   level <int>, cause_group <chr>, rankable <lgl>
ghe_data(area = 'PHL', year = 2023, age = 'Y40T44',
         sex = c('FEMALE', 'MALE'), cause = 0, measure = 'death_rate')
#> Fetching WHO: "DEX_CMS/GHE_FULL"
#> # A tibble: 2 × 16
#>   iso3  location_name  year sex    age    cause_code cause_name measure    value
#>   <chr> <chr>         <int> <chr>  <chr>  <chr>      <chr>      <chr>      <dbl>
#> 1 PHL   Philippines    2023 FEMALE Y40T44 0          All Causes death_rate  236.
#> 2 PHL   Philippines    2023 MALE   Y40T44 0          All Causes death_rate  488.
#> # ℹ 7 more variables: low <dbl>, high <dbl>, population <dbl>, unit <chr>,
#> #   level <int>, cause_group <chr>, rankable <lgl>
# }
```
