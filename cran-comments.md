## Release candidate notes

This is the local preparation draft for DSIR 0.11.0. No submission has
been made for this version.

This feature release migrates the default GHO provider to the public WHO
xMart OData API, adds a separate Global Health Estimates client, and
replaces `who_std_pop` with the official WHO 2026 Standard Population.
The standard population now has 18 age groups. Analyses using the earlier
age groups must align their input vectors with the revised standard.
The default cleaned output remains the same 15-column schema, with
optional named dimensions and metadata. See NEWS.md for details.

No dependencies or authentication requirements were added. Network
failures produce informative warnings and empty results. Incomplete
downloads are discarded. The legacy GHO adapter is available only by
explicit selection; there is no automatic provider fallback. Package
loading makes no network requests or cache-directory writes.

Maintainer: Shanlong Ding <dings@who.int>

## Test environments

* Local Windows 11 x64 (build 22631), R 4.6.1 (2026-06-24 ucrt), UTF-8.
* Documentation built with roxygen2 8.1.0 and Pandoc 3.10.
* Validation date: 2026-10-06.

## R CMD check results

* `devtools::check(cran = FALSE)`: 0 errors, 0 warnings, 0 notes.
* `devtools::check(cran = FALSE, args = "--as-cran", remote = TRUE,
  incoming = TRUE)`: 0 errors, 0 warnings, 1 note.

The sole note is from CRAN incoming feasibility:

    Days since last update: 5

This flags the short interval since the previous CRAN update. Incoming
checks were enabled and the note was not suppressed. Release timing
should be reviewed before a future submission.

Examples, package tests and vignette rebuilds passed. The `--as-cran`
run also passed the network examples under `--run-donttest`. Both runs
used devtools' default `--no-manual`; PDF-manual compilation was not
checked.

The final `devtools::test()` run recorded 953 passing assertions,
0 failures/errors/warnings, and 29 skips. Live tests require explicit
opt-in and skip on CRAN. Separate read-only production queries verified
GHO mappings and filters, GHE examples, paging and coverage, and
legacy/xMart comparisons.

Linux/macOS and R-devel/win-builder checks remain to be run before any
submission that requires those results. They are not claimed here.

## Reverse dependencies

Confirm the current reverse-dependency status before submission and
record any checks required. No new reverse-dependency check is claimed
in this draft.
