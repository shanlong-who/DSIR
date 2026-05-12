# Changelog

## DSIR 0.6.0

### Behavior changes

- [`theme_dsi()`](https://shanlong-who.github.io/DSIR/reference/theme_dsi.md)
  now draws grid lines in both directions by default. New `grid`
  argument controls direction — pass `grid = "y"` to restore the
  previous look (horizontal grid only). This change fixes the visual
  glitch where horizontal bar charts (made with
  [`coord_flip()`](https://ggplot2.tidyverse.org/reference/coord_flip.html))
  had grid lines running parallel to the bars instead of crossing them.

- [`theme_dsi_facet()`](https://shanlong-who.github.io/DSIR/reference/theme_dsi_facet.md)
  gains a `grid` argument mirroring
  [`theme_dsi()`](https://shanlong-who.github.io/DSIR/reference/theme_dsi.md)’s
  — defaults to `"both"` (unchanged behaviour); pass `"y"`, `"x"`, or
  `"none"` to control which direction(s) the grid runs.

### New features

- New
  [`scale_y_dsi_col()`](https://shanlong-who.github.io/DSIR/reference/scale_dsi_col.md)
  and
  [`scale_x_dsi_col()`](https://shanlong-who.github.io/DSIR/reference/scale_dsi_col.md)
  — drop-in replacements for
  [`scale_y_continuous()`](https://ggplot2.tidyverse.org/reference/scale_continuous.html)
  /
  [`scale_x_continuous()`](https://ggplot2.tidyverse.org/reference/scale_continuous.html)
  that remove the lower axis expansion, so columns in bar charts sit
  flush with the axis (WHO publication style).

- New
  [`theme_dsi_facet()`](https://shanlong-who.github.io/DSIR/reference/theme_dsi_facet.md)
  for faceted plots — uses panel borders, light-grey strip backgrounds,
  and bilateral grid lines.

- New GHO data-availability helpers, for screening indicator / filter
  combinations before pulling a full result set:

  - [`gho_has_data()`](https://shanlong-who.github.io/DSIR/reference/gho_has_data.md)
    returns `TRUE` / `FALSE` / `NA` for whether the server has any rows
    for an indicator and filter.
  - [`gho_count()`](https://shanlong-who.github.io/DSIR/reference/gho_count.md)
    returns the row count the same filter would yield, using the OData
    `$count=true` endpoint (no rows transferred).
  - [`gho_coverage()`](https://shanlong-who.github.io/DSIR/reference/gho_coverage.md)
    returns a tibble with `location`, `year_min`, `year_max`, `n_obs`
    per area, using `$select=SpatialDim,TimeDim` to keep the payload
    small.

- [`sdg_indicators()`](https://shanlong-who.github.io/DSIR/reference/sdg_indicators.md)
  gains a `search` parameter, mirroring `gho_indicators(search)`.
  Accepts either a single string (split on whitespace into terms) or a
  character vector (terms used verbatim). All terms must match (AND
  semantics, case-insensitive substring on the indicator `description`
  column). The filter is applied client-side because the UN SDG
  `/Indicator/List` endpoint is not OData and exposes no server-side
  search parameter; the list is small enough (~250 rows) that this is
  cheap.

- New
  [`sdg_coverage()`](https://shanlong-who.github.io/DSIR/reference/sdg_coverage.md):
  series-exploration helper for SDG indicators. An SDG indicator
  (e.g. `"3.4.1"`) typically contains several series stratified by sex,
  age, or cause;
  [`sdg_coverage()`](https://shanlong-who.github.io/DSIR/reference/sdg_coverage.md)
  returns a tibble of `(location, series, year_min, year_max, n_obs)` so
  you can see which series exist and how each is covered. This is
  intentionally framed as series-exploration rather than as a
  [`gho_has_data()`](https://shanlong-who.github.io/DSIR/reference/gho_has_data.md)
  /
  [`gho_count()`](https://shanlong-who.github.io/DSIR/reference/gho_count.md)-style
  availability precheck — SDG data is generally complete, so those
  screening helpers are deliberately not provided for SDG.

- New
  [`geomean()`](https://shanlong-who.github.io/DSIR/reference/geomean.md):
  geometric mean of a numeric vector, with optional weights via `w`.
  Useful for aggregating ratio-based health indicators such as UHC
  service-coverage tracers. Handles NA (removed by default), zeros
  (returns 0), and negative values (warns and returns NaN).

- New
  [`iso3_to_m49()`](https://shanlong-who.github.io/DSIR/reference/iso3_to_m49.md):
  maps ISO3 country codes to UN M49 numeric codes using the bundled
  `who_countries` dataset. Non-Member codes return `NA`. Input is
  case-insensitive.

- [`sdg_data()`](https://shanlong-who.github.io/DSIR/reference/sdg_data.md)
  and
  [`sdg_coverage()`](https://shanlong-who.github.io/DSIR/reference/sdg_coverage.md)
  now accept ISO3 codes directly for the `area` argument; M49 codes
  continue to work unchanged. DSIR’s regional vectors (`wpro_cty`,
  `afro_cty`, etc.) can now be passed directly to SDG functions,
  matching the existing GHO workflow. ISO3 and M49 cannot be mixed
  within a single call.

- New
  [`iso3_to_region()`](https://shanlong-who.github.io/DSIR/reference/iso3_to_region.md):
  maps ISO3 country codes to WHO region codes (`"AFR"`, `"AMR"`,
  `"SEAR"`, `"EUR"`, `"EMR"`, `"WPR"`) using the bundled `who_countries`
  dataset. Pass `long = TRUE` for full names (`"Western Pacific"`,
  etc.). Non-Member codes (e.g. Associate Members like `"PRI"`) return
  `NA`. Stays in sync with WHO governance changes reflected in DSIR —
  e.g. Indonesia in WPR since EB156 (May 2025).

### Bug fixes

- [`sdg_data()`](https://shanlong-who.github.io/DSIR/reference/sdg_data.md):
  year filtering (`year_from` / `year_to`) is now applied client-side.
  The UN SDG API’s server-side `timePeriodStart` / `timePeriodEnd`
  parameters were causing HTTP 500 errors and ~30x slowdowns on at least
  some indicator/area combinations (e.g. `3.2.1` with `area = "608"`);
  client-side filtering avoids the issue. User-facing behaviour is
  unchanged.
  [`sdg_coverage()`](https://shanlong-who.github.io/DSIR/reference/sdg_coverage.md)
  inherits the fix automatically because it dispatches through
  [`sdg_data()`](https://shanlong-who.github.io/DSIR/reference/sdg_data.md).

- `.sdg_get()` now sets a 20-second per-request timeout and exponential
  backoff between retries (`backoff = ~ min(2^.x, 30)`), so a hung
  upstream request cannot stall a call indefinitely.

- The internal pagination helper `.gho_get()` previously produced a
  spurious 1-row, 1-column tibble (`V1` of type list) when the server
  returned an empty result set (`value = []`). Empty `value` chunks are
  now skipped and an empty tibble is returned when no rows accumulate.
  This affected
  [`gho_data()`](https://shanlong-who.github.io/DSIR/reference/gho_data.md)
  on filters with no matches (e.g. an indicator + area combination GHO
  has no data for) and `gho_indicators(search)` when no indicator name
  matched the search term.

- [`sdg_data()`](https://shanlong-who.github.io/DSIR/reference/sdg_data.md)
  now correctly filters when more than one indicator or area code is
  supplied. The SDG API expects multi-value parameters as repeated keys
  (`indicator=A&indicator=B`), but the previous implementation joined
  them with commas (`indicator=A,B`); the API silently dropped the
  filter and returned all rows. Single-value calls were unaffected.

- [`sdg_data()`](https://shanlong-who.github.io/DSIR/reference/sdg_data.md)
  no longer errors with `duplicate 'row.names' are not allowed` when the
  result spans more than one page. The per-page row-name handling has
  been simplified.

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
  (`id`, `location`, `year`, `dim1`-`dim3`, `value`, `value_num`, `low`,
  `high`, `indicator`). Output schema is stable across indicators —
  missing columns are filled with `NA`. See
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
