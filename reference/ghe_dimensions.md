# Explore Global Health Estimates Dimensions

Retrieves official references and small, filtered code-list slices from
WHO's public xMart GHE table. Results are cached in memory for ten
minutes.

## Usage

``` r
ghe_dimensions(dimension = "measure")
```

## Arguments

- dimension:

  One of `"area"`, `"year"`, `"sex"`, `"age"`, `"cause"`, or
  `"measure"`. Default `"measure"`.

## Value

A tibble of `code` and `label`. Cause results include hierarchy fields.
Measures include their provider field and unit. Missing official labels
remain `NA`. Countries, ages and causes describe the latest GHE year;
use
[`ghe_coverage()`](https://shanlong-who.github.io/DSIR/reference/ghe_coverage.md)
to verify a specific selection.

## See also

[`ghe_data()`](https://shanlong-who.github.io/DSIR/reference/ghe_data.md),
[`ghe_causes()`](https://shanlong-who.github.io/DSIR/reference/ghe_causes.md),
[`ghe_coverage()`](https://shanlong-who.github.io/DSIR/reference/ghe_coverage.md)

## Examples

``` r
# \donttest{
ghe_dimensions('sex')
ghe_dimensions('age')
ghe_dimensions('measure')
# }
```
