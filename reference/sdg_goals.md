# List SDG Goals

Fetches the list of Sustainable Development Goals from the UN SDG API.

## Usage

``` r
sdg_goals(include_children = FALSE)
```

## Arguments

- include_children:

  Logical. Include targets and indicators nested under each goal?
  Default `FALSE`.

## Value

A list (or [tibble](https://tibble.tidyverse.org/reference/tibble.html))
of SDG goals, or `NULL` when the service is unreachable.

## See also

[`sdg_targets()`](https://shanlong-who.github.io/DSIR/reference/sdg_targets.md),
[`sdg_indicators()`](https://shanlong-who.github.io/DSIR/reference/sdg_indicators.md),
[`sdg_data()`](https://shanlong-who.github.io/DSIR/reference/sdg_data.md).

## Examples

``` r
if (FALSE) { # \dontrun{
sdg_goals()
sdg_goals(include_children = TRUE)
} # }
```
