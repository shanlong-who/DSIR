# =============================================================================
# data-raw/who_std_pop.R
#
# Build the WHO World Standard Population dataset shipped with DSIR.
#
# This is the single source of truth for `who_std_pop`. The weights are the
# fixed WHO World Standard (world average population 2000-2025) and do not
# change, so this script rarely needs re-running.
#
# Run from the package root with:
#   source("data-raw/who_std_pop.R")
#
# Source:
# - Ahmad OB, Boschi-Pinto C, Lopez AD, Murray CJL, Lozano R, Inoue M (2001).
#   "Age standardization of rates: a new WHO standard." GPE Discussion Paper
#   Series No. 31. World Health Organization.
#   Table 4 (p.11) gives the 21-group distribution (0-4, 5-9, ..., 100+);
#   Table 1 (p.10) gives the 18-group form with 85+ aggregated.
# - Cross-checked against the SEER "World (WHO 2000-2025) Standard" million
#   (<https://seer.cancer.gov/stdpopulations/world.who.html>); the two agree
#   exactly. The published percentages sum to 100.035, which SEER resolves by
#   recalculating to a standard million summing to 1,000,000 (the only numeric
#   adjustment is 90-94 rounded up from 1,499.48 to 1,500).
# =============================================================================

library(tibble)
library(usethis)

# -----------------------------------------------------------------------------
# 21 five-year age groups, terminal group 100+.
# `weight` is the published WHO percentage; `std_million` is the SEER standard
# million (per 1,000,000). Both are carried verbatim from the sources above.
# age_standardize() normalises the weights internally, so the fact that the
# percentages sum to 100.035 rather than 100 has no effect on results.
# -----------------------------------------------------------------------------

who_std_pop <- tribble(
  ~age_group, ~age_start, ~weight, ~std_million,
  "0-4",              0L,   8.860,       88569L,
  "5-9",              5L,   8.690,       86870L,
  "10-14",           10L,   8.600,       85970L,
  "15-19",           15L,   8.470,       84670L,
  "20-24",           20L,   8.220,       82171L,
  "25-29",           25L,   7.930,       79272L,
  "30-34",           30L,   7.610,       76073L,
  "35-39",           35L,   7.150,       71475L,
  "40-44",           40L,   6.590,       65877L,
  "45-49",           45L,   6.040,       60379L,
  "50-54",           50L,   5.370,       53681L,
  "55-59",           55L,   4.550,       45484L,
  "60-64",           60L,   3.720,       37187L,
  "65-69",           65L,   2.960,       29590L,
  "70-74",           70L,   2.210,       22092L,
  "75-79",           75L,   1.520,       15195L,
  "80-84",           80L,   0.910,        9097L,
  "85-89",           85L,   0.440,        4398L,
  "90-94",           90L,   0.150,        1500L,
  "95-99",           95L,   0.040,         400L,
  "100+",           100L,   0.005,          50L
)

# -----------------------------------------------------------------------------
# Sanity checks (fail loudly if anything is off).
# -----------------------------------------------------------------------------

stopifnot(
  "who_std_pop should have 21 rows"        = nrow(who_std_pop) == 21,
  "age_start should be strictly increasing" =
    all(diff(who_std_pop$age_start) > 0),
  "percentages should sum to 100.035"      =
    isTRUE(all.equal(sum(who_std_pop$weight), 100.035)),
  "standard million should sum to 1e6"     =
    sum(who_std_pop$std_million) == 1000000L,
  "no missing values"                      = !anyNA(who_std_pop)
)

# -----------------------------------------------------------------------------
# Save to data/.
# -----------------------------------------------------------------------------

usethis::use_data(who_std_pop, overwrite = TRUE)

message("\nDone. who_std_pop written to data/ (", nrow(who_std_pop), " age groups).")
