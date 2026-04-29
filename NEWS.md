# DSIR 0.5.0

## Bug fixes

* `gho_data()` now correctly handles long `area` vectors. Previously,
  passing 25+ ISO3 codes hit the upstream query string length limit and
  resulted in HTTP 400 errors. Switched from chained OR clauses to the
  OData `in` operator, which generates a much shorter URL and supports
  up to ~115 codes per call.

## New features

* New `gho_clean()`: a small post-processor for [gho_data()] output
  that selects and renames the most useful columns
  (`IndicatorCode`, `SpatialDim`, `TimeDim`, `Dim1`-`Dim3`,
  `NumericValue`, `Low`, `High`) into a compact tibble with snake_case
  names (`indicator`, `location`, `year`, `dim1`-`dim3`, `value`,
  `low`, `high`), sorted by `location` and `year`. Missing source
  columns (e.g. `Low` / `High` for indicators without confidence
  intervals) are filled with `NA`, so the output schema is stable.

* New `sdg_clean()`: counterpart for [sdg_data()] output. Renames
  `goal`, `target`, `indicator`, `series`, `geoAreaCode`,
  `geoAreaName`, `timePeriodStart`, `value`, `lowerBound`,
  `upperBound` to snake_case names (`goal`, `target`, `indicator`,
  `series`, `location`, `location_name`, `year`, `value`, `low`,
  `high`) and sorts by `location` then `year`. The `indicator`
  list-column from the SDG API is flattened to its first code.
  Missing source columns are filled with `NA`. `value`, `low` and
  `high` are returned as character because the SDG API returns
  non-numeric values for some rows; coerce with `as.numeric()`
  downstream.

* `gho_data()` now infers `spatial_type = "country"` when `area` is
  provided without an explicit `spatial_type`. Pass `spatial_type`
  explicitly to silence the message.

* Added input validation for `area`: must be non-NA, non-empty character
  vector.

# DSIR 0.4.0

## New features

* New `who_countries` dataset: a tibble of all 194 WHO Member States with
  ISO3, ISO2, UN M49 numeric code, official and short names, WHO region,
  and a `is_pic` flag for the 14 Pacific Island Country Member States.

* New regional ISO3 character vectors for ergonomic filtering:
  `afro_cty`, `amro_cty`, `searo_cty`, `euro_cty`, `emro_cty`, plus
  `pic_cty`. All are derived from `who_countries` and stay consistent
  with the master table.

## Important data changes

* **`wpro_cty` now contains 28 countries (was 22 in 0.2.0).** This
  reflects the May 2025 World Health Assembly decision (EB156) reassigning
  Indonesia from the South-East Asia Region to the Western Pacific Region,
  along with Cook Islands and Niue, which are full WHO Member States but
  were previously omitted. Code that aggregates over `wpro_cty` (sums,
  counts, joins) will produce different results than under DSIR 0.2.x —
  this is intended.

## Internal

* Added `data-raw/who_countries.R` as the single source of truth for all
  country-related datasets. Editing one file regenerates the master tibble
  and all derived vectors.

# DSIR 0.3.0

## New features

* GHO and SDG network functions now return tibbles instead of plain
  data frames, improving printing of wide result tables. Tibbles
  inherit from data.frame, so existing code continues to work.

# DSIR 0.2.0

Initial CRAN submission. Renamed from `DSI` to avoid a name clash
with the existing CRAN `DSI` package.

## New features

* `gho_dimensions()` returns the unique values of a dimension
  column for a given GHO indicator, to make it easier to discover
  which breakdowns (sex, age, region, etc.) are available before
  calling `gho_data()`.
* `sdg_targets()` lists Sustainable Development Goal targets from
  the UN SDG API, complementing `sdg_goals()` and
  `sdg_indicators()`.

## Improvements

* `theme_dsi()` and `dsi_flextable_defaults()` now default to the
  device / package default font (`base_family = ""`), so they work
  on systems where Cambria is not installed. Pass
  `base_family = "Cambria"` to get the original look.
* `ggpie()` gains input validation and uses tidy-evaluation
  helpers internally, so `R CMD check` no longer reports
  undefined global variables.
* `gho_*()` and `sdg_*()` now fail gracefully when the remote
  service is unreachable, per CRAN policy for packages that hit
  the network. They warn and return an empty data frame (or
  `NULL`) instead of raising a hard error.
* Full `roxygen2` help pages for every exported function, with
  cross-references between related functions.
* All runnable examples use `\donttest{}` (not `\dontrun{}`) for
  network-dependent code, so CRAN reviewers can opt into running
  them.
