## DSIR 0.15.0

This updates DSIR 0.13.0 on CRAN. Version 0.14.0 was a GitHub release.
GHO and SDG downloads now return cleaned indicator tables by default.
Existing scripts can request provider columns with clean = FALSE.
The update also adds dimension summaries and automatic plot selection.

## Local checks

Windows 11 x64, R 4.6.2, R CMD check --no-manual --as-cran:
0 errors, 0 warnings, 0 notes. The check included remote incoming
checks using a CRAN mirror, examples with --run-donttest and vignette rebuilding.

The checkout test suite passed 2,615 assertions. The 32 opt-in network tests
were skipped. Separate live WHO xMart and UN SDG downloads for the Philippines
returned cleaned observations. A UN SDG goal-directory example timed out and
returned its documented warning and NULL result.
