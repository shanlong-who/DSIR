# Pre-populate the GHO indicator-catalog cache used by gho_clean() so
# unit tests don't trigger a network call when looking up indicator
# names. Tests that need a different cache state (e.g. empty catalog,
# unknown codes) can override .dsi_cache$gho_indicator_catalog locally
# and restore via on.exit().
#
# Helper files are sourced into the package namespace, so `.dsi_cache`
# is reachable directly without a `DSIR:::` prefix.
.dsi_cache$gho_indicator_catalog <- tibble::tibble(
  IndicatorCode = c("WHOSIS_000001"),
  IndicatorName = c("Life expectancy at birth (years)"),
  Language      = c("EN")
)
