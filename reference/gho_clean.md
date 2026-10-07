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
  `provider` (`"legacy"` or `"xmart"`) from recorded retrieval
  provenance; unknown origins remain `NA`, never the current session
  setting. Also appends character columns `observation_id`,
  `spatial_type`, `time_type`, `data_source_type`, `data_source`,
  `updated`, `parent_location`, `parent_location_name`, `time_detail`,
  `time_start`, and `time_end`, copied from the raw API fields. Raw
  `Comments` are kept as `footnotes`, a list-column of character
  vectors. Missing scalar fields are `NA`; missing list fields are empty
  character vectors. This option is independent of `keep_dimensions`.
  Unit and dimension labels are not inferred. xMart output also retains
  `unit`, `measure_field`, and `spatial_type_source`. Both backends
  preserve a `who_provenance` attribute, including with the default
  15-column output. Retaining these fields makes no extra network
  requests beyond the usual indicator-name lookup.

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
[`gho_indicators()`](https://shanlong-who.github.io/DSIR/reference/gho_indicators.md)
with the backend recorded in their `Provider` column or `who_provenance`
attribute, even if the session default has changed since retrieval.
Older/imported data without provenance use the session default for this
label lookup. For such input, on the first call within an R session,
`gho_clean()` fetches the catalog once and caches it for the rest of the
session, so the `indicator` column carries the full human-readable
indicator name. If the catalog cannot be fetched (e.g. no network),
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
#> Waiting 2s for retry backoff ■■■■■■■■■■■■■■■                 
#> Waiting 2s for retry backoff ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■  
#> Waiting 4s for retry backoff ■■■■■■■■                        
#> Waiting 4s for retry backoff ■■■■■■■■■■■■■■■■■■■■■■■■■■■     
#> Waiting 4s for retry backoff ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■  
#> Warning: GHO request failed.
#> ℹ URL:
#>   <https://ghoapi.azureedge.net/api/NCDMORT3070?$filter=SpatialDimType%20eq%20%27COUNTRY%27>
#> ✖ HTTP 502 Bad Gateway.
#> # A tibble: 0 × 15
#> # ℹ 15 variables: source <chr>, id <chr>, indicator <chr>, location <chr>,
#> #   iso3 <chr>, location_name <chr>, year <int>, value <chr>, value_num <dbl>,
#> #   low <dbl>, high <dbl>, series <chr>, dim1 <chr>, dim2 <chr>, dim3 <chr>
# }
```
