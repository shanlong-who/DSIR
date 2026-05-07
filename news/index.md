# Changelog

## DSIR 0.5.0

### Breaking changes

- [`theme_dsi()`](https://shanlong-who.github.io/DSIR/reference/theme_dsi.md):
  removed the `color` argument and added `accent` instead. The semantics
  are different: `color` previously controlled text colour, while
  `accent` now controls axis line and tick colour. If you used
  `theme_dsi(color = X)` in 0.2.x, change to `theme_dsi(accent = X)` and
  note that the visual effect has shifted from “everywhere” to “axis
  only”. Text colour is now fixed to `grey20` to follow modern
  publication conventions.

### Bug fixes

- [`gho_data()`](https://shanlong-who.github.io/DSIR/reference/gho_data.md)
  now correctly handles long `area` vectors. Previously, passing more
  than ~22 ISO3 codes hit the upstream query string length limit and
  resulted in HTTP 400 errors. Switched from chained OR clauses to the
  OData `in` operator, which generates a much shorter URL and supports
  up to ~115 codes per call.

### New features

- New
  [`gho_clean()`](https://shanlong-who.github.io/DSIR/reference/gho_clean.md):
  post-processor for
  [`gho_data()`](https://shanlong-who.github.io/DSIR/reference/gho_data.md)
  output. Selects the useful columns and renames them to snake_case
  (`indicator`, `location`, `year`, `dim1`-`dim3`, `value`, `value_num`,
  `low`, `high`). Output schema is stable across indicators — missing
  columns are filled with `NA`. See
  [`?gho_clean`](https://shanlong-who.github.io/DSIR/reference/gho_clean.md)
  for details.

- New
  [`sdg_clean()`](https://shanlong-who.github.io/DSIR/reference/sdg_clean.md):
  counterpart for
  [`sdg_data()`](https://shanlong-who.github.io/DSIR/reference/sdg_data.md).
  Renames the SDG API columns to snake_case and flattens the `indicator`
  list-column. Returns `value`, `low`, and `high` as character to
  preserve non-numeric entries (`"<0.1"`, aggregate notes); coerce with
  [`as.numeric()`](https://rdrr.io/r/base/numeric.html) downstream. See
  [`?sdg_clean`](https://shanlong-who.github.io/DSIR/reference/sdg_clean.md)
  for details.

### Improvements

- [`theme_dsi()`](https://shanlong-who.github.io/DSIR/reference/theme_dsi.md)
  redesigned to follow modern publication conventions (BBC, OECD,
  Financial Times style):

  - Removed panel border; axis lines only on left and bottom
  - Removed vertical grid lines (kept horizontal only)
  - Lighter grid colour (`grey92`, was `grey85`)
  - Larger title and subtitle
  - Text colour standardised to `grey20`
  - Title left-aligned to plot edge
  - New `legend_position` argument

- [`gho_data()`](https://shanlong-who.github.io/DSIR/reference/gho_data.md)
  now infers `spatial_type = "country"` when `area` is provided without
  an explicit `spatial_type`. Pass `spatial_type` explicitly to silence
  the message.

- [`gho_data()`](https://shanlong-who.github.io/DSIR/reference/gho_data.md)
  now validates the `area` argument: must be a non-NA, non-empty
  character vector.

## DSIR 0.4.0

### New features

- New `who_countries` dataset: a tibble of all 194 WHO Member States
  with ISO3, ISO2, UN M49 numeric code, official and short names, WHO
  region, and a `is_pic` flag for the 14 Pacific Island Country Member
  States.

- New regional ISO3 character vectors for ergonomic filtering:
  `afro_cty`, `amro_cty`, `searo_cty`, `euro_cty`, `emro_cty`, plus
  `pic_cty`. All are derived from `who_countries` and stay consistent
  with the master table.

### Important data changes

- **`wpro_cty` now contains 28 countries (was 22 in 0.2.0).** This
  reflects the May 2025 World Health Assembly decision (EB156)
  reassigning Indonesia from the South-East Asia Region to the Western
  Pacific Region, along with Cook Islands and Niue, which are full WHO
  Member States but were previously omitted. Code that aggregates over
  `wpro_cty` (sums, counts, joins) will produce different results than
  under DSIR 0.2.x — this is intended.

### Internal

- Added `data-raw/who_countries.R` as the single source of truth for all
  country-related datasets. Editing one file regenerates the master
  tibble and all derived vectors.

## DSIR 0.3.0

### New features

- GHO and SDG network functions now return tibbles instead of plain data
  frames, improving printing of wide result tables. Tibbles inherit from
  data.frame, so existing code continues to work.

## DSIR 0.2.0

CRAN release: 2026-04-21

Initial CRAN submission. Renamed from `DSI` to avoid a name clash with
the existing CRAN `DSI` package.

### New features

- [`gho_dimensions()`](https://shanlong-who.github.io/DSIR/reference/gho_dimensions.md)
  returns the unique values of a dimension column for a given GHO
  indicator, to make it easier to discover which breakdowns (sex, age,
  region, etc.) are available before calling
  [`gho_data()`](https://shanlong-who.github.io/DSIR/reference/gho_data.md).
- [`sdg_targets()`](https://shanlong-who.github.io/DSIR/reference/sdg_targets.md)
  lists Sustainable Development Goal targets from the UN SDG API,
  complementing
  [`sdg_goals()`](https://shanlong-who.github.io/DSIR/reference/sdg_goals.md)
  and
  [`sdg_indicators()`](https://shanlong-who.github.io/DSIR/reference/sdg_indicators.md).

### Improvements

- [`theme_dsi()`](https://shanlong-who.github.io/DSIR/reference/theme_dsi.md)
  and
  [`dsi_flextable_defaults()`](https://shanlong-who.github.io/DSIR/reference/dsi_flextable_defaults.md)
  now default to the device / package default font (`base_family = ""`),
  so they work on systems where Cambria is not installed. Pass
  `base_family = "Cambria"` to get the original look.
- [`ggpie()`](https://shanlong-who.github.io/DSIR/reference/ggpie.md)
  gains input validation and uses tidy-evaluation helpers internally, so
  `R CMD check` no longer reports undefined global variables.
- `gho_*()` and `sdg_*()` now fail gracefully when the remote service is
  unreachable, per CRAN policy for packages that hit the network. They
  warn and return an empty data frame (or `NULL`) instead of raising a
  hard error.
- Full `roxygen2` help pages for every exported function, with
  cross-references between related functions.
- All runnable examples use `\donttest{}` (not `\dontrun{}`) for
  network-dependent code, so CRAN reviewers can opt into running them.
