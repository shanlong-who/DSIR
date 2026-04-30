# List SDG Targets

Fetches the list of SDG targets from the UN SDG API.

## Usage

``` r
sdg_targets(include_children = FALSE)
```

## Arguments

- include_children:

  Logical. Include indicators nested under each target? Default `FALSE`.

## Value

A list (or [tibble](https://tibble.tidyverse.org/reference/tibble.html))
of SDG targets, or `NULL` when the service is unreachable.

## See also

[`sdg_goals()`](https://shanlong-who.github.io/DSIR/reference/sdg_goals.md),
[`sdg_indicators()`](https://shanlong-who.github.io/DSIR/reference/sdg_indicators.md).

## Examples

``` r
if (FALSE) { # \dontrun{
sdg_targets()
} # }
```
