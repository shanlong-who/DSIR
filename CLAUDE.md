# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working
with code in this repository.

## What this repo is

`DSIR` is a small R package (“Data Science Infrastructure for Global
Health in R”), targeted at CRAN. It provides:

- A `ggplot2` theme (`theme_dsi`) and `flextable` defaults helper
  (`dsi_flextable_defaults`)
- A pie-chart wrapper (`ggpie`)
- A bundled dataset (`wpro_cty`, ISO3 codes for WHO Western Pacific
  Region)
- Thin API clients for the WHO Global Health Observatory (`gho_*`) and
  UN SDG (`sdg_*`) APIs

The package is CRAN-bound, so conventions below are driven by
`R CMD check` and CRAN policy, not just taste.

## Current development state — 0.5.1 in preparation (last updated 2026-05-08)

Two new functions are written, tested, exported, and documented in
`NEWS.md`. **Code is committed-ready but the release scripts have not
yet been run.** Resume from this point.

### What was added in 0.5.1

- `geomean(x, na.rm = TRUE)` — geometric mean. For ratio-based indicator
  aggregation (e.g. UHC service-coverage tracers). Returns 0 if any
  element is 0; warns + returns `NaN` for negative input.
- `iso3_to_region(iso3, long = FALSE)` — ISO3 → WHO region using the
  bundled `who_countries` dataset. `long = TRUE` gives full names.
  Non-Member codes return `NA`.

### Files touched in this release

- `R/geomean.R`, `R/iso3_to_region.R` (new)
- `tests/testthat/test-geomean.R`,
  `tests/testthat/test-iso3_to_region.R` (new)
- `R/DSIR-package.R` — added `utils::globalVariables("who_countries")`
  to silence R CMD check NOTE; listed new functions in `@details`
- `NAMESPACE` — manually added `export(geomean)` and
  `export(iso3_to_region)` (will be regenerated identically by
  `devtools::document()`)
- `DESCRIPTION` — Version bumped to 0.5.1; Description field updated
- `NEWS.md` — added 0.5.1 section

### Pending steps before tagging

``` r

devtools::document()   # regenerate NAMESPACE + man/*.Rd from roxygen
devtools::test()       # all tests should pass
devtools::check()      # R CMD check — expect 0 errors / 0 warnings / 0 notes
```

Then commit + tag:

``` bash
git add R/ tests/ NAMESPACE DESCRIPTION NEWS.md CLAUDE.md
git commit -m "Release 0.5.1: add geomean() and iso3_to_region()"
git tag v0.5.1
```

### Known doc staleness (not blocking 0.5.1)

The “What this repo is” section above still describes only `wpro_cty` as
the bundled dataset. Since 0.4.0 the package also ships `who_countries`,
the full `afro_cty/.../wpro_cty` regional vectors, and `pic_cty`. Worth
refreshing during a future doc cleanup.

## Roadmap — 0.6.0 candidates

### High priority — schema alignment for `gho_clean()` / `sdg_clean()`

Their outputs cannot currently be `bind_rows()`-ed cleanly:

| Source | Columns |
|----|----|
| [`gho_clean()`](https://shanlong-who.github.io/DSIR/reference/gho_clean.md) | `id, location, year, dim1, dim2, dim3, value, value_num, low, high, indicator` |
| [`sdg_clean()`](https://shanlong-who.github.io/DSIR/reference/sdg_clean.md) | `goal, target, indicator, series, location, location_name, year, value, low, high` |

Open design question: pick a shared core schema
(e.g. `id, indicator, location, year, value, low, high`) and let
source-specific extras live alongside. Possibly add a
`bind_indicators(...)` helper. This is a breaking change, hence 0.6.0.

### Other candidates surfaced from scanning user’s analytical projects

Worth packaging once 0.5.1 ships:

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
`R/gho.R:153` and `.sdg_get` in `R/sdg.R:171`):

1.  `httr2::request() |> req_retry(max_tries = 3) |> req_perform()`
    wrapped in `tryCatch`
2.  On failure,
    [`cli::cli_warn()`](https://cli.r-lib.org/reference/cli_abort.html)
    and return `NULL`
3.  Public wrappers turn `NULL` into an empty
    [`data.frame()`](https://rdrr.io/r/base/data.frame.html) (or `NULL`
    for list endpoints) so downstream code doesn’t crash

When adding a new network call, follow this pattern — do not
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
