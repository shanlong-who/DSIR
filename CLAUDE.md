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
