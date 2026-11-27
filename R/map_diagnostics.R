.dsi_map_validation <- function(boundaries, keys, source) {
  spherical <- isTRUE(sf::st_is_longlat(boundaries)) && sf::sf_use_s2()
  engine <- if (spherical) "S2" else "GEOS"
  version <- if (spherical) as.character(utils::packageVersion("s2")) else unname(sf::sf_extSoftVersion()[["GEOS"]])
  reason <- vapply(seq_along(keys), function(i) {
    tryCatch({
      result <- sf::st_is_valid(boundaries[i, , drop = FALSE], reason = TRUE)
      if (length(result) != 1L || is.na(result)) "Validation returned NA; validity could not be established." else result
    }, error = function(e) paste("Validation exception:", conditionMessage(e)))
  }, character(1))
  list(schema_version = 1L, checked_at = .dsi_timestamp(), engine = engine,
    engine_version = version, sf_version = as.character(utils::packageVersion("sf")),
    crs = sf::st_crs(boundaries)$wkt, source = source,
    checks = tibble::tibble(key = keys, valid = reason == "Valid Geometry", reason = reason))
}

.dsi_map_boundary_abort <- function(message, diagnostics) {
  checks <- diagnostics$checks
  failed <- is.na(checks$valid) | !checks$valid
  engine <- paste(c(diagnostics$engine, diagnostics$engine_version[!is.na(diagnostics$engine_version)]),
    collapse = " ")
  details <- paste0(checks$key[failed], " [", engine, "]: ", checks$reason[failed])
  cli::cli_abort(c("{message}", "x" = "{paste(details, collapse = '\n')}"),
    class = "dsir_map_boundary_error", diagnostics = diagnostics)
}

.dsi_map_structure_abort <- function(message, keys, reason, source, issue = NULL, engine = "sf") {
  version <- switch(engine, sf = as.character(utils::packageVersion("sf")),
    GDAL = unname(sf::sf_extSoftVersion()[["GDAL"]]), NA_character_)
  .dsi_map_boundary_abort(message, list(schema_version = 1L,
    checked_at = .dsi_timestamp(), engine = engine, engine_version = version, issue = issue,
    source = source, checks = tibble::tibble(key = keys, valid = FALSE, reason = reason)))
}
