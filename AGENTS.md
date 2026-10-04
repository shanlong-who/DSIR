# AGENTS.md

## Scope and sources of truth

DSIR is a small CRAN R package for global health data analysis.
Read `DESCRIPTION` for the current version and dependencies, `NEWS.md`
for released changes, and `README.md` and `vignettes/` for user workflows.
Do not keep session logs, local machine paths, or release checklists here.

Long-term design decisions and feature boundaries are recorded in
[design notes](.github/maintenance/design-notes.md). Do not propose new
exports or reopen declined features unless the user asks.

## Development rules

- Use R. Keep code, comments, file names, and documentation in English.
- Follow the surrounding package style. Package function names use underscores.
- Keep dependencies light; do not promote vignette-only packages to Imports
  without a clear package requirement.
- Diagnose before fixing. Show a diff or preview before overwriting code.
  Obtain confirmation before major refactors or deleting files unless the
  user's current request already authorizes that work.
- Do not change package behavior as part of repository housekeeping.
- Run existing tests and `R CMD check` after non-trivial changes.

## Architecture and regression safeguards

- Roxygen comments in `R/` are the source of truth for `NAMESPACE` and
  `man/*.Rd`. Regenerate them with `devtools::document()` after roxygen
  changes; do not hand-edit generated documentation.
- `R/clean_schema.R` defines the typed 15-column default cleaned schema.
  The optional dimension and metadata columns are additional fields;
  `bind_indicators()` must preserve them.
- Network requests use `.dsi_request()` in `R/http.R`. Request and JSON
  parsing failures warn and return the documented empty/NA result.
  Never interpolate external error text directly in a `cli_warn()`
  message template; use a variable such as `"x" = "{msg}"`.
- GHO follows `@odata.nextLink`; SDG validates pagination before applying
  local series and dimension filters. Keep these source-specific contracts.
- `who_countries$m49_code` stores zero-padded M49 codes. Rebuild bundled
  data through `data-raw/` scripts; do not hand-edit binary data files.
- Fonts must have portable defaults. Keep string-based ggplot column access
  compatible with tidy evaluation and CRAN checks.
- Use `inst/WORDLIST` for technical terms needed by spelling checks.

## Validation

From the package root:

```r
devtools::test()
devtools::check()
```

Tests that need live GHO or UN services use their existing `skip_on_cran()`
guards. The independent CI workflow uses `NOT_CRAN=false` and
`R CMD check --no-manual --as-cran`; report when live tests are skipped.
Keep `httptest2` installed so the existing offline mock tests run.
For httr2 mocks, supply a function or a list of responses. Mocked responses
bypass retry behavior; retry policy assertions are in the offline tests.

Vignette rebuilding needs Pandoc. Discover its installed location locally
instead of committing a machine-specific path. Update the pkgdown reference
index if a requested feature changes the public API.

## Public repository hygiene

Follow [repository hygiene](.github/maintenance/repository-hygiene.md).
Keep reusable tests in `tests/testthat/` and reusable data preparation in
`data-raw/`. Keep local probes and raw AI conversation exports untracked.
The distributable country-profile skills under `.claude/skills/` and
`.github/skills/` are intentional public assets.
