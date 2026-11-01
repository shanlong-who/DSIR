# WHO boundaries stay outside the package and are cached only after validation.
.dsi_map_source <- function() {
  id <- "39663258d2b44dcaa28af952ed40760b"
  list(item_id = id, layer_id = 0L,
    item_url = paste0("https://www.arcgis.com/sharing/rest/content/items/", id),
    endpoint = paste0("https://services.arcgis.com/5T5nSi527N4F7luB/ArcGIS/rest/services/",
                       "Detailed_Boundary_ADM0/FeatureServer/0"))
}

.dsi_map_interactive <- function() interactive()
.dsi_map_confirm <- function(message) utils::askYesNo(message, default = FALSE)

.dsi_map_permission <- function(download, codes) {
  if (download == "allow") return(invisible(TRUE))
  if (download == "ask" && .dsi_map_interactive()) {
    shown <- paste(utils::head(codes, 6L), collapse = ", ")
    message <- paste0("Download unmodified WHO ADM0 boundaries for ", length(codes),
      " area(s) (", shown, if (length(codes) > 6L) ", ..." else "", ") and cache them?\n",
      "Source: WHO GIS, Detailed_Boundary_ADM0. Detailed polygons can be large.\n",
      "Terms: https://data.who.int/about/data/terms-and-conditions")
    if (isTRUE(.dsi_map_confirm(message))) return(invisible(TRUE))
  }
  cli::cli_abort(c("WHO boundary download was not permitted; no network request was made.",
    "i" = 'Use {.code download = "allow"} explicitly in scripts/Quarto, or supply {.arg boundaries} or a complete cache.'))
}

.dsi_map_json <- function(request) {
  tryCatch({
    response <- httr2::req_perform(request)
    body <- httr2::resp_body_json(response, simplifyVector = FALSE)
    if (!is.list(body)) stop("Unexpected JSON structure.")
    if (!is.null(body$error)) {
      msg <- paste("ArcGIS", body$error$code, body$error$message)
      stop(msg, call. = FALSE)
    }
    body
  }, error = function(e) {
    msg <- conditionMessage(e)
    cli::cli_warn(c("WHO boundary request failed.", "x" = "{msg}"))
    NULL
  })
}

.dsi_map_item <- function(source) {
  request <- .dsi_request(source$item_url) %>% httr2::req_url_query(f = "json")
  item <- .dsi_map_json(request)
  if (is.null(item)) cli::cli_abort("No WHO boundary item metadata was returned.")
  if (!identical(item$id, source$item_id) || !identical(item$access, "public")) {
    cli::cli_abort("The expected WHO boundary item is not publicly available.")
  }
  modified <- item$modified
  modified.at <- if (is.numeric(modified) && length(modified) == 1L && is.finite(modified)) {
    format(as.POSIXct(modified / 1000, origin = "1970-01-01", tz = "UTC"), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC")
  } else NA_character_
  list(item_modified_at = modified.at, license = item$licenseInfo %||% NA_character_)
}

.dsi_map_fetch_country <- function(code, source, item) {
  query.url <- paste0(source$endpoint, "/query")
  where <- paste0("ISO_3_CODE = '", code, "'")
  ids <- .dsi_map_json(.dsi_request(query.url) %>%
    httr2::req_url_query(where = where, returnIdsOnly = "true", f = "json"))
  if (is.null(ids)) cli::cli_abort("Could not verify WHO boundary identifiers for {.val {code}}.")
  object.ids <- unlist(ids$objectIds, use.names = FALSE)
  if (length(object.ids) != 1L || !is.numeric(object.ids) || !is.finite(object.ids) ||
      object.ids < 0 || object.ids != trunc(object.ids) || !is.character(ids$objectIdFieldName) ||
      length(ids$objectIdFieldName) != 1L || is.na(ids$objectIdFieldName) || !nzchar(ids$objectIdFieldName)) {
    cli::cli_abort("Expected exactly one WHO ADM0 feature for {.val {code}}; the identifier response was missing or ambiguous.")
  }
  file <- tempfile("dsir-boundary-", fileext = ".geojson")
  on.exit(unlink(file), add = TRUE)
  request <- .dsi_request(query.url) %>%
    httr2::req_url_query(where = where, objectIds = format(object.ids, scientific = FALSE),
      outFields = "*", returnGeometry = "true", outSR = 4326, f = "geojson") %>%
    httr2::req_timeout(120)
  # Stream large coordinates to disk instead of expanding them into R lists.
  data <- tryCatch({
    httr2::req_perform(request, path = file)
    sf::st_read(file, quiet = TRUE, stringsAsFactors = FALSE)
  }, error = function(e) {
    msg <- conditionMessage(e)
    cli::cli_warn(c("WHO geometry download failed for {.val {code}}.", "x" = "{msg}"))
    NULL
  })
  if (is.null(data)) cli::cli_abort("No usable WHO boundary download for {.val {code}}.")
  if (!inherits(data, "sf")) cli::cli_abort("Empty geometry in the WHO boundary response for {.val {code}}.")
  if (nrow(data) != 1L || !ids$objectIdFieldName %in% names(data) ||
      !isTRUE(as.character(data[[ids$objectIdFieldName]]) == as.character(object.ids))) {
    cli::cli_abort("WHO boundary feature identifiers changed or the response was incomplete for {.val {code}}.")
  }
  data <- .dsi_map_select_boundaries(data, "ISO_3_CODE", code)
  if (!isTRUE(sf::st_crs(data) == sf::st_crs(4326))) cli::cli_abort("Unexpected coordinate system in the WHO boundary response.")
  list(schema_version = 1L, item_id = source$item_id, endpoint = source$endpoint,
    layer_id = source$layer_id, code = code, id_field = ids$objectIdFieldName,
    object_id = object.ids, data = data, retrieved_at = .dsi_timestamp(),
    item_modified_at = item$item_modified_at, license = item$license,
    download_md5 = unname(tools::md5sum(file)), query = list(where = where,
      object_ids = object.ids, out_sr = 4326L), cache_hit = FALSE)
}

.dsi_map_read_cache <- function(file, code, source) {
  if (!file.exists(file)) return(NULL)
  tryCatch({
    record <- readRDS(file)
    required <- c("schema_version", "item_id", "endpoint", "layer_id", "code", "id_field",
      "object_id", "data", "retrieved_at", "item_modified_at", "license", "download_md5", "query", "cache_hit")
    if (!is.list(record) || !all(required %in% names(record)) || !identical(record$schema_version, 1L) ||
        !identical(record$item_id, source$item_id) || !identical(record$endpoint, source$endpoint) ||
        !identical(record$code, code) || !identical(record$layer_id, source$layer_id) ||
        !is.character(record$retrieved_at) || length(record$retrieved_at) != 1L ||
        is.na(record$retrieved_at) || !nzchar(record$retrieved_at) ||
        !is.character(record$download_md5) || length(record$download_md5) != 1L ||
        is.na(record$download_md5) || !grepl("^[a-f0-9]{32}$", record$download_md5) ||
        !is.list(record$query) || !is.character(record$license) || length(record$license) != 1L ||
        !is.character(record$item_modified_at) || length(record$item_modified_at) != 1L ||
        !inherits(record$data, "sf") || nrow(record$data) != 1L ||
        !is.character(record$id_field) || length(record$id_field) != 1L ||
        !record$id_field %in% names(record$data) ||
        !isTRUE(as.character(record$data[[record$id_field]]) == as.character(record$object_id))) {
      stop("Unrecognized or incomplete cache record.")
    }
    .dsi_map_select_boundaries(record$data, "ISO_3_CODE", code)
    if (!isTRUE(sf::st_crs(record$data) == sf::st_crs(4326))) stop("Unexpected cache coordinate system.")
    record$cache_hit <- TRUE
    record
  }, error = function(e) {
    msg <- conditionMessage(e)
    cli::cli_warn(c("Ignoring an invalid WHO boundary cache for {.val {code}}.", "x" = "{msg}"))
    NULL
  })
}

.dsi_map_write_cache <- function(record, file) {
  tryCatch({
    dir.create(dirname(file), recursive = TRUE, showWarnings = FALSE)
    temporary <- tempfile("dsir-cache-", tmpdir = dirname(file), fileext = ".rds")
    on.exit(unlink(temporary), add = TRUE)
    saveRDS(record, temporary)
    if (!file.rename(temporary, file)) stop("Could not replace the cache file; the previous cache was retained.")
  }, error = function(e) {
    msg <- conditionMessage(e)
    cli::cli_warn(c("Map boundaries were downloaded but could not be cached.", "x" = "{msg}"))
  })
  invisible(NULL)
}

.dsi_map_who_boundaries <- function(codes, download, cache_dir, refresh) {
  if (is.null(cache_dir)) cache_dir <- file.path(tools::R_user_dir("DSIR", "cache"), "maps")
  if (!is.character(cache_dir) || length(cache_dir) != 1L || is.na(cache_dir) || !nzchar(cache_dir)) {
    cli::cli_abort("{.arg cache_dir} must be a single directory path.")
  }
  source <- .dsi_map_source()
  files <- file.path(cache_dir, paste0("who-adm0-", source$item_id, "-v1"), paste0(codes, ".rds"))
  records <- lapply(seq_along(codes), function(i) {
    if (refresh) NULL else .dsi_map_read_cache(files[[i]], codes[[i]], source)
  })
  missing <- which(vapply(records, is.null, logical(1)))
  if (length(missing)) {
    .dsi_map_permission(download, codes[missing])
    item <- .dsi_map_item(source)
    for (i in missing) {
      cli::cli_inform("Downloading WHO ADM0 boundary for {.val {codes[[i]]}}.")
      records[[i]] <- .dsi_map_fetch_country(codes[[i]], source, item)
      .dsi_map_write_cache(records[[i]], files[[i]])
    }
  }
  data <- do.call(rbind, lapply(records, `[[`, "data"))
  sources <- do.call(vctrs::vec_rbind, lapply(records, function(record) {
    tibble::tibble(iso3 = record$code, item_id = record$item_id, layer_id = record$layer_id,
      endpoint = record$endpoint, retrieved_at = record$retrieved_at,
      item_modified_at = record$item_modified_at, download_md5 = record$download_md5,
      cache_hit = record$cache_hit, license = record$license, query = list(record$query))
  }))
  list(data = data, metadata = list(origin = "who_gis", key = "ISO_3_CODE",
    countries = codes, crs = sf::st_crs(data)$wkt, sources = sources))
}
