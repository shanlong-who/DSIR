## Update rationale

This updates CRAN's DSIR 0.11.0 to 0.13.0. Version 0.12.0 was not
submitted to CRAN.

The earlier update is requested because the legacy WHO GHO service now
returns HTTP 500 for indicator searches and some observation requests,
including UHC_INDEX_REPORTED. This disrupts the existing default workflow.

GHO now defaults to automatic selection, preferring WHO's public xMart
service. It attempts legacy only when a successfully read directory omits
the exact indicator code or a whole-indicator query verifies zero rows.
HTTP, parsing and schema failures, empty filtered results and partial
coverage do not trigger fallback. A fallback warns and records its source;
providers are never combined and provider-specific filters are not dropped.
Explicit legacy or xMart selection remains available. The default cleaned
15-column schema is unchanged. Legacy catalog lookup can use a dated
bundled snapshot after an online failure; this does not cache observations.

The update also adds experimental source timestamp queries and offline GHO
snapshot comparison. The flextable dependency moves from Imports to
Suggests and is checked only when its helper is called. There are no new
required dependencies, license changes or maintainer changes. NEWS.md
describes the intentional backend default change and the other additions.

Maintainer: Shanlong Ding <dings@who.int>

## Test environments and R CMD check

Validation date: 2026-10-30.

* GitHub Actions, Ubuntu 26.04.1 x64, R 4.6.2 (2026-10-29):
  0 errors, 0 warnings, 0 notes with `--no-manual --as-cran`, including
  `--run-donttest` examples. This run built and checked the exact source
  archive selected for submission.
  <https://github.com/shanlong-who/DSIR/actions/runs/41030107358>
* GitHub Actions, Ubuntu 26.04.1 x64, R-devel (2026-10-29 r90794):
  0 errors, 0 warnings, 0 notes with `--no-manual --as-cran`, including
  `--run-donttest` examples. The check branch adds only a workflow file;
  its package source is unchanged from the release candidate.
  <https://github.com/shanlong-who/DSIR/actions/runs/41041352267>
* Local Windows 11 x64, R 4.6.1 (2026-06-24 ucrt):
  0 errors, 0 warnings, 0 notes with `--as-cran`, including `--run-donttest`
  examples and the PDF and HTML manuals. Remote CRAN incoming lookups were
  disabled after the main CRAN index and archive metadata downloads timed
  out. This check used a local build of the same package source. The PDF
  manual was also compiled successfully from the exact submission archive.

The existing opt-in live API tests are skipped on CRAN; the offline mock
tests run. Vignettes retain their existing guards against live API calls
during ordinary builds. The current CRAN check page for DSIR 0.11.0 was
reviewed on 2026-10-30 and reports OK on every listed platform.

## Additional validation

The complete local test suite recorded 1,945 passing assertions,
0 failures/errors, 0 warnings and 32 skips. A separate live UHC query for
the Philippines in 2020-2023 returned four xMart observations, matching
the count query. English, Chinese and French website builds and all 15
translated-page validations passed.

## Reverse dependencies

The current CRAN package page lists no reverse Depends, Imports or
LinkingTo packages, and two reverse Suggests packages. Both were checked
from current CRAN source archives against DSIR 0.13.0 in a separate
library, using `--no-manual --as-cran` with CRAN incoming checks disabled.

| Package | With DSIR 0.13.0 |
| --- | --- |
| cataScience 2.1.4 | 0 errors, 0 warnings, 0 notes |
| exmort 0.1.1 | 0 errors, 0 warnings, 0 notes |

Both checks reached `* DONE` with `Status: OK`.

## Source archive

The submission archive is `DSIR_0.13.0.tar.gz`, built by R 4.6.2 in the
successful GitHub Actions run above. Its package code, tests, help files
and bundled data match the reviewed repository source.

Source commit: `4e55242197e8cf355fa3cd39a048000ef35ee228`.
Archive size: 1,754,252 bytes.
SHA-256: `b84ac9d8a7798ab36165cbb71a10420f009f82524aebfc79046ceebabc20b1f1`.
