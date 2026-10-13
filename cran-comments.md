## Update rationale

This is an update from DSIR 0.10.0 to 0.11.0, prepared in response to
the CRAN Team request to correct the check failures by 2026-10-28.

The reported failure in `vignettes/DSIR.Rmd` occurs when live data are
empty and a dependent plot has no faceting values. In 0.11.0, live
API examples and the chunks that depend on them are displayed but not
executed during default vignette builds. The plotting vignette uses
simulated data. All three vignettes also rendered with HTTP requests
blocked; no API requests were attempted. This addresses the reported
failure without depending on temporary WHO or UN service availability.

GHO retains its legacy compatibility default and offers explicit
per-call `backend = "legacy"` or `"xmart"` selection. There is no automatic
provider fallback. The separate GHE client always uses xMart. The
default cleaned result retains 15 columns; named dimensions and
metadata remain optional. No new package dependencies or authentication
requirements were added.

The update also changes `who_std_pop` to the WHO 2026 Standard Population.
This is an intentional behavior change: there are now 18 age groups,
ending in `85+`, and `std_million` is numeric. Input age groups must be
aligned with the revised standard. See NEWS.md for the full changes.

Maintainer: Shanlong Ding <dings@who.int>

## Test environments and R CMD check

Validation date: 2026-10-12.

* Local Windows 11 x64, R 4.6.1 (2026-06-24 ucrt):
  0 errors, 0 warnings, 0 notes. This complete `R CMD check --as-cran`
  included the PDF manual and remote CRAN incoming checks.
* GitHub Actions, Windows x64, R-devel (2026-10-10 r90659 ucrt):
  0 errors, 0 warnings, 0 notes.
* GitHub Actions, Windows x64, R 4.5.3 (oldrelease):
  0 errors, 0 warnings, 0 notes.
* GitHub Actions, Ubuntu 24.04.5 x64, R-devel (2026-10-09 r90655):
  0 errors, 0 warnings, 0 notes.
* GitHub Actions, macOS 15.7.9 Apple Silicon (aarch64),
  R-devel (2026-10-10 r90659): 0 errors, 0 warnings, 0 notes.
* GitHub Actions, macOS 15.7.9 Apple Silicon (aarch64), R 4.6.1:
  0 errors, 0 warnings, 0 notes.

GitHub Actions checks use `--no-manual --as-cran`; live tests and live
vignette execution are disabled. The check-only branch has no package
source changes relative to the release candidate.

The official win-builder R-devel and R-oldrelease services accepted the
same source archive on 2026-10-12. Results are sent to the maintainer's
email and have not yet been verified here. The official macbuilder
submission endpoint returned HTTP 502 for both R-devel and R-release;
no successful macbuilder submission or result is claimed.

## Additional validation

`devtools::test()` recorded 1,130 passing assertions, 0 failures/errors,
0 warnings, and 30 skips. Live WHO/UN tests require explicit opt-in and
skip on CRAN. The existing offline mock tests ran. `urlchecker::url_check()`
reported that all checked URLs were correct.

## Reverse dependencies

The CRAN source package database was checked on 2026-10-12. There are
no reverse Depends, Imports, or LinkingTo packages. The two reverse
Suggests packages were checked from their current CRAN source archives
against both DSIR 0.10.0 and 0.11.0, using separate private libraries.
Each run used `R CMD check --no-manual --as-cran`, with CRAN incoming
checks disabled for the unchanged reverse dependencies.

| Package | With DSIR 0.10.0 | With DSIR 0.11.0 |
| --- | --- | --- |
| cataScience 2.1.4 | 0 errors, 0 warnings, 0 notes | 0 errors, 0 warnings, 0 notes |
| exmort 0.1.1 | 0 errors, 0 warnings, 0 notes | 0 errors, 0 warnings, 0 notes |

All four checks reached `* DONE` with exit status 0. No new reverse
dependency problems were found.

## Submission and publication status

This submission uses the checked `DSIR_0.11.0.tar.gz` archive described
below. The package author and maintainer is Shanlong Ding.

DSIR 0.11.0 was published on CRAN on 2026-10-12:
<https://CRAN.R-project.org/package=DSIR>.

Source commit: `5ee3a41feca301c9dd007e323235268aa7a4dc91`.
Archive size: 280,241 bytes.
SHA-256: `213ea4f7e63d610a336ef44fd873057642abaf6123064d9b1059c4076abc2e93`.
