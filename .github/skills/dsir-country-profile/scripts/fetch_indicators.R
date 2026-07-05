#!/usr/bin/env Rscript
# fetch_indicators.R -- pull GHO / SDG indicator data with DSIR, clean
# each pull to the unified 15-column schema, bind, and save.
#
# Usage:
#   Rscript fetch_indicators.R --gho WHOSIS_000001,NCDMORT3070 --sdg 3.4.1 \
#     --area PHL --year-from 2000 --dim1 SEX_BTSX --out phl_indicators.csv
#
# Arguments:
#   --gho          GHO indicator code(s), comma-separated (optional)
#   --sdg          SDG indicator code(s), comma-separated (optional)
#   --area         ISO3 code(s), comma-separated (optional = all areas)
#   --spatial-type GHO spatial level: country / region / global
#                  (optional; DSIR assumes "country" when --area is given)
#   --year-from    First year (optional)
#   --year-to      Last year (optional)
#   --dim1         GHO Dim1 filter, e.g. SEX_BTSX (optional; GHO only)
#   --out          Output path, .csv or .rds (required)
#
# Exits with status 1 when zero rows were fetched overall -- DSIR fails
# soft on network errors and wrong codes alike, so the row count is the
# only reliable success signal.

suppressPackageStartupMessages({
  library(DSIR)
  library(dplyr)
  library(readr)
})

parse_args <- function(args = commandArgs(trailingOnly = TRUE)) {
  out <- list()
  i <- 1L
  while (i <= length(args)) {
    key <- args[[i]]
    if (!startsWith(key, "--")) {
      stop("Unexpected argument: ", key, call. = FALSE)
    }
    key <- substring(key, 3L)
    if (i == length(args) || startsWith(args[[i + 1L]], "--")) {
      out[[key]] <- TRUE
      i <- i + 1L
    } else {
      out[[key]] <- args[[i + 1L]]
      i <- i + 2L
    }
  }
  out
}

split_csv <- function(x) {
  if (is.null(x)) NULL else trimws(strsplit(x, ",", fixed = TRUE)[[1]])
}

as_year <- function(x) if (is.null(x)) NULL else as.integer(x)

# GHO sex codes are prefixed (SEX_BTSX); a bare BTSX silently returns
# 0 rows (HTTP 200, empty body), so fix the three known bare codes.
fix_sex_codes <- function(x) {
  if (is.null(x)) return(NULL)
  bare <- x %in% c("BTSX", "MLE", "FMLE")
  if (any(bare)) {
    message("Prefixing bare GHO sex code(s) with 'SEX_': ",
            paste(x[bare], collapse = ", "))
    x[bare] <- paste0("SEX_", x[bare])
  }
  x
}

args <- parse_args()
gho.codes <- split_csv(args[["gho"]])
sdg.codes <- split_csv(args[["sdg"]])
out.path  <- args[["out"]]

if (is.null(gho.codes) && is.null(sdg.codes)) {
  stop("Provide at least one of --gho or --sdg.", call. = FALSE)
}
if (is.null(out.path) || isTRUE(out.path)) {
  stop("--out <path.csv|path.rds> is required.", call. = FALSE)
}

area         <- split_csv(args[["area"]])
spatial.type <- args[["spatial-type"]]
year.from    <- as_year(args[["year-from"]])
year.to      <- as_year(args[["year-to"]])
dim1         <- fix_sex_codes(split_csv(args[["dim1"]]))

if (is.null(spatial.type) && !is.null(area)) spatial.type <- "country"

cleaned <- list()

for (code in gho.codes) {
  raw <- gho_data(code, spatial_type = spatial.type, area = area,
                  year_from = year.from, year_to = year.to, dim1 = dim1)
  clean <- gho_clean(raw)
  message(sprintf("GHO %-24s %6d rows", code, nrow(clean)))
  if (nrow(clean) == 0L) {
    message("  hint: check the code spelling, dim1 values (SEX_ prefix!),",
            " and API reachability")
  }
  cleaned[[paste0("gho_", code)]] <- clean
}

for (code in sdg.codes) {
  raw <- sdg_data(code, area = area,
                  year_from = year.from, year_to = year.to)
  clean <- sdg_clean(raw)
  message(sprintf("SDG %-24s %6d rows", code, nrow(clean)))
  if (nrow(clean) == 0L) {
    message("  hint: check the indicator code (e.g. 3.4.1) and API",
            " reachability (unstats.un.org can be slow -- retry once)")
  }
  cleaned[[paste0("sdg_", code)]] <- clean
}

data.all <- do.call(bind_indicators, unname(cleaned))

if (nrow(data.all) == 0L) {
  message("No rows fetched for any indicator. Nothing written.")
  quit(status = 1L)
}

if (grepl("\\.rds$", out.path, ignore.case = TRUE)) {
  saveRDS(data.all, out.path)
} else {
  write_csv(data.all, out.path, na = "")
}

message(sprintf("Wrote %d rows x %d cols to %s",
                nrow(data.all), ncol(data.all), out.path))
print(as.data.frame(count(data.all, source, id, name = "rows")),
      row.names = FALSE)
