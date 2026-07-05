#!/usr/bin/env Rscript
# check_availability.R -- check GHO / SDG data availability before a pull.
#
# Usage:
#   Rscript check_availability.R --gho NCDMORT3070 --area PHL,VNM
#   Rscript check_availability.R --sdg 3.4.1 --area PHL --year-from 2000
#
# Arguments:
#   --gho        GHO indicator code(s), comma-separated
#   --sdg        SDG indicator code(s), comma-separated (e.g. 3.4.1)
#   --area       ISO3 code(s), comma-separated (optional; default = all)
#   --year-from  First year (optional)
#   --year-to    Last year (optional)
#   --dim1       GHO Dim1 filter, e.g. SEX_BTSX (optional; GHO only)
#
# Prints one coverage table per indicator (location, [series,] year_min,
# year_max, n_obs). An empty table means no data OR the API was
# unreachable -- DSIR fails soft with a warning on stderr, never an error.

suppressPackageStartupMessages({
  library(DSIR)
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
if (is.null(gho.codes) && is.null(sdg.codes)) {
  stop("Provide at least one of --gho or --sdg.", call. = FALSE)
}

area      <- split_csv(args[["area"]])
year.from <- as_year(args[["year-from"]])
year.to   <- as_year(args[["year-to"]])
dim1      <- fix_sex_codes(split_csv(args[["dim1"]]))

for (code in gho.codes) {
  cat("\n== GHO", code, "==\n")
  coverage <- gho_coverage(code, area = area,
                           year_from = year.from, year_to = year.to,
                           dim1 = dim1)
  print(as.data.frame(coverage), row.names = FALSE)
  n.total <- gho_count(code, spatial_type = "country", area = area,
                       year_from = year.from, year_to = year.to,
                       dim1 = dim1)
  cat("Country-level observations (server count):", n.total, "\n")
}

for (code in sdg.codes) {
  cat("\n== SDG", code, "==\n")
  coverage <- sdg_coverage(code, area = area,
                           year_from = year.from, year_to = year.to)
  print(as.data.frame(coverage), row.names = FALSE)
  if (nrow(coverage) > 0) {
    cat("Series present:",
        paste(sort(unique(coverage$series)), collapse = ", "), "\n")
  }
}
