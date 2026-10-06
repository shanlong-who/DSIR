# Put GHE Estimates in the Unified DSIR Schema

Converts
[`ghe_data()`](https://shanlong-who.github.io/DSIR/reference/ghe_data.md)
output for
[`bind_indicators()`](https://shanlong-who.github.io/DSIR/reference/bind_indicators.md).
A GHE cause is `id`, the selected measure is `series`, sex is `dim1`,
and age is `dim2`. Use `keep_dimensions = TRUE` to retain named sex/age,
cause hierarchy and unit, preventing information loss when combining
multiple measures.

## Usage

``` r
ghe_clean(df, keep_dimensions = FALSE)
```

## Arguments

- df:

  A data frame from
  [`ghe_data()`](https://shanlong-who.github.io/DSIR/reference/ghe_data.md).

- keep_dimensions:

  Append `dim_sex`, `dim_age`, `cause_name`, `cause_group`,
  `cause_level`, `rankable`, `unit`, and `population`? Default `FALSE`
  keeps the 15-column core.

## Value

A tibble in the unified schema, with `source = "ghe"`.

## Examples

``` r
# \donttest{
ghe_data('PHL', year = 2023, age = 'TOTAL', sex = 'TOTAL', cause = 0,
         measure = 'deaths') |> ghe_clean(keep_dimensions = TRUE)
#> Fetching WHO: "DEX_CMS/REF_SEX_COD"
#> Fetching WHO: "DEX_CMS/GHE_FULL"
#> Fetching WHO: "DEX_CMS/REF_AGE_COD"
#> Fetching WHO: "DEX_CMS/GHE_FULL"
#> Fetching WHO: "DEX_CMS/GHE_FULL"
#> # A tibble: 1 × 23
#>   source id    indicator      location iso3  location_name  year value value_num
#>   <chr>  <chr> <chr>          <chr>    <chr> <chr>         <int> <chr>     <dbl>
#> 1 ghe    0     All Causes: d… PHL      PHL   Philippines    2023 6928…   692891.
#> # ℹ 14 more variables: low <dbl>, high <dbl>, series <chr>, dim1 <chr>,
#> #   dim2 <chr>, dim3 <chr>, dim_sex <chr>, dim_age <chr>, cause_name <chr>,
#> #   cause_group <chr>, cause_level <int>, rankable <lgl>, unit <chr>,
#> #   population <dbl>
# }
```
