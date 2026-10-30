# Rebuild the internal legacy GHO catalog snapshot from the package root.
# Uses the raw transport so a failed refresh cannot repackage an old fallback.
library(pkgload)
library(tibble)

pkgload::load_all(".", quiet = TRUE, helpers = FALSE)
catalog.url <- "https://ghoapi.azureedge.net/api/Indicator"
catalog.raw <- DSIR:::.gho_get(catalog.url)
catalog.fields <- c("IndicatorCode", "IndicatorName", "Language")
stopifnot(
  is.data.frame(catalog.raw), nrow(catalog.raw) > 0L,
  all(catalog.fields %in% names(catalog.raw)),
  isTRUE(attr(catalog.raw, "who_provenance")$complete)
)
catalog.data <- as_tibble(catalog.raw[, catalog.fields])
stopifnot(
  all(vapply(catalog.data, is.character, logical(1))),
  !anyNA(catalog.data),
  all(vapply(catalog.data, function(x) all(nzchar(trimws(x))), logical(1))),
  !anyDuplicated(catalog.data[c("IndicatorCode", "Language")])
)
attr(catalog.data, "who_provenance") <- NULL
catalog.snapshot <- list(
  catalog = catalog.data,
  backend = "legacy",
  source = catalog.url,
  retrieved = format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC")
)
dir.create("inst/extdata", recursive = TRUE, showWarnings = FALSE)
saveRDS(catalog.snapshot, "inst/extdata/gho-indicators.rds", compress = "xz", version = 2)
message("Saved ", nrow(catalog.data), " legacy indicators, collected ", catalog.snapshot$retrieved)
