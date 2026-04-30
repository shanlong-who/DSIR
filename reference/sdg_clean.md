# Tidy an SDG Data Frame

Selects and renames the most useful columns from an SDG observation
table returned by
[`sdg_data()`](https://shanlong-who.github.io/DSIR/reference/sdg_data.md),
producing a compact tibble suitable for downstream analysis.

## Usage

``` r
sdg_clean(df)
```

## Arguments

- df:

  A data frame returned by
  [`sdg_data()`](https://shanlong-who.github.io/DSIR/reference/sdg_data.md).

## Value

A [tibble](https://tibble.tidyverse.org/reference/tibble.html) with
columns `goal`, `target`, `indicator`, `series`, `location`,
`location_name`, `year`, `value`, `low`, `high`, sorted by `location`
then `year`. An empty input returns an empty tibble with the same
columns.

## Details

The mapping is:

- `goal` -\> `goal`

- `target` -\> `target`

- `indicator` -\> `indicator` (flattened to the first code when the
  source column is a list)

- `series` -\> `series`

- `geoAreaCode` -\> `location`

- `geoAreaName` -\> `location_name`

- `timePeriodStart` -\> `year`

- `value` -\> `value`

- `lowerBound` -\> `low`

- `upperBound` -\> `high`

Source columns that are absent from `df` are filled with `NA`, so the
output always has the same ten columns. `value`, `low` and `high` are
returned in their original character form because the SDG API returns
non-numeric values (e.g. `"<0.1"` or aggregate notes) for some rows;
coerce with [`as.numeric()`](https://rdrr.io/r/base/numeric.html)
downstream when appropriate.

## See also

[`sdg_data()`](https://shanlong-who.github.io/DSIR/reference/sdg_data.md).

## Examples

``` r
if (FALSE) { # \dontrun{
sdg_data("3.2.1", area = "156", year_from = 2015) |>
  sdg_clean()
} # }
```
