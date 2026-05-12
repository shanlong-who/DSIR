# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working
with code in this repository.

## What this repo is

`DSIR` is a small R package (“Data Science Infrastructure for Global
Health in R”), targeted at CRAN. It provides:

- A `ggplot2` theme (`theme_dsi`) and `flextable` defaults helper
  (`dsi_flextable_defaults`)
- A pie-chart wrapper (`ggpie`)
- Bundled WHO Member State data: the `who_countries` tibble plus
  regional ISO3 vectors (`wpro_cty`, `afro_cty`, `amro_cty`,
  `searo_cty`, `euro_cty`, `emro_cty`, `pic_cty`) and lookup helpers
  ([`iso3_to_region()`](https://shanlong-who.github.io/DSIR/reference/iso3_to_region.md),
  [`iso3_to_m49()`](https://shanlong-who.github.io/DSIR/reference/iso3_to_m49.md))
- [`geomean()`](https://shanlong-who.github.io/DSIR/reference/geomean.md)
  for ratio-based indicator aggregation
- Thin clients for the WHO Global Health Observatory OData API
  (`gho_indicators`, `gho_data`, `gho_dimensions`, `gho_clean`, plus the
  availability helpers `gho_has_data`, `gho_count`, `gho_coverage`)
- Thin clients for the UN SDG API (`sdg_goals`, `sdg_targets`,
  `sdg_indicators`, `sdg_areas`, `sdg_data`, `sdg_clean`, plus the
  series-exploration helper `sdg_coverage`)

The package is CRAN-bound, so conventions below are driven by
`R CMD check` and CRAN policy, not just taste.

## Current development state — 0.6.0 in preparation (last updated 2026-05-12)

Version bumped to 0.6.0 in `DESCRIPTION`. All planned code is written,
tested, exported, and described in `NEWS.md`. README and vignette are
updated to integrate every new function. **The full release is
uncommitted on `main`**; `devtools::check()` is clean (0 errors / 0
warnings / 0 notes). Resume from a `git status` to see what is staged.

### What was added across 0.6.0

GHO availability helpers (screening before a full download): -
[`gho_has_data()`](https://shanlong-who.github.io/DSIR/reference/gho_has_data.md)
— `TRUE` / `FALSE` / `NA` for whether the server has any rows. -
[`gho_count()`](https://shanlong-who.github.io/DSIR/reference/gho_count.md)
— row count via OData `$count=true` (no rows transferred). -
[`gho_coverage()`](https://shanlong-who.github.io/DSIR/reference/gho_coverage.md)
— `(location, year_min, year_max, n_obs)` per area, using
`$select=SpatialDim,TimeDim` to keep the payload small.

SDG additions: - `sdg_indicators(search = NULL)` — gains a keyword
filter mirroring
[`gho_indicators()`](https://shanlong-who.github.io/DSIR/reference/gho_indicators.md).
AND semantics; case-insensitive substring match on the indicator
`description`. Applied **client-side** (`grepl(..., fixed = TRUE)`)
because the UN SDG `/Indicator/List` endpoint is not OData and exposes
no server-side search parameter; the catalog is small (~250 rows).
Validation runs before the network call so it is unit-testable offline.
Default `search = NULL` preserves the previous behaviour exactly. -
[`sdg_coverage()`](https://shanlong-who.github.io/DSIR/reference/sdg_coverage.md)
— series-exploration helper. Groups by `(location, series)`, not just
`(location)`. Returns `(location, series, year_min, year_max, n_obs)`.
Intentional asymmetry vs. GHO: no `sdg_has_data()` or `sdg_count()` is
provided because SDG data is generally complete, so per-series
exploration is the more useful pre-analysis question. -
[`sdg_data()`](https://shanlong-who.github.io/DSIR/reference/sdg_data.md)
and
[`sdg_coverage()`](https://shanlong-who.github.io/DSIR/reference/sdg_coverage.md)
now accept ISO3 codes for `area` — converted internally via
[`iso3_to_m49()`](https://shanlong-who.github.io/DSIR/reference/iso3_to_m49.md)
through the internal `.resolve_area()` helper. M49 still works. ISO3 ↔︎
M49 cannot be mixed within one call. This lets DSIR’s regional vectors
(`wpro_cty`, etc.) be passed straight through, matching the GHO
workflow.

Cross-API helper: - `iso3_to_m49(iso3)` — case-insensitive ISO3 → UN M49
lookup against `who_countries$m49_code`. Non-Member codes return `NA`.
Returned values are three-character zero-padded strings, the same form
the dataset stores.

Carried over (already in `NEWS.md` before this round): -
`geomean(x, na.rm = TRUE, w = NULL)` -
`iso3_to_region(iso3, long = FALSE)`

Bug fixes captured in 0.6.0: - `.gho_get()` no longer produces a
spurious 1×1 list-column tibble when GHO returns `value = []`. -
[`sdg_data()`](https://shanlong-who.github.io/DSIR/reference/sdg_data.md)
now sends multi-value `indicator` / `areaCode` filters as repeated keys
(not comma-joined) and no longer trips
`duplicate 'row.names' are not allowed` when paginating. -
[`sdg_data()`](https://shanlong-who.github.io/DSIR/reference/sdg_data.md)
year filtering (`year_from` / `year_to`) is now applied **client-side**.
The UN SDG API’s server-side `timePeriodStart` / `timePeriodEnd`
parameters cause HTTP 500 errors and ~30x slowdowns on at least some
indicator/area combinations (e.g. `3.2.1` with `area = "608"`). The
filter runs after the pagination loop assembles `out`; if
`timePeriodStart` is missing the function warns and returns unfiltered.
[`sdg_coverage()`](https://shanlong-who.github.io/DSIR/reference/sdg_coverage.md)
inherits the fix automatically. - `.sdg_get()` now has a 20-second
per-request timeout (`req_timeout(20)`) and exponential backoff
(`backoff = ~ min(2 ^ .x, 30)`), so a hung upstream request cannot stall
a call indefinitely.

### Implementation notes worth remembering

- **The M49 column is `who_countries$m49_code`, not `un_m49`.** Easy to
  misremember when reading historical task briefs. Values are
  zero-padded to three characters (e.g. `"076"` for Brazil). The SDG API
  accepts both `"076"` and `"76"` for the same area, so the bundled
  zero-padded form is fine to pass straight through.
- `.resolve_area()` (internal to `R/sdg.R`) detects format with
  `^[A-Za-z]{3}$` for ISO3 and `^[0-9]+$` for M49. These two regexes can
  never both match the same value, so format detection is unambiguous.
  Mixed input errors (refused, not coerced). Unknown ISO3 codes are
  dropped with a warning; if every code is unknown, the function errors.
- [`sdg_coverage()`](https://shanlong-who.github.io/DSIR/reference/sdg_coverage.md)
  calls `.resolve_area()` **before** the internal
  `suppressWarnings(sdg_data(...))` call, so the legitimate “dropped
  unknown ISO3” warning surfaces cleanly from
  [`sdg_coverage()`](https://shanlong-who.github.io/DSIR/reference/sdg_coverage.md)
  rather than being swallowed.
  [`sdg_data()`](https://shanlong-who.github.io/DSIR/reference/sdg_data.md)
  re-runs `.resolve_area()` on the already-resolved vector — that’s a
  no-op (M49 passes through), so the duplication is safe.
- [`sdg_coverage()`](https://shanlong-who.github.io/DSIR/reference/sdg_coverage.md)
  calls
  [`sdg_data()`](https://shanlong-who.github.io/DSIR/reference/sdg_data.md)
  internally — SDG offers no payload-reduction option equivalent to
  GHO’s `$select`, so there is no efficiency win from going around it.
  The grouping key is `paste(location, series, sep = "\x1f")` (US, unit
  separator — can’t collide with M49 codes or SDG series codes). Mirror
  the `yr_range` / `vapply` idiom from
  [`gho_coverage()`](https://shanlong-who.github.io/DSIR/reference/gho_coverage.md).
- For `sdg_indicators(search)`: the source-of-truth probe (see
  `scratch/probe_sdg.R`) confirmed the description column is named
  `description` (plain `chr`, not nested in `series`). The `series`
  column on
  [`sdg_data()`](https://shanlong-who.github.io/DSIR/reference/sdg_data.md)
  output is also plain `chr` — no `as.character(v[[1]])` flatten needed
  (that flatten in
  [`sdg_clean()`](https://shanlong-who.github.io/DSIR/reference/sdg_clean.md)
  is only for the `indicator` list-column).
- The 20-second timeout on `.sdg_get()` is fine for typical 2–6s SDG
  responses, but the un.org endpoint occasionally spikes well past 20s.
  If users start reporting spurious “Timeout was reached” failures,
  bumping the constant to 30–60s is the right move. `req_retry()` runs
  three attempts, so the worst-case wall time is bounded around 66s.

### Pending steps before tagging

``` r

devtools::document()   # may need TWO passes when a new function is added —
                       # the first pass writes the Rd, the second resolves
                       # cross-references that point at it
devtools::test()       # all tests should pass
devtools::check()      # R CMD check — expect 0 errors / 0 warnings / 0 notes
```

Then commit + tag. The 0.6.0 work is several independent themes (GHO
availability helpers; SDG series exploration + search; SDG year-filter
workaround; ISO3-friendly SDG functions +
[`iso3_to_m49()`](https://shanlong-who.github.io/DSIR/reference/iso3_to_m49.md))
and can be split into separate commits if a clean history is wanted.

``` bash
git tag v0.6.0
```

### Pandoc on this machine

`devtools::check()` rebuilds the vignette, which needs Pandoc. Pandoc is
not on `PATH` on this laptop but ships with RStudio. Point
`RSTUDIO_PANDOC` at the bundled binary before running `check()`:

``` r

Sys.setenv(RSTUDIO_PANDOC = "C:/Program Files/RStudio/resources/app/bin/quarto/bin/tools")
devtools::check()
```

## Roadmap — 0.7.0 candidates

### High priority — schema alignment for `gho_clean()` / `sdg_clean()`

Their outputs still cannot be `bind_rows()`-ed cleanly:

| Source | Columns |
|----|----|
| [`gho_clean()`](https://shanlong-who.github.io/DSIR/reference/gho_clean.md) | `id, location, year, dim1, dim2, dim3, value, value_num, low, high, indicator` |
| [`sdg_clean()`](https://shanlong-who.github.io/DSIR/reference/sdg_clean.md) | `goal, target, indicator, series, location, location_name, year, value, low, high` |

Open design question: pick a shared core schema
(e.g. `id, indicator, location, year, value, low, high`) and let
source-specific extras live alongside. Possibly add a
`bind_indicators(...)` helper. This is a breaking change, hence a
minor-version bump.

### Other candidates surfaced from scanning user’s analytical projects

- `get_latest(df)` — keep the last-non-missing year per location. Used
  in 3+ WHI/SDG projects in the user’s working directory.
- `ggdot(df, ...)` — Likert-style dot plot built on
  [`theme_dsi()`](https://shanlong-who.github.io/DSIR/reference/theme_dsi.md).
  Used in SCORE and WHI projects.

Deliberately deferred:

- `who_iso3(name)` — `countrycode::countrycode()` with a `custom_match`
  argument covers the same ground. Consider exporting only a named
  vector `who_short_name_overrides`
  (e.g. `c("DPR Korea" = "PRK", "DR Congo" = "COD", "Lao PDR" = "LAO", ...)`)
  if those overrides recur across many user scripts.
- `ggbar()` / `ggcol()` — too thin (`geom_col` + `fct_reorder`).
- ACM / excess-mortality helpers (`annotate_events_dt`,
  `create_period_indicator`, `loadEventsData`, `validate_*`) — wait for
  the ACM calculator 1.0 to stabilize the Excel template assumptions
  before extracting.

### Source folder for these candidates

The candidate list came from scanning
`C:\Users\User\OneDrive - World Health Organization\Documents\CAT\DSI`
(the user’s analytical working directory containing 2024–2026 WHO WPRO
projects). Conversation memory for that scan lives at
`C:\Users\User\.claude\projects\C--Users-User-OneDrive---World-Health-Organization-Documents-CAT-DSI\memory\`.

## Common commands

Run from the package root in an R session (or via `Rscript -e '...'`):

``` r

# Regenerate NAMESPACE and man/*.Rd from roxygen2 comments.
# ALWAYS run after editing any roxygen block or adding/removing an @export.
devtools::document()

# Rebuild the installed package for interactive testing.
devtools::load_all()       # fast, for iteration
devtools::install()        # full install

# Run the test suite (testthat edition 3).
devtools::test()
testthat::test_file("tests/testthat/test-ggpie.R")   # single file

# Full R CMD check — must pass cleanly before any CRAN-related change.
devtools::check()
```

Spell-checked words live in `inst/WORDLIST`; add new technical terms
there if `devtools::spell_check()` flags them.

## Architecture notes

### roxygen2 is the source of truth

`NAMESPACE` and everything under `man/` are generated. Never hand-edit
them. Exports come from `@export` tags in `R/*.R`; the two
`importFrom(rlang, ...)` lines are driven by the `@importFrom`
directives in `R/DSIR-package.R`. If a function disappears from
`NAMESPACE` or a help page goes stale, the fix is almost always “re-run
`devtools::document()`”.

### Network functions must fail soft

`gho_*()` and `sdg_*()` hit live APIs. Per CRAN policy, they must not
error when the remote is unreachable. The pattern (see `.gho_get` in
`R/gho.R` and `.sdg_get` in `R/sdg.R`):

1.  `httr2::request() |> req_timeout(20) |> req_retry(max_tries = 3, backoff = ~ min(2 ^ .x, 30)) |> req_perform()`,
    wrapped in `tryCatch`
2.  On failure,
    [`cli::cli_warn()`](https://cli.r-lib.org/reference/cli_abort.html)
    and return `NULL`
3.  Public wrappers turn `NULL` into an empty
    [`data.frame()`](https://rdrr.io/r/base/data.frame.html) (or `NULL`
    for list endpoints) so downstream code doesn’t crash

`.gho_get()` currently uses `req_retry(max_tries = 3)` without
`req_timeout` or an explicit backoff; `.sdg_get()` has both. If you
touch the GHO helper, consider aligning it with the SDG pattern. When
adding a new network call, follow this pattern — do not
[`stop()`](https://rdrr.io/r/base/stop.html) on HTTP failure.

### GHO uses OData; SDG uses query params

`.gho_get` understands OData paging (`@odata.nextLink`) and auto-follows
it until exhausted. `.sdg_get` is a single-request helper; `sdg_data`
layers manual page-number iteration on top of it using
`body$totalPages`. Keep that split — don’t try to unify them.

GHO filters are built as OData `$filter` strings and URL-encoded with
`utils::URLencode(..., reserved = TRUE)`. SDG filters are plain query
params joined with `&`.

### Example tags for network code

Examples that hit the network are wrapped in `\dontrun{}` in the current
source (`R/gho.R`, `R/sdg.R`). `NEWS.md` claims `\donttest{}` — if
you’re preparing a CRAN release, reconcile these: CRAN reviewers can opt
into `\donttest{}` but not `\dontrun{}`, so `\donttest{}` is the
intended state.

### Data files

`data/wpro_cty.rda` is the binary form of the `wpro_cty` character
vector; `R/data.R` only holds its roxygen doc block. `DESCRIPTION` sets
`LazyData: true`, so the dataset is available as
[`DSIR::wpro_cty`](https://shanlong-who.github.io/DSIR/reference/who_region_vectors.md)
without an explicit [`data()`](https://rdrr.io/r/utils/data.html) call.
To update the values, rebuild the `.rda`
(e.g. `usethis::use_data(wpro_cty, overwrite = TRUE)`) rather than
editing the binary.

### Fonts

[`theme_dsi()`](https://shanlong-who.github.io/DSIR/reference/theme_dsi.md)
and
[`dsi_flextable_defaults()`](https://shanlong-who.github.io/DSIR/reference/dsi_flextable_defaults.md)
default to `base_family = ""` / `font_family = ""` so they work on
CRAN’s Linux check machines where Cambria isn’t installed. Don’t
reintroduce a hard-coded font default — it will break `R CMD check` on
non-Windows.

### Tidy-eval in ggpie

`ggpie` uses `.data[[.x]]` / `.data[[.y]]` (from `rlang`) to reference
columns by string, which is why `R/DSIR-package.R` imports
[`rlang::.data`](https://rlang.r-lib.org/reference/dot-data.html). If
you add another ggplot helper that takes column-name strings, use the
same pattern so `R CMD check` doesn’t flag undefined globals.
