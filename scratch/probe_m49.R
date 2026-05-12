# Phase 1 probe: verify who_countries$un_m49 format before
# implementing iso3_to_m49() and area-resolution logic.
devtools::load_all(".", quiet = TRUE)

cat("--- names(who_countries) ---\n")
print(names(who_countries))

cat("\n--- str(who_countries$un_m49) ---\n")
str(who_countries$un_m49)

cat("\n--- head(who_countries$un_m49, 12) ---\n")
print(head(who_countries$un_m49, 12))

cat("\n--- NA count ---\n")
cat(sum(is.na(who_countries$un_m49)), "\n")

cat("\n--- distinct nchar (after stringification) ---\n")
v <- as.character(who_countries$un_m49)
print(table(nchar(v), useNA = "ifany"))

cat("\n--- known landmark values ---\n")
idx <- match(c("PHL", "FRA", "JPN", "IDN", "USA", "BRA"),
             who_countries$iso3)
print(data.frame(
  iso3 = c("PHL", "FRA", "JPN", "IDN", "USA", "BRA"),
  un_m49_value = who_countries$un_m49[idx],
  un_m49_as_chr = as.character(who_countries$un_m49[idx])
))

cat("\n--- ISO3 column regex sanity ---\n")
iso3_vals <- who_countries$iso3
cat("all match ^[A-Za-z]{3}$ ? ",
    all(grepl("^[A-Za-z]{3}$", iso3_vals)), "\n", sep = "")

cat("\n--- M49 column regex sanity (against ^[0-9]+$) ---\n")
m49_chr <- as.character(who_countries$un_m49)
cat("all match ^[0-9]+$ ? ",
    all(grepl("^[0-9]+$", m49_chr[!is.na(m49_chr)])), "\n", sep = "")
cat("M49 with leading zero present ? ",
    any(grepl("^0", m49_chr[!is.na(m49_chr)])), "\n", sep = "")

cat("\n--- documentation ---\n")
# R/data.R holds the roxygen for who_countries.
if (file.exists("R/data.R")) {
  cat(readLines("R/data.R", warn = FALSE), sep = "\n")
}
