# Live API health checks

The independent **API health** workflow runs four small queries against the
current checkout on Ubuntu with R release. It is scheduled for Monday at
01:17 UTC (09:17 Manila) and supports **Actions > API health > Run workflow**.
Scheduled runs use the default branch; manual runs use the selected branch.
The existing CRAN check workflow, package exports and dependencies are unchanged.

| Check | Fixed selection |
| --- | --- |
| GHO legacy | `MDG_0000000026`, Philippines, 2020; this indicator has no sex breakdown |
| GHO xMart | `NCDMORT3070`, Philippines, 2020, `DIM_SEX = TOTAL` |
| GHE | Philippines, 2023, all causes, all ages, both sexes, deaths |
| UN SDG | `3.2.1`, Philippines, 2020, `SH_DYN_MORT`, `Sex = BOTHSEX` |

Each case downloads and cleans observations through DSIR's public functions.
Checks require nonempty data, the typed 15-column core, the requested selections,
usable numeric values and WHO completeness/provider metadata where available.
Optional dimension and metadata fields are checked where they identify the
selection. Exact estimate values and row counts are not pinned, and the two
GHO backends are not compared for numerical agreement.

The SDG client downloads the selected indicator/country before applying its
year, series and dimension filters locally. These are four query scenarios,
not necessarily four HTTP requests: WHO reference and label lookups also make
requests. No observation snapshots are used or saved by the workflow.

## Results and failures

All four cases must execute and pass. An empty result, error or warning fails
its case; later cases still run. No offline skip is treated as healthy. Results
are written before work starts and after each case, so an interrupted report
shows `RUNNING` or `NOT_RUN` rather than a false pass.

The run summary shows backend, status, row counts and elapsed time. The diagnostic
artifact contains CSV/Markdown summaries, per-case logs and session information;
it is retained for 14 days. Reports include UTC time, DSIR/R versions and the
checkout commit. They are not committed to the repository.

The existing HTTP timeout/retry policy is reused. The live-check step has a
10-minute limit and the job has a 15-minute limit including setup and reporting.
There is no additional automatic full-run retry and no fixed latency assertion.

When a run fails, inspect the affected case and its diagnostic log. A transport
failure or temporary service error is not proof of a DSIR bug. A changed schema,
selection, empty result or missing metadata needs investigation. A manual rerun
can distinguish a transient problem from a persistent failure. This workflow
does not create issues or configure account notifications; maintainers can enable
GitHub Actions failure notifications in their own notification settings.

## Local use

Install the checkout with `R CMD INSTALL .`, then run from the repository root:

```r
Sys.setenv(DSIR_RUN_LIVE_TESTS = "true",
           DSIR_HEALTH_OUTPUT = file.path(tempdir(), "dsir-api-health"))
system2(file.path(R.home("bin"), "Rscript"),
        c("--vanilla", ".github/scripts/api-health.R"))
```

The standalone script requires explicit live-test opt-in. Loading it with
`source()` defines the functions without starting network checks, which allows
the reporting and failure behavior to be tested offline. In local runs outside
Actions, the commit field is `unknown` unless `GITHUB_SHA` is supplied.

GitHub schedules can be delayed, and scheduled workflows in public repositories
are disabled after 60 days without repository activity. Check the last successful
run occasionally; this weekly check is not a real-time availability guarantee.
See [GitHub's schedule documentation](https://docs.github.com/en/actions/reference/workflows-and-actions/events-that-trigger-workflows#schedule).
