# Build all three public discovery catalogs from the package root.
# No observation availability is inferred from catalog membership.
#
# Normal refresh: source("data-raw/catalogs.R")
# Optional replay: DSIR_CATALOG_INPUT_DIR contains legacy.rds, xmart.rds,
# sdg.rds and ghe.rds saved by this script (original retrieval times retained).
# Set DSIR_CATALOG_CAPTURE_DIR to retain new source captures outside maintained
# package data. Historical legacy fallback is allowed only for the FIRST build
# with DSIR_ALLOW_CATALOG_SNAPSHOT=true. It cannot replace an existing catalog.

library(pkgload)
library(tibble)

pkgload::load_all(".", quiet = TRUE, helpers = FALSE, export_all = FALSE)
catalog.time <- function() format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC")
catalog.input.dir <- Sys.getenv("DSIR_CATALOG_INPUT_DIR")
catalog.capture.dir <- Sys.getenv("DSIR_CATALOG_CAPTURE_DIR")
catalog.allow.snapshot <- identical(Sys.getenv("DSIR_ALLOW_CATALOG_SNAPSHOT"), "true")

if (nzchar(catalog.input.dir)) {
  inputs <- lapply(c("legacy", "xmart", "sdg", "ghe"), function(name) {
    readRDS(file.path(catalog.input.dir, paste0(name, ".rds")))
  })
  names(inputs) <- c("legacy", "xmart", "sdg", "ghe")
} else {
  inputs <- list()
  for (backend in c("legacy", "xmart")) {
    started <- catalog.time()
    catalog <- DSIR::gho_indicators(backend = backend)
    directory <- if (backend == "xmart") DSIR:::.xmart_catalog() else NULL
    inputs[[backend]] <- list(catalog = catalog, directory = directory,
      attempted_at = started, finished_at = catalog.time())
  }
  sdg.live <- DSIR::sdg_indicators()
  if (is.null(sdg.live)) stop("SDG catalog retrieval failed. Existing catalogs are unchanged.")
  inputs$sdg <- list(catalog = sdg.live, retrieved_at = DSIR::dsir_metadata(sdg.live)$sources$retrieved_at[[1]])
  causes <- DSIR::ghe_causes()
  measures <- DSIR::ghe_dimensions("measure")
  cache.key <- paste("xmart", DSIR:::.who_config("xmart")$base, "ghe_causes", sep = "|")
  origin <- attr(DSIR:::.who_cache[[cache.key]]$value, "who_provenance", exact = TRUE)
  inputs$ghe <- list(causes = causes, measures = measures,
    year = DSIR:::.ghe_latest(), area = DSIR:::.ghe_reference_area(),
    provenance = origin, retrieved_at = DSIR::dsir_metadata(measures)$sources$retrieved_at[[1]])
  if (nzchar(catalog.capture.dir)) {
    dir.create(catalog.capture.dir, recursive = TRUE, showWarnings = FALSE)
    for (name in names(inputs)) saveRDS(inputs[[name]], file.path(catalog.capture.dir, paste0(name, ".rds")))
  }
}

legacy.snapshot <- attr(inputs$legacy$catalog, "catalog_snapshot", exact = TRUE)
legacy.origin <- attr(inputs$legacy$catalog, "who_provenance", exact = TRUE)
if (!is.null(legacy.snapshot)) {
  if (!catalog.allow.snapshot || file.exists("data/gho_catalog.rda")) {
    stop("Legacy retrieval used a historical fallback. Existing catalogs are unchanged.")
  }
  legacy.time <- legacy.snapshot$retrieved
  legacy.status <- "bundled_snapshot"
} else {
  stopifnot(isTRUE(legacy.origin$complete))
  legacy.time <- legacy.origin$retrieved
  legacy.status <- "live"
}
xmart.origin <- attr(inputs$xmart$directory, "who_provenance", exact = TRUE)
stopifnot(isTRUE(xmart.origin$complete), isTRUE(inputs$ghe$provenance$complete))

gho.data <- DSIR:::.dsi_catalog_gho(inputs$legacy$catalog, inputs$xmart$catalog)
sdg.data <- DSIR:::.dsi_catalog_sdg(inputs$sdg$catalog)
ghe.data <- DSIR:::.dsi_catalog_ghe(inputs$ghe$causes, inputs$ghe$measures)
bundled.at <- catalog.time()
package.version <- unname(read.dcf("DESCRIPTION", fields = "Version")[[1]])

source_row <- function(component, backend, endpoint, retrieved_at, count,
                       status = "live", api_version = NA_character_, release = NA_character_) {
  # Both formats are recorded as UTC by the existing DSIR retrieval code.
  date.format <- if (grepl("T", retrieved_at, fixed = TRUE)) "%Y-%m-%dT%H:%M:%SZ" else "%Y-%m-%d %H:%M:%S"
  retrieved.time <- as.POSIXct(strptime(retrieved_at, date.format, tz = "UTC"))
  stopifnot(length(retrieved.time) == 1L, !is.na(retrieved.time))
  tibble(component = component, backend = backend, endpoint = endpoint,
         retrieved_at = format(retrieved.time, "%Y-%m-%dT%H:%M:%SZ", tz = "UTC"), retrieval_status = status,
         record_count = as.integer(count), api_version = api_version, source_release = release)
}

gho.sources <- rbind(
  source_row("indicators", "legacy", "https://ghoapi.azureedge.net/api/Indicator",
             legacy.time, nrow(inputs$legacy$catalog), status = legacy.status),
  source_row("indicators", "xmart", "https://xmart-api-public.who.int/DATA_/IND_DIRECTORY_WIDE",
             xmart.origin$retrieved, nrow(inputs$xmart$catalog))
)
releases <- unique(unlist(lapply(sdg.data$series, function(x) x$release), use.names = FALSE))
releases <- sort(releases[!is.na(releases) & nzchar(releases)])
sdg.sources <- source_row("indicators", "unsdg",
  "https://unstats.un.org/sdgs/UNSDGAPIV5/v1/sdg/Indicator/List",
  inputs$sdg$retrieved_at, nrow(sdg.data), api_version = "V5",
  release = if (length(releases)) paste(releases, collapse = "; ") else NA_character_)
ghe.sources <- rbind(
  source_row("causes", "xmart", "https://xmart-api-public.who.int/DEX_CMS/GHE_FULL",
             inputs$ghe$provenance$retrieved, nrow(inputs$ghe$causes)),
  source_row("measures", "xmart", "https://xmart-api-public.who.int/DEX_CMS/GHE_FULL?$top=1",
             inputs$ghe$retrieved_at, nrow(inputs$ghe$measures))
)

gho_catalog <- DSIR:::.dsi_catalog_attach(gho.data, "gho_catalog", gho.sources, bundled.at, package.version,
  scope = list(xmart_language = "en", xmart_directory_rows = xmart.origin$rows))
sdg_catalog <- DSIR:::.dsi_catalog_attach(sdg.data, "sdg_catalog", sdg.sources, bundled.at, package.version,
  scope = list(provider_releases = releases, series_links = "provider nested indicator-to-series links"))
ghe_catalog <- DSIR:::.dsi_catalog_attach(ghe.data, "ghe_catalog", ghe.sources, bundled.at, package.version,
  scope = list(cause_reference = list(year = inputs$ghe$year, area = inputs$ghe$area,
    age = "TOTAL", sex = "TOTAL", filter = inputs$ghe$provenance$filter),
    measures = "DSIR measure definitions whose fields occur in the provider schema"))

# All inputs and outputs are validated before any maintained snapshot is written.
save(gho_catalog, file = "data/gho_catalog.rda", compress = "xz", version = 2)
save(sdg_catalog, file = "data/sdg_catalog.rda", compress = "xz", version = 2)
save(ghe_catalog, file = "data/ghe_catalog.rda", compress = "xz", version = 2)
message("Saved catalogs: GHO ", nrow(gho_catalog), ", SDG ", nrow(sdg_catalog),
        ", GHE ", nrow(ghe_catalog), ". Snapshot version: ", bundled.at)
