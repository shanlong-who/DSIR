# DSIR 0.2.0

Initial CRAN submission. Renamed from `DSI` to avoid a name clash
with the existing CRAN `DSI` package.

## New features

* `gho_dimensions()` returns the unique values of a dimension
  column for a given GHO indicator, to make it easier to discover
  which breakdowns (sex, age, region, etc.) are available before
  calling `gho_data()`.
* `sdg_targets()` lists Sustainable Development Goal targets from
  the UN SDG API, complementing `sdg_goals()` and
  `sdg_indicators()`.

## Improvements

* `theme_dsi()` and `dsi_flextable_defaults()` now default to the
  device / package default font (`base_family = ""`), so they work
  on systems where Cambria is not installed. Pass
  `base_family = "Cambria"` to get the original look.
* `ggpie()` gains input validation and uses tidy-evaluation
  helpers internally, so `R CMD check` no longer reports
  undefined global variables.
* `gho_*()` and `sdg_*()` now fail gracefully when the remote
  service is unreachable, per CRAN policy for packages that hit
  the network. They warn and return an empty data frame (or
  `NULL`) instead of raising a hard error.
* Full `roxygen2` help pages for every exported function, with
  cross-references between related functions.
* All runnable examples use `\donttest{}` (not `\dontrun{}`) for
  network-dependent code, so CRAN reviewers can opt into running
  them.
