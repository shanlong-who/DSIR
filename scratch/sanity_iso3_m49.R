devtools::load_all(".", quiet = TRUE)

cat("\n=== iso3_to_m49('PHL') ===\n")
print(iso3_to_m49("PHL"))

cat("\n=== iso3_to_m49(c('PHL','FRA','JPN')) ===\n")
print(iso3_to_m49(c("PHL", "FRA", "JPN")))

cat("\n=== iso3_to_m49(c('PRI','PHL')) ===\n")
print(iso3_to_m49(c("PRI", "PHL")))

cat("\n=== iso3_to_m49('phl') ===\n")
print(iso3_to_m49("phl"))

cat("\n=== sdg_data('3.4.1', area = 'PHL')  (network) ===\n")
t <- system.time(a <- sdg_data("3.4.1", area = "PHL"))
cat(sprintf("rows: %d   elapsed: %.2fs\n", nrow(a), as.numeric(t["elapsed"])))
print(unique(a$geoAreaCode))

cat("\n=== sdg_data('3.4.1', area = wpro_cty) (network, full WPR) ===\n")
t <- system.time(b <- sdg_data("3.4.1", area = wpro_cty))
cat(sprintf("rows: %d   elapsed: %.2fs\n", nrow(b), as.numeric(t["elapsed"])))
cat("distinct locations:", length(unique(b$geoAreaCode)), "\n")

cat("\n=== sdg_coverage('3.4.1', area = c('PHL','FRA')) ===\n")
t <- system.time(d <- sdg_coverage("3.4.1", area = c("PHL", "FRA")))
cat(sprintf("rows: %d   elapsed: %.2fs\n", nrow(d), as.numeric(t["elapsed"])))
print(d)

cat("\n=== sdg_data('3.4.1', area = '608') (M49 backward compat) ===\n")
t <- system.time(e <- sdg_data("3.4.1", area = "608"))
cat(sprintf("rows: %d   elapsed: %.2fs\n", nrow(e), as.numeric(t["elapsed"])))

cat("\n=== sdg_data('3.4.1', area = c('608','250')) ===\n")
t <- system.time(f <- sdg_data("3.4.1", area = c("608","250")))
cat(sprintf("rows: %d   elapsed: %.2fs   distinct locs: %d\n",
            nrow(f), as.numeric(t["elapsed"]), length(unique(f$geoAreaCode))))

cat("\n=== sdg_data('3.4.1', area = c('PHL','608')) -- expect cli_abort about mixing ===\n")
out <- tryCatch(
  sdg_data("3.4.1", area = c("PHL", "608")),
  error = function(e) {
    cat("ERROR:", conditionMessage(e), "\n")
    NULL
  }
)
