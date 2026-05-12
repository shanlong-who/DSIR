# Manual sanity calls for the four acceptance-criteria cases.
devtools::load_all(".", quiet = TRUE)

cat("\n=== A. sdg_indicators('mortality cancer') ===\n")
a <- sdg_indicators("mortality cancer")
print(a)
cat("\nAll rows contain both terms (case-insensitive substring)?\n")
print(all(
  grepl("mortality", tolower(a$description), fixed = TRUE) &
  grepl("cancer",    tolower(a$description), fixed = TRUE)
))


cat("\n\n=== B. sdg_indicators(c('maternal', 'mortality')) ===\n")
b <- sdg_indicators(c("maternal", "mortality"))
print(b)
cat("\nAll rows contain both terms?\n")
print(all(
  grepl("maternal",  tolower(b$description), fixed = TRUE) &
  grepl("mortality", tolower(b$description), fixed = TRUE)
))


cat("\n\n=== C. Backward compat: sdg_indicators('mortality') ===\n")
c_now  <- sdg_indicators("mortality")
c_full <- sdg_indicators()
c_manual <- c_full[grepl("mortality", tolower(c_full$description),
                         fixed = TRUE), , drop = FALSE]
cat("rows:                 ", nrow(c_now), "\n", sep = "")
cat("rows of manual filter:", nrow(c_manual), "\n", sep = "")
cat("identical?            ", identical(c_now, c_manual), "\n", sep = "")
print(c_now)


cat("\n\n=== D. sdg_coverage('3.4.1', area = c('156', '608')) ===\n")
d <- sdg_coverage("3.4.1", area = c("156", "608"))
print(d)
cat("\nColumn classes:\n")
print(sapply(d, function(x) paste(class(x), collapse = ",")))
cat("\nRows per location (should be > 1 to confirm multi-row-per-location):\n")
print(table(d$location))
