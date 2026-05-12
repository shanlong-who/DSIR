devtools::load_all(".", quiet = TRUE)

run <- function(label, expr) {
  cat(sprintf("\n=== %s ===\n", label))
  t <- system.time(out <- eval(expr))
  cat(sprintf("elapsed: %.2fs   rows: %d   under 30s: %s\n",
              as.numeric(t["elapsed"]),
              if (is.data.frame(out)) nrow(out) else NA_integer_,
              if (as.numeric(t["elapsed"]) < 30) "YES" else "NO"))
  invisible(out)
}

a <- run('sdg_data("3.2.1", area = "608", year_from = 2010)',
         quote(sdg_data("3.2.1", area = "608", year_from = 2010)))
yr <- suppressWarnings(as.integer(a$timePeriodStart))
cat(sprintf("year range: [%d, %d]\n", min(yr, na.rm = TRUE), max(yr, na.rm = TRUE)))

b <- run('sdg_data("3.2.1", area = "608", year_from = 2015, year_to = 2018)',
         quote(sdg_data("3.2.1", area = "608", year_from = 2015, year_to = 2018)))
yr <- suppressWarnings(as.integer(b$timePeriodStart))
cat(sprintf("year range: [%d, %d]\n", min(yr, na.rm = TRUE), max(yr, na.rm = TRUE)))

cov <- run('sdg_coverage("3.2.1", area = "608", year_from = 2010)',
           quote(sdg_coverage("3.2.1", area = "608", year_from = 2010)))
print(cov)
