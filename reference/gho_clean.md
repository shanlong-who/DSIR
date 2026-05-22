# Tidy a GHO Data Frame

Selects, renames, and type-casts the most useful columns from a GHO
observation table returned by
[`gho_data()`](https://shanlong-who.github.io/DSIR/reference/gho_data.md),
producing a compact tibble in the **unified DSIR cleaned-indicator
schema** — the same schema produced by
[`sdg_clean()`](https://shanlong-who.github.io/DSIR/reference/sdg_clean.md),
so the two outputs can be combined directly with
[`bind_indicators()`](https://shanlong-who.github.io/DSIR/reference/bind_indicators.md).

## Usage

``` r
gho_clean(df)
```

## Arguments

- df:

  A data frame returned by
  [`gho_data()`](https://shanlong-who.github.io/DSIR/reference/gho_data.md).

## Value

A [tibble](https://tibble.tidyverse.org/reference/tibble.html) with 15
columns: `source` (always `"gho"`), `id`, `indicator`, `location`,
`iso3`, `location_name`, `year`, `value`, `value_num`, `low`, `high`,
`series` (`NA`), `dim1`, `dim2`, `dim3`. Sorted by `location` then
`year`. Empty input returns an empty tibble with the same columns and
types.

## Details

The mapping (GHO source → unified column) is:

- `IndicatorCode` → `id`

- `IndicatorCode` resolved against the GHO indicator catalog →
  `indicator` (the human-readable name; cached at session level after
  the first call)

- `SpatialDim` → `location`; also `iso3` when it matches a WHO Member
  State, otherwise `iso3 = NA`

- `TimeDim` → `year` (integer)

- `Value` → `value` (character; raw)

- `NumericValue` → `value_num` (numeric)

- `Low`, `High` → `low`, `high` (numeric)

- `Dim1`, `Dim2`, `Dim3` → `dim1`, `dim2`, `dim3` (character)

The `series` column is always `NA` for GHO output (it is an SDG-only
concept). The `location_name` column is populated by looking up
`location` (an ISO3 code or a WHO region code) against the
[`who_countries`](https://shanlong-who.github.io/DSIR/reference/who_countries.md)
dataset and a hardcoded set of WHO regional names; locations that match
neither (e.g. non-Member State areas) are left as `NA`.

Source columns absent from `df` (e.g. `Low` / `High` for indicators
without confidence intervals) are filled with typed `NA`, so the output
always has the same 15 columns with the same column types.

The GHO data endpoint (`/api/{IndicatorCode}`) does not return
`IndicatorName`; that field lives on the catalog endpoint queried by
[`gho_indicators()`](https://shanlong-who.github.io/DSIR/reference/gho_indicators.md).
On the first call within an R session, `gho_clean()` fetches the catalog
once and caches it for the rest of the session, so the `indicator`
column carries the full human-readable indicator name. If the catalog
cannot be fetched (e.g. no network),
[`gho_indicators()`](https://shanlong-who.github.io/DSIR/reference/gho_indicators.md)
emits a warning and the `indicator` column falls back to `NA`.

## See also

[`gho_data()`](https://shanlong-who.github.io/DSIR/reference/gho_data.md),
[`sdg_clean()`](https://shanlong-who.github.io/DSIR/reference/sdg_clean.md),
[`bind_indicators()`](https://shanlong-who.github.io/DSIR/reference/bind_indicators.md).

## Examples

``` r
# \donttest{
gho_data("NCDMORT3070", spatial_type = "country") |>
  gho_clean()
#> Fetching:
#> <https://ghoapi.azureedge.net/api/NCDMORT3070?$filter=SpatialDimType%20eq%20%27COUNTRY%27>
#> # A tibble: 12,210 × 15
#>    source id        indicator location iso3  location_name  year value value_num
#>    <chr>  <chr>     <chr>     <chr>    <chr> <chr>         <int> <chr>     <dbl>
#>  1 gho    NCDMORT3… Probabil… AFG      AFG   Afghanistan    2000 43.2…      43.2
#>  2 gho    NCDMORT3… Probabil… AFG      AFG   Afghanistan    2000 40.0…      40  
#>  3 gho    NCDMORT3… Probabil… AFG      AFG   Afghanistan    2000 46.7…      46.7
#>  4 gho    NCDMORT3… Probabil… AFG      AFG   Afghanistan    2001 46.8…      46.8
#>  5 gho    NCDMORT3… Probabil… AFG      AFG   Afghanistan    2001 40.5…      40.5
#>  6 gho    NCDMORT3… Probabil… AFG      AFG   Afghanistan    2001 43.5…      43.5
#>  7 gho    NCDMORT3… Probabil… AFG      AFG   Afghanistan    2002 40.3…      40.3
#>  8 gho    NCDMORT3… Probabil… AFG      AFG   Afghanistan    2002 43.1…      43.1
#>  9 gho    NCDMORT3… Probabil… AFG      AFG   Afghanistan    2002 46.0…      46  
#> 10 gho    NCDMORT3… Probabil… AFG      AFG   Afghanistan    2003 40.0…      40  
#> # ℹ 12,200 more rows
#> # ℹ 6 more variables: low <dbl>, high <dbl>, series <chr>, dim1 <chr>,
#> #   dim2 <chr>, dim3 <chr>
# }
```
