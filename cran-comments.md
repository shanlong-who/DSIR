## Submission notes

This is a feature release (0.8.0). It adds one new exported function,
`aarr()` (average annual rate of reduction, a standard WHO / UNICEF
progress metric), new optional `dim1` / `dim2` / `dim3` arguments for
server-side filtering in the GHO client functions, a lighter-weight
`gho_dimensions()` metadata query, a fix for a session-cache bug in
`gho_clean()`'s indicator-name resolution, and a new vignette on
visualizing cleaned indicator data. There are no breaking changes
since 0.7.1. See NEWS.md for details.

All API-facing functions keep the fail-soft behaviour required by
CRAN policy: network failures produce a warning and an empty result,
never an error. The new vignette uses simulated data only and builds
without network access.

Maintainer: Shanlong Ding <dings@who.int>

## Test environments

* local Windows 11, R 4.6.0
* win-builder (R-devel)
* GitHub Actions: ubuntu-latest (release), windows-latest (release),
  macos-latest (release), ubuntu-latest (devel)

## R CMD check results

0 errors | 0 warnings | 0 notes

## Reverse dependencies

None.
