# Phase 1 probe for SDG API additions.
# Not part of the package; scratch/ is in .Rbuildignore.
#
# Probe A: which column on /Indicator/List holds the human-readable description?
# Probe B: confirm the sdg_data() response shape for a series-rich indicator.

devtools::load_all(".", quiet = TRUE)

cat("\n=========================\n")
cat("Probe A: sdg_indicators() text field\n")
cat("=========================\n\n")

res <- DSIR:::.sdg_get(
  "https://unstats.un.org/sdgs/UNSDGAPIV5/v1/sdg/Indicator/List"
)
cat("class: ", paste(class(res), collapse = ", "), "\n", sep = "")
cat("dim:   ", paste(dim(res), collapse = " x "), "\n", sep = "")
cat("names: ", paste(names(res), collapse = ", "), "\n\n", sep = "")
cat("--- str(head(res, 2)) ---\n")
str(head(res, 2), max.level = 2)
cat("\n--- sample description values ---\n")
print(utils::head(res$description, 3))


cat("\n\n=========================\n")
cat("Probe B: sdg_data response shape for series-rich indicator 3.4.1\n")
cat("=========================\n\n")

url <- paste0(
  "https://unstats.un.org/sdgs/UNSDGAPIV5/v1/sdg/Indicator/Data?",
  "indicator=3.4.1&areaCode=156&pageSize=5"
)
resp <- httr2::request(url) |>
  httr2::req_headers(Accept = "application/json") |>
  httr2::req_retry(max_tries = 3) |>
  httr2::req_perform()
body <- httr2::resp_body_json(resp, simplifyVector = TRUE)

cat("--- str(body, max.level = 2) ---\n")
str(body, max.level = 2)

cat("\n--- names(body$data) ---\n")
print(names(body$data))

cat("\n--- class of key columns ---\n")
for (col in c("series", "geoAreaCode", "timePeriodStart", "value")) {
  if (col %in% names(body$data)) {
    cat(sprintf("  %-18s class = %s\n", col,
                paste(class(body$data[[col]]), collapse = ",")))
  } else {
    cat(sprintf("  %-18s MISSING\n", col))
  }
}

cat("\n--- unique(body$data$series) ---\n")
print(unique(body$data$series))
