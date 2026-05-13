## Submission notes

This is a resubmission updating `DSIR` from 0.2.0 (the previous CRAN
release) to 0.7.0. The intermediate development versions 0.3.0, 0.4.0,
0.5.0 and 0.6.0 were not submitted to CRAN; this is the first
resubmission since the initial release.

Maintainer: Shanlong Ding <dings@who.int>

### What has changed since 0.2.0

The full release notes are in `NEWS.md`. The most user-facing items:

* **New unified output schema for the GHO and SDG cleaning helpers.**
  `gho_clean()` and `sdg_clean()` now both produce the same 15-column
  tibble (`source`, `id`, `indicator`, `location`, `iso3`,
  `location_name`, `year`, `value`, `value_num`, `low`, `high`,
  `series`, `dim1`–`dim3`), so output from the two APIs can be
  combined directly with the new `bind_indicators()` helper. This is
  the only breaking change since 0.2.0; migration notes are in
  `NEWS.md`.

* New functions: `bind_indicators()`, `m49_to_iso3()`, `geomean()`,
  `iso3_to_region()`, `iso3_to_m49()`, `gho_has_data()`,
  `gho_count()`, `gho_coverage()`, `sdg_coverage()`,
  `scale_x_dsi_col()` / `scale_y_dsi_col()`, `theme_dsi_facet()`.

* New bundled datasets: `who_countries` and the regional ISO3 vectors
  `afro_cty`, `amro_cty`, `searo_cty`, `euro_cty`, `emro_cty`,
  `pic_cty` (joining the existing `wpro_cty`).

* `gho_data()` no longer fails with HTTP 400 on long `area` vectors
  (switched from chained `or` clauses to the OData `in` operator).

* `sdg_data()` now sends multi-value `indicator` / `areaCode` as
  repeated keys instead of comma-joined, applies `year_from` /
  `year_to` client-side (working around a UN SDG API HTTP 500 bug),
  and concatenates multi-page responses without the previous
  `duplicate 'row.names' are not allowed` error.

* `.gho_get()` and `.sdg_get()` now share a 20-second per-request
  timeout and exponential backoff, so a hung upstream request cannot
  stall a call indefinitely.

* All network examples now use `\donttest{}` so CRAN reviewers can
  opt to run them.

## Test environments

* local Windows 11, R 4.6.0
* GitHub Actions: ubuntu-latest (release), windows-latest (release),
  macos-latest (release), ubuntu-latest (devel)

## R CMD check results

0 errors | 0 warnings | 0 notes

`R CMD check --run-donttest` is also clean (network examples
exercised against the live GHO and SDG APIs).

## Reverse dependencies

None.
