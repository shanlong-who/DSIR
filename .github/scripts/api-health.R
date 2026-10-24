# Repository maintenance only; this file is excluded from the CRAN package.
library(DSIR)

health_cases <- function() {
  list(
    gho_legacy = list(
      backend = "legacy", source = "gho",
      query = "MDG_0000000026; PHL; 2020; no sex breakdown",
      expected = list(id = "MDG_0000000026", iso3 = "PHL", year = 2020L,
                      dim1 = NA_character_, provider = "legacy"),
      fetch = function() gho_data("MDG_0000000026", spatial_type = "country", area = "PHL",
                                  year_from = 2020, year_to = 2020, backend = "legacy"),
      clean = function(x) gho_clean(x, keep_dimensions = TRUE, keep_metadata = TRUE)),
    gho_xmart = list(
      backend = "xmart", source = "gho",
      query = "NCDMORT3070; PHL; 2020; DIM_SEX=TOTAL",
      expected = list(id = "NCDMORT3070", iso3 = "PHL", year = 2020L,
                      dim_sex = "TOTAL", provider = "xmart"),
      fetch = function() gho_data("NCDMORT3070", spatial_type = "country", area = "PHL",
                                  year_from = 2020, year_to = 2020,
                                  dimensions = list(DIM_SEX = "TOTAL"), backend = "xmart"),
      clean = function(x) gho_clean(x, keep_dimensions = TRUE, keep_metadata = TRUE)),
    ghe = list(
      backend = "xmart", source = "ghe",
      query = "PHL; 2023; sex=TOTAL; age=TOTAL; cause=0; measure=deaths",
      expected = list(id = "0", iso3 = "PHL", year = 2023L, dim_sex = "TOTAL",
                      dim_age = "TOTAL", series = "deaths"),
      fetch = function() ghe_data("PHL", year = 2023, sex = "TOTAL", age = "TOTAL",
                                  cause = 0, measure = "deaths"),
      clean = function(x) ghe_clean(x, keep_dimensions = TRUE)),
    sdg = list(
      backend = "un_sdg", source = "sdg",
      query = "3.2.1; PHL; 2020; series=SH_DYN_MORT; Sex=BOTHSEX",
      expected = list(id = "3.2.1", iso3 = "PHL", year = 2020L,
                      series = "SH_DYN_MORT", dim_sex = "BOTHSEX"),
      fetch = function() sdg_data("3.2.1", area = "PHL", year_from = 2020, year_to = 2020,
                                  series = "SH_DYN_MORT", dimensions = list(Sex = "BOTHSEX")),
      clean = function(x) sdg_clean(x, keep_dimensions = TRUE, keep_metadata = TRUE))
  )
}

assert_health <- function(condition, message) {
  if (!isTRUE(condition)) stop(message, call. = FALSE)
}

validate_health <- function(raw, clean, case) {
  assert_health(is.data.frame(raw) && nrow(raw) > 0L, "Query returned no observations.")
  assert_health(is.data.frame(clean) && nrow(clean) == nrow(raw),
                "Cleaning changed the observation count or returned an invalid object.")
  schema <- c(source = "character", id = "character", indicator = "character",
              location = "character", iso3 = "character", location_name = "character",
              year = "integer", value = "character", value_num = "double", low = "double",
              high = "double", series = "character", dim1 = "character",
              dim2 = "character", dim3 = "character")
  assert_health(identical(head(names(clean), length(schema)), names(schema)),
                "Cleaned output no longer begins with the 15-column schema.")
  assert_health(identical(vapply(clean[names(schema)], typeof, character(1)), schema),
                "Cleaned column types do not match the documented schema.")
  expected <- c(list(source = case$source), case$expected)
  for (column in names(expected)) {
    assert_health(column %in% names(clean), paste("Missing cleaned field:", column))
    values <- clean[[column]]
    wanted <- expected[[column]]
    matches <- if (all(is.na(wanted))) all(is.na(values)) else
      !anyNA(values) && all(values %in% wanted)
    assert_health(matches, paste("Unexpected selection in cleaned field:", column))
  }
  assert_health(any(is.finite(clean$value_num)), "No usable numeric observations after cleaning.")
  assert_health(all(is.na(clean$value_num) | (is.finite(clean$value_num) & clean$value_num >= 0)),
                "Unexpected negative or non-finite numeric observation.")
  if (case$source != "sdg") {
    provenance <- attr(raw, "who_provenance")
    assert_health(isTRUE(provenance$complete), "WHO download is not marked complete.")
    assert_health(identical(provenance$backend, case$backend), "Unexpected WHO provider.")
  }
  invisible(TRUE)
}

run_health_case <- function(case) {
  warnings <- messages <- character()
  error <- ""
  raw.rows <- clean.rows <- NA_integer_
  started <- proc.time()[["elapsed"]]
  tryCatch(withCallingHandlers({
    raw <- case$fetch()
    if (is.data.frame(raw)) raw.rows <- nrow(raw)
    assert_health(is.data.frame(raw) && nrow(raw) > 0L, "Query returned no observations.")
    clean <- case$clean(raw)
    if (is.data.frame(clean)) clean.rows <- nrow(clean)
    validate_health(raw, clean, case)
  }, warning = function(w) {
    warnings <<- c(warnings, conditionMessage(w))
    invokeRestart("muffleWarning")
  }, message = function(m) {
    messages <<- c(messages, conditionMessage(m))
    invokeRestart("muffleMessage")
  }), error = function(e) { error <<- conditionMessage(e) })
  list(status = if (!nzchar(error) && !length(warnings)) "PASS" else "FAIL",
       elapsed_seconds = round(proc.time()[["elapsed"]] - started, 2),
       raw_rows = raw.rows, clean_rows = clean.rows, warnings = warnings,
       error = error, messages = messages)
}

write_health_report <- function(results, output.dir) {
  utils::write.csv(results, file.path(output.dir, "results.csv"), row.names = FALSE, na = "")
  escape_cell <- function(x) {
    x[is.na(x)] <- ""
    x <- gsub("[\r\n]+", " ", x)
    x <- gsub("&", "&amp;", x, fixed = TRUE)
    x <- gsub("<", "&lt;", x, fixed = TRUE)
    gsub("|", "\\|", x, fixed = TRUE)
  }
  display <- results[c("check", "backend", "status", "raw_rows", "clean_rows", "elapsed_seconds")]
  rows <- apply(display, 1, function(x) paste0("| ", paste(escape_cell(x), collapse = " | "), " |"))
  details <- unlist(lapply(seq_len(nrow(results)), function(i) {
    c(paste0("- **", results$check[i], "**: ", results$query[i]),
      if (nzchar(results$warnings[i])) paste0("  - Warning: ", escape_cell(results$warnings[i])),
      if (nzchar(results$error[i])) paste0("  - Error: ", escape_cell(results$error[i])))
  }))
  lines <- c("# DSIR API health", "",
             paste("DSIR:", results$dsir_version[1], "| R:", results$r_version[1]),
             paste("Commit:", results$commit[1]),
             paste("Started (UTC):", results$started_utc[1]), "",
             "| Check | Backend | Status | Raw rows | Clean rows | Seconds |",
             "| --- | --- | --- | ---: | ---: | ---: |", rows, "", details, "",
             "Healthy requires all four checks to execute and pass. RUNNING or NOT_RUN is not a pass.",
             "Values and exact row counts are not pinned. A failed run requires investigation; it does not by itself identify the cause.")
  writeLines(lines, file.path(output.dir, "summary.md"))
}

run_api_health <- function(output.dir, cases = health_cases(), commit = "unknown") {
  expected.names <- c("gho_legacy", "gho_xmart", "ghe", "sdg")
  assert_health(identical(names(cases), expected.names), "All four named health checks are required.")
  dir.create(output.dir, recursive = TRUE, showWarnings = FALSE)
  results <- data.frame(
    check = names(cases), backend = vapply(cases, `[[`, character(1), "backend"),
    query = vapply(cases, `[[`, character(1), "query"),
    dsir_version = as.character(utils::packageVersion("DSIR")),
    r_version = as.character(getRversion()), commit = commit,
    started_utc = format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC"),
    status = "NOT_RUN", elapsed_seconds = NA_real_, raw_rows = NA_integer_,
    clean_rows = NA_integer_, warnings = "", error = "", stringsAsFactors = FALSE
  )
  write_health_report(results, output.dir)
  capture.output(utils::sessionInfo(), file = file.path(output.dir, "session-info.txt"))
  for (i in seq_along(cases)) {
    message("Checking ", names(cases)[i], " ...")
    results$status[i] <- "RUNNING"
    write_health_report(results, output.dir)
    result <- run_health_case(cases[[i]])
    for (column in c("status", "elapsed_seconds", "raw_rows", "clean_rows", "error")) {
      results[[column]][i] <- result[[column]]
    }
    results$warnings[i] <- paste(result$warnings, collapse = " | ")
    writeLines(c(result$messages, paste("Status:", result$status),
                 paste("Warning:", result$warnings), paste("Error:", result$error)),
               file.path(output.dir, paste0(names(cases)[i], ".log")))
    write_health_report(results, output.dir)
    message(names(cases)[i], ": ", result$status)
  }
  results
}

health_exit_status <- function(results) {
  if (nrow(results) == 4L && all(results$status == "PASS")) 0L else 1L
}

if (sys.nframe() == 0L) {
  assert_health(identical(Sys.getenv("DSIR_RUN_LIVE_TESTS"), "true"),
                "Set DSIR_RUN_LIVE_TESTS=true to run these live API checks.")
  options(DSIR.who_backend = NULL, DSIR.who_base_url = NULL, DSIR.who_max_rows = 10000,
          cli.num_colors = 1)
  output.dir <- Sys.getenv("DSIR_HEALTH_OUTPUT", file.path(tempdir(), "dsir-api-health"))
  commit <- Sys.getenv("GITHUB_SHA", "unknown")
  results <- run_api_health(output.dir, commit = commit)
  print(results[c("check", "status", "raw_rows", "clean_rows", "elapsed_seconds")], row.names = FALSE)
  message("Reports: ", normalizePath(output.dir, winslash = "/"))
  quit(save = "no", status = health_exit_status(results))
}
