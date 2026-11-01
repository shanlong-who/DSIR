# Plot a Cleaned DSIR Indicator

Draw an annual trend or a same-year country comparison from a
[dsir_data](https://shanlong-who.github.io/DSIR/reference/as_dsir_data.md)
object. All checks and plotting are offline.

## Usage

``` r
# S3 method for class 'dsir_data'
plot(
  x,
  y = NULL,
  ...,
  type = c("trend", "compare"),
  country = NULL,
  year = NULL,
  group = NULL,
  facet = NULL,
  interval = FALSE
)
```

## Arguments

- x:

  A `dsir_data` object, normally returned by
  [`gho_clean()`](https://shanlong-who.github.io/DSIR/reference/gho_clean.md),
  [`sdg_clean()`](https://shanlong-who.github.io/DSIR/reference/sdg_clean.md)
  or
  [`ghe_clean()`](https://shanlong-who.github.io/DSIR/reference/ghe_clean.md).

- y:

  Unused; must be `NULL`.

- ...:

  Reserved; must be empty. Customize the returned ggplot with `+`.

- type:

  Required: `"trend"` for points and annual line segments, or
  `"compare"` for horizontal country points at one common year.

- country:

  Optional character vector of ISO3 codes present in `x`. This first
  version supports countries, not regional aggregates.

- year:

  Optional integer-valued year vector. For comparisons, exactly one year
  must be selected or already present in `x`.

- group:

  Optional column name for colour groups, such as `"dim1"` or
  `"dim_sex"`. Trends with multiple countries default to `"iso3"`.

- facet:

  Optional column name for panels, such as `"iso3"` or `"dim_age"`.
  Other population dimensions must be constant.

- interval:

  Logical. Show reported `low` and `high` bounds as ranges? Default
  `FALSE`. No intervals are calculated, and no confidence level is
  assumed. Incomplete bounds are omitted with a warning; invalid bounds
  cause an error.

## Value

A standard ggplot object using
[`theme_dsi()`](https://shanlong-who.github.io/DSIR/reference/theme_dsi.md)
or
[`theme_dsi_facet()`](https://shanlong-who.github.io/DSIR/reference/theme_dsi_facet.md).
No aggregation, unit conversion, interpolation or data retrieval occurs.

## Details

Select one source, backend, indicator, series/measure and unit before
plotting. Use normal row filtering to select other dimensions. Unmapped
population dimensions must be constant even when there is only one row
per country/year. Recorded aliases, such as GHE `dim1` and `dim_sex`,
may represent the same dimension. Every country/year/group/panel
position must be unique; duplicate observations cause an error.

Cleaning metadata retains constant context without adding table columns.
If varying dimensions or units were omitted, clean the original data
again with `keep_dimensions = TRUE` and, for GHO/SDG,
`keep_metadata = TRUE`. Filtering the compact table cannot recover the
missing row identities. Unknown units are labelled explicitly. Metadata
is evidence about the supplied data, not a certification of
comparability or completeness.

Changes to plot-relevant fields marked `needs_review` prevent automatic
plotting. Unrelated added flags or notes do not. Review derived measures
and use explicit ggplot mappings for analyses outside this contract.
Missing/non-finite estimates are omitted with a warning. Trends break
across missing estimates and gaps greater than one year, without filling
missing years. Known non-annual or truncated time periods are rejected.

## Examples

``` r
raw <- tibble::tibble(
  IndicatorCode = "EXAMPLE", IndicatorName = "Illustrative indicator",
  SpatialDim = rep(c("PHL", "LAO"), each = 3),
  TimeDim = rep(2021:2023, 2), NumericValue = c(12, 11, 10, 15, 14, 13),
  Unit = "percent", Dim1 = "SEX_BTSX", Dim1Type = "SEX"
)
data.clean <- gho_clean(raw)
plot(data.clean, type = "trend")
plot(data.clean, type = "compare", year = 2023)
```
