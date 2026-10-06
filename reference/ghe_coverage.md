# Summarise Global Health Estimates Coverage

Fetches only identifiers, geography and year, respecting sex, age and
cause filters. Counts refer to source observations before measure
pivoting.

## Usage

``` r
ghe_coverage(
  area = NULL,
  year = NULL,
  year_from = NULL,
  year_to = NULL,
  sex = NULL,
  age = NULL,
  cause = NULL
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

## Value

A tibble with `location`, `year_min`, `year_max`, `n_years`, and
`n_obs`. Empty selections or failures return the same typed schema.

## Examples

``` r
# \donttest{
ghe_coverage(area = 'PHL', age = 'TOTAL', sex = 'TOTAL', cause = 0)
#> Fetching WHO: "DEX_CMS/GHE_FULL"
#> # A tibble: 1 × 5
#>   location year_min year_max n_years n_obs
#>   <chr>       <int>    <int>   <int> <int>
#> 1 PHL          2000     2023      24    24
# }
```
