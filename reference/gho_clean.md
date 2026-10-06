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
gho_clean(df, keep_dimensions = FALSE, keep_metadata = FALSE)
```

## Arguments

- df:

  A data frame returned by
  [`gho_data()`](https://shanlong-who.github.io/DSIR/reference/gho_data.md).

- keep_dimensions:

  Logical. Append `dim1_type`, `dim2_type`, and `dim3_type` from the
  source's `Dim1Type`, `Dim2Type`, and `Dim3Type`? Default `FALSE`.
  Types are kept per row: one indicator can use the same position for
  different dimensions. No type is guessed from a code's spelling, and
  missing types remain `NA`. xMart output also retains all named source
  dimensions as `dim_*` character columns.

- keep_metadata:

  Logical. Retain source context? Default `FALSE`. With `TRUE`, appends
  character columns `observation_id`, `spatial_type`, `time_type`,
  `data_source_type`, `data_source`, `updated`, `parent_location`,
  `parent_location_name`, `time_detail`, `time_start`, and `time_end`,
  copied from the raw API fields. Raw `Comments` are kept as
  `footnotes`, a list-column of character vectors. Missing scalar fields
  are `NA`; missing list fields are empty character vectors. This option
  is independent of `keep_dimensions`. Unit and dimension labels are not
  inferred. xMart output also retains `unit`, `measure_field`,
  `spatial_type_source`, and a `who_provenance` attribute. Retaining
  these fields makes no extra network requests beyond the usual
  indicator-name lookup.

## Value

A [tibble](https://tibble.tidyverse.org/reference/tibble.html) with 15
core columns: `source` (always `"gho"`), `id`, `indicator`, `location`,
`iso3`, `location_name`, `year`, `value`, `value_num`, `low`, `high`,
`series` (`NA`), `dim1`, `dim2`, `dim3`. Sorted by `location` then
`year`. Empty input returns an empty tibble with the same columns and
types. Optional dimension types and metadata follow the core columns.

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
concept; GHE uses it for measure codes). The `location_name` column is
populated by looking up `location` (an ISO3 code or a WHO region code)
against the
[`who_countries`](https://shanlong-who.github.io/DSIR/reference/who_countries.md)
dataset and a hardcoded set of WHO regional names; other locations use a
published `SpatialName` when available, otherwise they remain `NA`.

Source columns absent from `df` (e.g. `Low` / `High` for indicators
without confidence intervals) are filled with typed `NA`, so the default
output always has the same 15 columns with the same column types.

xMart supplies indicator labels through its official directory. Legacy
observations without an `IndicatorName` use
[`gho_indicators()`](https://shanlong-who.github.io/DSIR/reference/gho_indicators.md).
For such input, on the first call within an R session, `gho_clean()`
fetches the catalog once and caches it for the rest of the session, so
the `indicator` column carries the full human-readable indicator name.
If the catalog cannot be fetched (e.g. no network),
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
#> Fetching WHO: "DATA_/RELAY_WHS"
#> Fetching WHO: "DATA_/RELAY_WHS"
#> Fetching WHO: "DATA_/RELAY_WHS"
#> # A tibble: 12,208 × 15
#>    source id        indicator location iso3  location_name  year value value_num
#>    <chr>  <chr>     <chr>     <chr>    <chr> <chr>         <int> <chr>     <dbl>
#>  1 gho    NCDMORT3… Probabil… AFG      AFG   Afghanistan    2000 40         40  
#>  2 gho    NCDMORT3… Probabil… AFG      AFG   Afghanistan    2000 46.7       46.7
#>  3 gho    NCDMORT3… Probabil… AFG      AFG   Afghanistan    2000 43.2       43.2
#>  4 gho    NCDMORT3… Probabil… AFG      AFG   Afghanistan    2001 40.5       40.5
#>  5 gho    NCDMORT3… Probabil… AFG      AFG   Afghanistan    2001 46.8       46.8
#>  6 gho    NCDMORT3… Probabil… AFG      AFG   Afghanistan    2001 43.5       43.5
#>  7 gho    NCDMORT3… Probabil… AFG      AFG   Afghanistan    2002 40.3       40.3
#>  8 gho    NCDMORT3… Probabil… AFG      AFG   Afghanistan    2002 46         46  
#>  9 gho    NCDMORT3… Probabil… AFG      AFG   Afghanistan    2002 43.1       43.1
#> 10 gho    NCDMORT3… Probabil… AFG      AFG   Afghanistan    2003 40         40  
#> # ℹ 12,198 more rows
#> # ℹ 6 more variables: low <dbl>, high <dbl>, series <chr>, dim1 <chr>,
#> #   dim2 <chr>, dim3 <chr>
# }
```
