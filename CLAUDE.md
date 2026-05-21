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

## Current development state — 0.7.0 ready to commit (last updated 2026-05-21)

Version bumped to 0.7.0 in `DESCRIPTION`. All planned code is written,
tested, exported, and described in `NEWS.md`. README and vignette are
updated to reflect the new schema.

**`devtools::check()` status (re-verified 2026-05-21).** All core
`R CMD check` checks, examples, `--run-donttest` (236s), and the
vignette rebuild are clean — 0 errors / 0 warnings / 0 notes. The **test
phase** can still report an ERROR, but only because of UN-endpoint
flakiness: `devtools::check()` sets `NOT_CRAN=true`, so the live network
tests in `test-sdg-year-filter.R` *run* locally instead of being skipped
by their `skip_on_cran()` guard, and they fail with “Timeout was
reached” whenever `unstats.un.org` is slow (the 20s `.sdg_get()` timeout
is exceeded). This is endpoint flakiness — **not a code defect, and not
CRAN-blocking**, since on real CRAN those tests skip. Offline mock
coverage is unaffected: **468 PASS / 0 FAIL** with the network tests
excluded. The `devtools::test()` baseline was 483 PASS; the three new
regression tests (below) take it to 486 when the UN endpoint is
reachable.

0.6.0 was already shipped to the GitHub `main` branch (commits
`1eeee49`, `15cb85a`, `4eb5a08`, `78e79e4`, `1debc4b`) but never reached
CRAN — CRAN is still on 0.2.0. Plan is to skip 0.6.x on CRAN and submit
0.7.0 directly.

### What was added across 0.7.0

**Breaking: unified 15-column cleaned-indicator schema.**
[`gho_clean()`](https://shanlong-who.github.io/DSIR/reference/gho_clean.md)
and
[`sdg_clean()`](https://shanlong-who.github.io/DSIR/reference/sdg_clean.md)
now both produce the same shape:

    source id indicator location iso3 location_name year value value_num low high series dim1 dim2 dim3

so GHO and SDG output can be `bind_rows()`-ed (or formally,
[`bind_indicators()`](https://shanlong-who.github.io/DSIR/reference/bind_indicators.md)-ed)
without column-shape work. `source` is `"gho"` or `"sdg"`. `value` stays
raw character (preserves SDG `"<0.1"` and similar); `value_num` is the
numeric coercion (NA where coercion fails). `year` is integer. `iso3`
for GHO is set when `SpatialDim %in% who_countries$iso3` else NA; for
SDG it comes from `m49_to_iso3(geoAreaCode)`.

For SDG specifically: `id` now holds the **indicator code**
(e.g. `"3.4.1"`, formerly named `indicator`) and `indicator` holds the
**`seriesDescription`** text from the API. The pre-0.7.0 SDG columns
`goal` and `target` are no longer carried forward. `series` is the SDG
series code (e.g. `"SH_DTH_NCD"`). `dim1` / `dim2` / `dim3` are always
NA for SDG (GHO-only).

For GHO specifically: `series` is always NA (SDG-only concept).
`location_name` is resolved from `location` against
`who_countries$name_short` plus a hardcoded WHO regional/GLOBAL map (see
the location_name fix below). `dim1` / `dim2` / `dim3` come from `Dim1`
/ `Dim2` / `Dim3`.

**New functions:** - `bind_indicators(...)` — variadic, rbinds any
number of cleaned tibbles into one. Validates that each input has the
full 15-column schema; drops NULL arguments; column re-ordering across
inputs is tolerated. - `m49_to_iso3(m49)` — counterpart to
[`iso3_to_m49()`](https://shanlong-who.github.io/DSIR/reference/iso3_to_m49.md).
Accepts zero-padded (`"076"`) or bare (`"76"`) input. Non-Member areas
and region/world aggregates return NA. Used internally by
[`sdg_clean()`](https://shanlong-who.github.io/DSIR/reference/sdg_clean.md)
to populate `iso3`.

**Bug fixes:** -
**[`sdg_coverage()`](https://shanlong-who.github.io/DSIR/reference/sdg_coverage.md)
duplicate definition.** The function was defined in **both** `R/sdg.R`
and `R/sdg_coverage.R` from 0.6.0; R loads files alphabetically so the
`sdg_coverage.R` version overrode the one in `sdg.R`. The two
implementations had subtly different behaviour. Resolved by deleting the
version in `sdg.R` and hardening the survivor (separator `\r` → `\x1f`,
added upfront `.resolve_area(area)` so the “dropped unknown ISO3”
warning surfaces from
[`sdg_coverage()`](https://shanlong-who.github.io/DSIR/reference/sdg_coverage.md)
rather than being swallowed by `suppressWarnings(sdg_data(...))`). -
**`.gho_get()` retry parity with `.sdg_get()`** — added
`req_timeout(20)` and `backoff = ~ min(2 ^ .x, 30)`. Same change applied
to the inline HTTP call in
[`gho_count()`](https://shanlong-who.github.io/DSIR/reference/gho_count.md)
(which doesn’t go through `.gho_get` because it needs `@odata.count`
rather than `value`). -
**[`sdg_data()`](https://shanlong-who.github.io/DSIR/reference/sdg_data.md)
multi-page `rbind` failure.** The 0.6.0 fix relied on
`make.row.names = TRUE` (the default) to disambiguate per-page tibble
row names like `"1"`..`"1000"`. That actually **does not** disambiguate
when each page has 1000 rows numbered identically; the rbind still trips
`duplicate 'row.names' are not allowed`. Surfaced when
`R CMD check --run-donttest` ran `sdg_data("1.1.1")` (26+ pages of ~1000
rows). Fixed by passing `make.row.names = FALSE` explicitly. The
existing test was too weak to catch this (each mock page had only 1
row); the new regression test uses 2-row pages so the collision actually
fires. -
**[`sdg_data()`](https://shanlong-who.github.io/DSIR/reference/sdg_data.md)
example simplified.** The first example was `sdg_data("1.1.1")`
(unfiltered, 26+ pages) — too slow for `R CMD check`. Now
`sdg_data("1.1.1", area = "PHL")`. -
**[`gho_clean()`](https://shanlong-who.github.io/DSIR/reference/gho_clean.md)
/
[`sdg_clean()`](https://shanlong-who.github.io/DSIR/reference/sdg_clean.md)
cross-API `location_name` consistency.** Before the fix,
[`gho_clean()`](https://shanlong-who.github.io/DSIR/reference/gho_clean.md)
left `location_name` always NA (GHO data endpoint returns no name
field), and
[`sdg_clean()`](https://shanlong-who.github.io/DSIR/reference/sdg_clean.md)
used the SDG API’s raw `geoAreaName`. The two sides could disagree on
the spelling for the same country, breaking
[`bind_indicators()`](https://shanlong-who.github.io/DSIR/reference/bind_indicators.md)
consumers that group by `location_name`. New helpers
`.gho_resolve_location_name()` and `.sdg_resolve_location_name()` (in
`R/gho.R` / `R/sdg.R`) route both cleaners through
`who_countries$name_short` for WHO Member States. GHO additionally
resolves the regional codes
`AFR / AMR / SEAR / EUR / EMR / WPR / GLOBAL` to human names via a
hardcoded map. SDG falls back to the raw `geoAreaName` for non-Member
rows (region/world aggregates), preserving information `who_countries`
does not carry. Schema, column order, and types unchanged — zero
breaking change. - **Network helpers now fail soft on malformed response
bodies, not just on HTTP errors.** `.gho_get()`, `.sdg_get()`, and the
inline HTTP call in
[`gho_count()`](https://shanlong-who.github.io/DSIR/reference/gho_count.md)
wrap
[`httr2::resp_body_json()`](https://httr2.r-lib.org/reference/resp_body_raw.html)
in [`tryCatch()`](https://rdrr.io/r/base/conditions.html). A truncated
upstream body (premature EOF) now surfaces a `cli_warn()` and returns
`NULL` / `NA_integer_` instead of propagating a `jsonlite` parse error —
which would otherwise abort an `R CMD check` example run
(CRAN-blocking). See `NEWS.md` for the user-facing entry. -
**[`cli::cli_warn()`](https://cli.r-lib.org/reference/cli_abort.html)
glue-injection bug in the warning handlers (fixed 2026-05-21).** All six
`tryCatch` error handlers in `R/gho.R` / `R/sdg.R` passed
`conditionMessage(e)` *directly* as a message element:
`cli::cli_warn(c(..., "x" = conditionMessage(e)))`. `cli` runs glue
interpolation on every message string, so an error message containing
literal `{` / `}` makes `cli` try to evaluate it as a glue expression
and re-error *while reporting the original error*. HTTP error messages
never carry braces, so this was latent — but a `jsonlite` parse error
message embeds the offending JSON fragment, which always has braces, so
the new body-parse handlers tripped it on the first malformed-body test.
Fixed by assigning `msg <- conditionMessage(e)` and interpolating the
variable: `"x" = "{msg}"` (glue inserts the variable’s value verbatim
and does not recurse into it). Applied to **all six** handlers — the
three new body-parse ones and the three pre-existing HTTP-failure ones —
so the pattern is uniform.

**Documentation:** - All network examples switched from `\dontrun{}` to
`\donttest{}`. CRAN reviewers can opt to run them;
`R CMD check --run-donttest` exercises them locally. - `DESCRIPTION`
`Authors@R` now carries the user’s ORCID (`0000-0002-8831-1684`). -
`cran-comments.md` rewritten as a 0.7.0 resubmission note (explains the
0.2.0 → 0.7.0 jump, points at NEWS for the unified-schema breaking
change, confirms `--run-donttest` is also clean). The pre-0.7.0 file was
still the initial-submission template.

**Internal:** - New `R/clean_schema.R` centralises the 15-column schema
(`.dsi_clean_schema()`), the typed-empty-tibble template
(`.dsi_empty_clean()`), and the typed-NA filler (`.fill_na(n, type)`).
Any change to the schema should start here. - `httptest2` added to
`Suggests`. The mocking tests use
[`httr2::with_mocked_responses()`](https://httr2.r-lib.org/reference/with_mocked_responses.html)
directly (httptest2 is a peer of httr2 for offline testing); see
implementation notes below for the gotcha. - `test-gho-dimensions.R`
added —
[`gho_dimensions()`](https://shanlong-who.github.io/DSIR/reference/gho_dimensions.md)
was the last exported network function without offline coverage. Uses
the same `mock_json()` pattern as `test-gho-get-mock.R` /
`test-sdg-get-mock.R`. - **Three regression tests for the malformed-body
fail-soft path (added 2026-05-21).** `test-gho-get-mock.R` gained two
(`.gho_get()` on a truncated JSON body → warning + `NULL`;
[`gho_count()`](https://shanlong-who.github.io/DSIR/reference/gho_count.md)
on a truncated body → `NA_integer_`) and `test-sdg-get-mock.R` gained
one (`.sdg_get()` on a truncated body → warning + `NULL`).
[`gho_count()`](https://shanlong-who.github.io/DSIR/reference/gho_count.md)
previously had **no** offline coverage at all. Writing the `.sdg_get`
one is what surfaced the `cli_warn()` glue-injection bug listed under
Bug fixes — the malformed-body fix had shipped to `NEWS.md` without a
test, so the bug in the fix went unnoticed until the test was written.

### Implementation notes worth remembering

- **The unified schema’s source of truth is `R/clean_schema.R`.**
  `.dsi_clean_schema()` returns the canonical column order and the type
  code (`"chr"`, `"int"`, `"num"`). `.dsi_empty_clean()` produces the
  typed 0-row tibble used by both cleaners for empty input and by
  [`bind_indicators()`](https://shanlong-who.github.io/DSIR/reference/bind_indicators.md)
  for the no-input / all-NULL case. Adding a new column means updating
  this file and then both
  [`gho_clean()`](https://shanlong-who.github.io/DSIR/reference/gho_clean.md)
  /
  [`sdg_clean()`](https://shanlong-who.github.io/DSIR/reference/sdg_clean.md)
  to populate it.
- **[`gho_clean()`](https://shanlong-who.github.io/DSIR/reference/gho_clean.md)’s
  old `n = 0` bug:** the pre-0.7.0 cleaners used `rep(NA, n)`, which for
  `n = 0` produces `logical(0)`. The empty-output column types were
  therefore all `logical`, not matching the documented types. 0.7.0
  fixes this by routing empty input through `.dsi_empty_clean()`
  directly.
- **The M49 column is `who_countries$m49_code`, not `un_m49`.** Values
  are 3-char zero-padded (e.g. `"076"` for Brazil). The SDG API accepts
  both `"076"` and `"76"`;
  [`m49_to_iso3()`](https://shanlong-who.github.io/DSIR/reference/m49_to_iso3.md)
  normalises both before lookup via
  `formatC(as.integer(m49), width = 3, flag = "0")` — note the
  `padded[padded == "NA"] <- NA_character_` step that handles
  `formatC(NA_integer_)` returning the literal string `"NA"`.
- **GHO `iso3` heuristic.**
  [`gho_clean()`](https://shanlong-who.github.io/DSIR/reference/gho_clean.md)
  sets `iso3 = location` when `location %in% who_countries$iso3`, else
  `NA`. This is a pure-lookup check, not a regex — so weird-but-valid
  3-letter codes like `"COG"` work, but region codes (`"EUR"`,
  `"GLOBAL"`) correctly get NA.
- **`location_name` resolution.** Both cleaners delegate to a small
  helper next to the public function:
  `.gho_resolve_location_name(location)` in `R/gho.R` and
  `.sdg_resolve_location_name(iso3, raw_geo_area_name)` in `R/sdg.R`.
  GHO order of resolution: ISO3 → `who_countries$name_short`, else WHO
  regional code → hardcoded `region_names` map
  (`AFR/AMR/SEAR/EUR/EMR/WPR/GLOBAL`), else NA. SDG order: ISO3 →
  `who_countries$name_short`, else SDG API raw `geoAreaName`, else NA.
  The hardcoded regional map is intentionally **GHO-only** — SDG
  `geoAreaName` already carries readable names for M49 region/world
  aggregates (`"World"`, `"Sub-Saharan Africa"`, etc.), so duplicating
  that map on the SDG side would be redundant and fragile. The “fallback
  to `geoAreaName`” rule means SDG output retains a `location_name` for
  rows where ISO3 is NA (region/world aggregates), while GHO output is
  `NA` for unknown/non-Member spatial codes. That asymmetry is by
  design: GHO has no equivalent of `geoAreaName` to fall back on.
- **SDG `indicator` column source.** Comes from `seriesDescription` in
  the raw
  [`sdg_data()`](https://shanlong-who.github.io/DSIR/reference/sdg_data.md)
  response, not from the indicator-list endpoint. For some series,
  `seriesDescription` is absent; in that case `indicator` is NA. If you
  want a human label for those, join the result against
  [`sdg_indicators()`](https://shanlong-who.github.io/DSIR/reference/sdg_indicators.md)
  on `id`.
- **`.resolve_area()` (in `R/sdg.R`)** detects format with
  `^[A-Za-z]{3}$` for ISO3 and `^[0-9]+$` for M49. Mixed input errors.
  Unknown ISO3 codes are dropped with a warning; if every code is
  unknown, the function errors.
- **[`sdg_coverage()`](https://shanlong-who.github.io/DSIR/reference/sdg_coverage.md)
  calls `.resolve_area()` upfront** so the legitimate “dropped unknown
  ISO3” warning surfaces from
  [`sdg_coverage()`](https://shanlong-who.github.io/DSIR/reference/sdg_coverage.md)
  rather than being swallowed by the `suppressWarnings(sdg_data(...))`
  wrapper.
  [`sdg_data()`](https://shanlong-who.github.io/DSIR/reference/sdg_data.md)
  re-runs `.resolve_area()` on the already-resolved vector — that’s a
  no-op (M49 passes through), so the duplication is safe. The grouping
  key is `paste(location, series, sep = "\x1f")`; `\x1f` (US, unit
  separator) cannot appear in either an M49 numeric code or an SDG
  series code.
- **httr2 1.x mocking gotcha.**
  `httr2::with_mocked_responses(mock, code)` requires `mock` to be a
  **function, list, or NULL** — passing a bare
  [`httr2::response()`](https://httr2.r-lib.org/reference/response.html)
  object errors with `mock must be function, list, or NULL`. The
  `mock_json()` helper in the test files wraps its single response in
  `list(...)`; when chaining two pages, the tests use
  `c(mock_json(p1), mock_json(p2))` to concatenate the two length-1
  lists into a length-2 list. URL-capturing tests pass a `function(req)`
  mock so they can inspect the outgoing URL before returning the canned
  response.
- **[`gho_count()`](https://shanlong-who.github.io/DSIR/reference/gho_count.md)
  uses its own HTTP call site,** not `.gho_get()`, because it needs
  `@odata.count` from the response envelope, not `value`. If you touch
  retry/timeout config for one, mirror the change in the other
  (currently they are in sync).
- **The 20-second timeout on `.sdg_get()` / `.gho_get()`** is fine for
  typical 2–6s responses, but the un.org endpoint occasionally spikes
  well past 20s. If users start reporting spurious “Timeout was reached”
  failures, bumping the constant to 30–60s is the right move.
  `req_retry()` runs three attempts, so the worst-case wall time is
  bounded around 66s × 1 retry cycle ≈ several minutes.
- **`devtools::document()` may need two passes** when a new function
  adds a roxygen cross-reference (`@seealso [new_fn()]`). First pass
  writes the new Rd; second pass resolves the cross-reference.
- **[`cli::cli_warn()`](https://cli.r-lib.org/reference/cli_abort.html)
  and untrusted error text.** Never pass `conditionMessage(e)` — or any
  string that may contain `{` / `}` — as a bare element of the
  `cli_warn()` message vector; `cli` glue-interpolates every element.
  Assign it to a variable first and interpolate the variable:
  `msg <- conditionMessage(e); cli::cli_warn(c(..., "x" = "{msg}"))`.
  glue inserts the variable’s value literally and does not
  re-interpolate it. All six `tryCatch` warning handlers in `R/gho.R` /
  `R/sdg.R` follow this pattern — keep any new handler consistent.

### Pending steps before tagging

``` r

devtools::test()       # baseline — needs unstats.un.org reachable for the SDG network tests
devtools::check()      # 0E/0W/0N on all non-test phases; test phase ERRORs only on UN-endpoint timeout (see status above)
```

Then commit + tag. The 0.7.0 work is several independent themes (schema
alignment + `bind_indicators`; `m49_to_iso3`; `sdg_coverage` dedup;
retry parity; documentation polish; test coverage; httptest2 mocking)
and can be split into separate commits if a clean history is wanted.

``` bash
git tag v0.7.0
```

### Toolchain on this machine (verified 2026-05-21)

- **R** is installed under `D:/R/` — current version `D:/R/R-4.5.3/` —
  *not* under `C:/Program Files/R`. Older sessions assumed
  `C:/Program Files/R/R-4.4.2`; that path does not exist. Use
  `D:/R/R-4.5.3/bin/Rscript.exe`.

- **No RStudio, Quarto, or system Pandoc is installed.** The earlier
  note pointing `RSTUDIO_PANDOC` at `C:/Program Files/RStudio/...` was
  stale and does not work.

- **`devtools::check()` rebuilds the vignette, which needs Pandoc.** A
  standalone Pandoc was installed via the `pandoc` R package:

  ``` r

  install.packages("pandoc")
  pandoc::pandoc_install()                          # installs Pandoc 3.9.0.2
  pandoc::pandoc_activate("3.9.0.2", rmarkdown = TRUE)
  ```

  The binary lives at
  `C:/Users/User/AppData/Local/r-pandoc/r-pandoc/3.9.0.2/pandoc.exe`.
  Point `RSTUDIO_PANDOC` at its **directory** before `check()`:

  ``` r

  Sys.setenv(RSTUDIO_PANDOC = "C:/Users/User/AppData/Local/r-pandoc/r-pandoc/3.9.0.2")
  devtools::check()
  ```

- **`httptest2` (a `Suggests` dependency) had to be installed** in the
  `R-4.5.3` library. Without it the three mock test files
  (`test-gho-get-mock.R`, `test-sdg-get-mock.R`,
  `test-gho-dimensions.R`) `skip` instead of running, so the offline
  regression coverage silently disappears.

## Roadmap — post-0.7.0

The package is approaching steady state. The user explicitly intends to
enter a stable phase after 0.7.0 ships. **Do not propose new exports
unprompted.** New features should only be added when the user asks; this
section records what was considered and what was declined, so future
sessions don’t reopen settled questions.

### Done in 0.7.0

- Schema alignment for
  [`gho_clean()`](https://shanlong-who.github.io/DSIR/reference/gho_clean.md)
  /
  [`sdg_clean()`](https://shanlong-who.github.io/DSIR/reference/sdg_clean.md)
  → unified 15-column shape. **Settled — do not reopen.**
- `bind_indicators(...)` — implemented as part of the schema work.
- [`m49_to_iso3()`](https://shanlong-who.github.io/DSIR/reference/m49_to_iso3.md)
  — added as the counterpart to
  [`iso3_to_m49()`](https://shanlong-who.github.io/DSIR/reference/iso3_to_m49.md),
  used by
  [`sdg_clean()`](https://shanlong-who.github.io/DSIR/reference/sdg_clean.md)
  to populate `iso3`.

### Declined by the user (2026-05-13)

The user reviewed the 0.7.0-candidates list and decided not to add
these. **Do not propose them again** unless the user asks:

- `get_latest(df)` — too narrow; users can write
  `slice_max(year, by = location, na_rm = TRUE)` themselves when they
  need it.
- `ggdot(df, ...)` — too narrow; chart-builder helpers belong in project
  code, not the package.

### Deferred (still on the long list)

- `who_iso3(name)` — `countrycode::countrycode()` with `custom_match`
  covers the same ground. If WHO-specific short-name overrides
  (`"DPR Korea" = "PRK"`, `"DR Congo" = "COD"`, `"Lao PDR" = "LAO"`,
  etc.) come up repeatedly across user scripts, consider exporting
  **only** a named vector `who_short_name_overrides` so users can plug
  it into `countrycode()`.
- `ggbar()` / `ggcol()` — too thin (`geom_col` + `fct_reorder`);
  explicit ggplot reads better.
- ACM / excess-mortality helpers (`annotate_events_dt`,
  `create_period_indicator`, `loadEventsData`, `validate_*`) — wait for
  the ACM calculator 1.0 to stabilise the Excel template assumptions
  before extracting.

### Source folder for these candidates

The candidate list came from scanning
`C:\Users\User\OneDrive - World Health Organization\Documents\CAT\DSI`
(the user’s analytical working directory containing 2024–2026 WHO WPRO
projects). Conversation memory for that scan lives at
`C:\Users\User\.claude\projects\C--Users-User-OneDrive---World-Health-Organization-Documents-CAT-DSI\memory\`.

## Pre-stable polish — remaining items

The user did the three highest-impact pre-stable items on 2026-05-13:
`cran-comments.md` rewritten,
[`gho_dimensions()`](https://shanlong-who.github.io/DSIR/reference/gho_dimensions.md)
test coverage added, ORCID added to `Authors@R`. The package is now in
fully shippable shape for 0.7.0.

Status of the cosmetic items:

1.  ~~**README’s “Note about CRAN version” banner**~~ — **done.** The
    “⚠️ Note about CRAN version” block (which described the 0.2.0
    [`gho_data()`](https://shanlong-who.github.io/DSIR/reference/gho_data.md)
    HTTP 400 bug) has been removed from `README.md`.
2.  **`README.md` lifecycle badge says “stable”** while the package is
    0.x — still open. Either bump to 1.0.0 (the API is now what it would
    be at 1.0) or change the badge to `maturing`.

Skippable nice-to-have:

- **`inst/CITATION`** — so `citation("DSIR")` returns a user-preferred
  citation rather than the auto-generated default. Add only if the user
  starts asking how others should cite the package.

### Path to 1.0.0

The user has signalled they want to enter a stable state. The
recommended sequence:

- Commit + tag `v0.7.0`. Submit 0.7.0 to CRAN.
- Let it sit on CRAN for ~1 month while running real WHO projects
  against it.
- If no API regret surfaces, bump `Version: 1.0.0`, write a one-line
  NEWS entry, and submit again.
- The 0.7.0 schema and
  [`bind_indicators()`](https://shanlong-who.github.io/DSIR/reference/bind_indicators.md)
  design are intentionally future-proof, so 1.0.0 should be a
  no-code-change version bump.

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
