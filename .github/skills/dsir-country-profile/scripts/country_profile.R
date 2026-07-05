#!/usr/bin/env Rscript
# country_profile.R -- generate a country profile from a cleaned DSIR
# indicator table (the unified 15-column schema produced by
# fetch_indicators.R or by gho_clean() / sdg_clean() directly).
#
# Usage:
#   Rscript country_profile.R --data phl_indicators.csv --iso3 PHL \
#     --out-dir outputs/profile_PHL [--target-year 2030]
#
# Arguments:
#   --data         Input .csv or .rds in the 15-column schema (required)
#   --iso3         Target country ISO3 code (required)
#   --out-dir      Output directory (default: outputs/profile_<ISO3>)
#   --target-year  Projection year for the AARR extrapolation (default 2030)
#
# Outputs in --out-dir:
#   profile.md        markdown summary: AARR table + embedded figures
#   aarr_summary.csv  per-indicator/stratum AARR, notes, projection
#   profile_data.csv  the country subset of the input (plus `stratum`)
#   figures/          one trend PNG per indicator (theme_dsi, Okabe-Ito)

suppressPackageStartupMessages({
  library(DSIR)
  library(dplyr)
  library(readr)
  library(ggplot2)
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

wrap_chr <- function(x, width = 70) paste(strwrap(x, width), collapse = "\n")

fmt_num <- function(x) {
  vapply(x, function(v) {
    if (is.na(v)) return("-")
    format(signif(v, 4), big.mark = ",", scientific = FALSE, trim = TRUE)
  }, character(1))
}

# Run aarr() capturing its warnings as a note instead of console noise;
# the note travels into aarr_summary.csv so mixed-strata groups are
# visible in the output, not just on stderr.
aarr_with_note <- function(year, value) {
  notes <- character(0)
  est <- withCallingHandlers(
    aarr(year, value),
    warning = function(w) {
      notes <<- c(notes, gsub("\\s+", " ", conditionMessage(w)))
      invokeRestart("muffleWarning")
    }
  )
  list(aarr = est,
       note = if (length(notes) > 0) paste(notes, collapse = " | ")
              else NA_character_)
}

# ---- Arguments -------------------------------------------------------

args <- parse_args()
if (is.null(args[["data"]]) || isTRUE(args[["data"]])) {
  stop("--data <file.csv|file.rds> is required.", call. = FALSE)
}
if (is.null(args[["iso3"]]) || isTRUE(args[["iso3"]])) {
  stop("--iso3 <code> is required.", call. = FALSE)
}
data.path   <- args[["data"]]
iso3.target <- toupper(trimws(args[["iso3"]]))
out.dir     <- args[["out-dir"]] %||%
  file.path("outputs", paste0("profile_", iso3.target))
target.year <- as.integer(args[["target-year"]] %||% "2030")

# ---- Read and validate input ----------------------------------------

schema.cols <- c("source", "id", "indicator", "location", "iso3",
                 "location_name", "year", "value", "value_num",
                 "low", "high", "series", "dim1", "dim2", "dim3")

if (grepl("\\.rds$", data.path, ignore.case = TRUE)) {
  data.raw <- readRDS(data.path)
} else {
  data.raw <- suppressWarnings(read_csv(
    data.path,
    col_types = cols(
      source = col_character(), id = col_character(),
      indicator = col_character(), location = col_character(),
      iso3 = col_character(), location_name = col_character(),
      year = col_integer(), value = col_character(),
      value_num = col_double(), low = col_double(), high = col_double(),
      series = col_character(), dim1 = col_character(),
      dim2 = col_character(), dim3 = col_character()
    ),
    show_col_types = FALSE
  ))
}

missing.cols <- setdiff(schema.cols, names(data.raw))
if (length(missing.cols) > 0) {
  stop("Input is not in the unified 15-column schema; missing: ",
       paste(missing.cols, collapse = ", "), call. = FALSE)
}

data.cty <- data.raw %>% filter(iso3 == iso3.target)
if (nrow(data.cty) == 0L) {
  available <- sort(unique(na.omit(data.raw$iso3)))
  stop("No rows for ", iso3.target, ". ISO3 codes present in the data: ",
       paste(available, collapse = ", "), call. = FALSE)
}

country.name <- who_countries$name_short[match(iso3.target,
                                               who_countries$iso3)]
if (is.na(country.name)) country.name <- iso3.target

# One stratum label per row: GHO breakdowns live in dim1, SDG series in
# series. "total" marks rows with neither.
data.cty <- data.cty %>%
  mutate(stratum = coalesce(dim1, series, "total"))

data.plot <- data.cty %>% filter(!is.na(year), !is.na(value_num))
if (nrow(data.plot) == 0L) {
  stop("All rows have missing year or non-numeric value ",
       "(inspect the raw `value` column -- entries like \"<0.1\" do ",
       "not coerce).", call. = FALSE)
}

# ---- AARR summary per indicator x stratum ----------------------------

data.plot <- data.plot %>%
  mutate(group_key = paste(source, id, stratum, sep = "\x1f"))

summary.tbl <- data.plot %>%
  summarise(
    indicator    = indicator[order(is.na(indicator))][1],
    n_obs        = n(),
    year_first   = min(year),
    year_last    = max(year),
    value_first  = mean(value_num[year == min(year)]),
    value_latest = mean(value_num[year == max(year)]),
    .by = c(group_key, source, id, stratum)
  )

est.list <- lapply(summary.tbl$group_key, function(k) {
  d <- data.plot[data.plot$group_key == k, ]
  aarr_with_note(d$year, d$value_num)
})
summary.tbl <- summary.tbl %>%
  mutate(
    aarr      = vapply(est.list, function(x) x$aarr, numeric(1)),
    aarr_note = vapply(est.list, function(x) x$note, character(1)),
    aarr_pct  = round(100 * aarr, 2),
    target_year = target.year,
    value_projected = if_else(
      !is.na(aarr) & year_last < target.year,
      value_latest * (1 - aarr) ^ (target.year - year_last),
      NA_real_
    )
  ) %>%
  arrange(source, id, stratum) %>%
  select(source, id, indicator, stratum, n_obs, year_first, year_last,
         value_first, value_latest, aarr, aarr_pct,
         target_year, value_projected, aarr_note)

# ---- Trend charts, one per (source, id) ------------------------------

fig.dir <- file.path(out.dir, "figures")
dir.create(fig.dir, recursive = TRUE, showWarnings = FALSE)

# Okabe-Ito without black (black reads as "no encoding" on line charts);
# single-stratum charts use the theme_dsi accent instead of a palette.
okabe.ito <- unname(grDevices::palette.colors(9, palette = "Okabe-Ito"))[-1]
accent <- "#0093D5"
source.labels <- c(gho = "WHO Global Health Observatory",
                   sdg = "UN SDG Global Database")

chart.keys <- summary.tbl %>% distinct(source, id)
chart.keys$file <- NA_character_
chart.keys$label <- NA_character_

for (i in seq_len(nrow(chart.keys))) {
  d <- data.plot %>%
    filter(source == chart.keys$source[i], id == chart.keys$id[i])

  ind.label <- d$indicator[order(is.na(d$indicator))][1]
  if (is.na(ind.label)) ind.label <- chart.keys$id[i]
  n.strata  <- length(unique(d$stratum))
  dup.years <- anyDuplicated(d[, c("stratum", "year")]) > 0
  ci.data   <- d %>% filter(!is.na(low), !is.na(high))

  caption <- paste0("Source: ",
                    source.labels[[chart.keys$source[i]]] %||%
                      chart.keys$source[i])
  if (dup.years) {
    caption <- paste0(caption,
                      "\nPoints: individual observations; line: annual",
                      " mean (multiple observations per year).")
  }

  p <- ggplot(d, aes(x = year, y = value_num))

  if (n.strata == 1) {
    if (nrow(ci.data) > 0 && !dup.years) {
      p <- p + geom_ribbon(data = ci.data, aes(ymin = low, ymax = high),
                           fill = accent, alpha = 0.15)
    }
    if (dup.years) {
      p <- p +
        geom_point(color = accent, size = 1.6, alpha = 0.6) +
        stat_summary(fun = mean, geom = "line", color = accent,
                     linewidth = 0.8)
    } else {
      p <- p +
        geom_line(color = accent, linewidth = 0.8) +
        geom_point(color = accent, size = 1.8)
    }
  } else {
    if (nrow(ci.data) > 0 && !dup.years) {
      p <- p + geom_ribbon(
        data = ci.data,
        aes(ymin = low, ymax = high, fill = stratum),
        alpha = 0.15, color = NA
      )
    }
    if (dup.years) {
      p <- p +
        geom_point(aes(color = stratum), size = 1.6, alpha = 0.6) +
        stat_summary(aes(color = stratum), fun = mean, geom = "line",
                     linewidth = 0.8)
    } else {
      p <- p +
        geom_line(aes(color = stratum), linewidth = 0.8) +
        geom_point(aes(color = stratum), size = 1.8)
    }
    if (n.strata <= length(okabe.ito)) {
      p <- p + scale_color_manual(values = okabe.ito) +
        scale_fill_manual(values = okabe.ito)
    } else {
      p <- p + scale_color_viridis_d(end = 0.9) +
        scale_fill_viridis_d(end = 0.9)
    }
  }

  p <- p +
    theme_dsi() +
    labs(title = wrap_chr(ind.label),
         subtitle = paste0(country.name, " (", iso3.target, ")"),
         x = NULL, y = NULL, color = NULL, fill = NULL,
         caption = caption)

  safe.id <- gsub("[^A-Za-z0-9._-]", "_", chart.keys$id[i])
  file.name <- paste0("trend_", chart.keys$source[i], "_", safe.id, ".png")
  ggsave(file.path(fig.dir, file.name), p,
         width = 8, height = 4.5, dpi = 300)

  chart.keys$file[i]  <- file.name
  chart.keys$label[i] <- ind.label
  message("figure: ", file.name)
}

# ---- Write tables ----------------------------------------------------

write_csv(summary.tbl, file.path(out.dir, "aarr_summary.csv"), na = "")
write_csv(data.cty, file.path(out.dir, "profile_data.csv"), na = "")

# ---- profile.md ------------------------------------------------------

esc <- function(x) gsub("\\|", "/", x)
trunc60 <- function(x) {
  ifelse(nchar(x) > 60, paste0(substr(x, 1, 57), "..."), x)
}

md <- c(
  paste0("# Country profile: ", country.name, " (", iso3.target, ")"),
  "",
  paste0("Generated on ", format(Sys.Date()), " with DSIR ",
         as.character(utils::packageVersion("DSIR")), "."),
  "",
  paste0("AARR = average annual rate of reduction (regression method), ",
         "in % per year. Positive = declining -- progress for ",
         "mortality-type indicators; for \"higher is better\" ",
         "indicators (coverage, life expectancy) a negative AARR means ",
         "improvement. Projection extrapolates the latest value to ",
         target.year, " at the observed AARR."),
  "",
  "## Indicator summary",
  "",
  paste0("| Indicator | Stratum | Years | First | Latest | AARR %/yr | ",
         "Projected ", target.year, " |"),
  "|---|---|---|---|---|---|---|"
)

for (i in seq_len(nrow(summary.tbl))) {
  s <- summary.tbl[i, ]
  label <- if (is.na(s$indicator)) s$id else s$indicator
  md <- c(md, paste0(
    "| ", esc(trunc60(label)),
    " | ", esc(s$stratum),
    " | ", s$year_first, "-", s$year_last,
    " | ", fmt_num(s$value_first), " (", s$year_first, ")",
    " | ", fmt_num(s$value_latest), " (", s$year_last, ")",
    " | ", fmt_num(s$aarr_pct),
    " | ", fmt_num(s$value_projected),
    " |"
  ))
}

notes <- summary.tbl %>% filter(!is.na(aarr_note))
if (nrow(notes) > 0) {
  md <- c(md, "", "### Notes", "")
  for (i in seq_len(nrow(notes))) {
    md <- c(md, paste0("- **", notes$id[i], " / ", notes$stratum[i],
                       "**: ", notes$aarr_note[i]))
  }
}

md <- c(md, "", "## Trends", "")
for (i in seq_len(nrow(chart.keys))) {
  md <- c(md,
          paste0("### ", chart.keys$label[i]),
          "",
          paste0("![", chart.keys$id[i], "](figures/",
                 chart.keys$file[i], ")"),
          "")
}

con <- file(file.path(out.dir, "profile.md"), open = "w",
            encoding = "UTF-8")
writeLines(md, con)
close(con)

message("Profile written to ", normalizePath(out.dir, winslash = "/"),
        ": profile.md, aarr_summary.csv, profile_data.csv, figures/ (",
        nrow(chart.keys), " chart", if (nrow(chart.keys) != 1) "s", ")")
