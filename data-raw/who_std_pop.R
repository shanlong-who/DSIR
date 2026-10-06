# Rebuild the WHO 2026 Standard Population from WHO's published Table 1.
# Source: WHO/HSA/DDA/GHE/2026.4, September 2026, page 6.
# https://cdn.who.int/media/docs/default-source/gho-documents/global-health-estimates/ghe2023_who_standard_population.pdf
# Accessed: 2026-10-06. Based on projected world population, 2026-2050.
# Published percentages sum to 100.02 because of rounding. Normalize them
# explicitly. The standard million is derived, not a published WHO count.
# Keep 85+ intact: the published table supplies no finer weights.
# Run from the package root: source('data-raw/who_std_pop.R').
library(tibble)
library(usethis)

published_percent <- c(7.21, 7.13, 7.11, 7.12, 7.15, 7.08, 6.89, 6.66,
                       6.35, 6.04, 5.75, 5.41, 4.97, 4.43, 3.77, 2.98,
                       2.08, 1.89)
age_start <- seq.int(0L, 85L, by = 5L)
who_std_pop <- tibble(
  age_group = c(paste0(age_start[1:17], '-', age_start[1:17] + 4L), '85+'),
  age_start = age_start,
  weight = published_percent / sum(published_percent) * 100,
  std_million = published_percent / sum(published_percent) * 1e6
)
stopifnot(nrow(who_std_pop) == 18L, !anyNA(who_std_pop),
          !anyDuplicated(who_std_pop$age_group), all(who_std_pop$weight >= 0),
          abs(sum(who_std_pop$weight) - 100) < 1e-12,
          abs(sum(who_std_pop$std_million) - 1e6) < 1e-8)
usethis::use_data(who_std_pop, overwrite = TRUE)
