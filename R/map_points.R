# Point records use the centre fields of the same WHO feature layer.
.dsi_map_valid_centre <- function(row) {
  if (!is.list(row)) return(FALSE)
  fields <- c("OBJECTID", "CENTER_LON", "CENTER_LAT")
  numeric.scalar <- function(x) is.numeric(x) && length(x) == 1L && is.finite(x)
  if (!all(vapply(row[fields], numeric.scalar, logical(1)))) return(FALSE)
  row$OBJECTID >= 0 && row$OBJECTID == trunc(row$OBJECTID) &&
    abs(row$CENTER_LON) <= 180 && abs(row$CENTER_LAT) <= 90
}

.dsi_map_read_centre <- function(file, code, source) {
  if (!file.exists(file)) return(NULL)
  tryCatch({
    record <- readRDS(file)
    if (!is.list(record) || !identical(record$schema_version, 1L) ||
        !identical(record$item_id, source$item_id) || !identical(record$endpoint, source$endpoint) ||
        !identical(record$layer_id, source$layer_id) ||
        !.dsi_map_valid_centre(record$row) || !identical(record$row$ISO_3_CODE, code) ||
        !is.character(record$retrieved_at) || length(record$retrieved_at) != 1L ||
        is.na(record$retrieved_at) || !grepl("^[0-9]{4}-[0-9]{2}-[0-9]{2}T.*Z$", record$retrieved_at) ||
        !is.character(record$query_url) || length(record$query_url) != 1L ||
        is.na(record$query_url) || !startsWith(record$query_url, paste0(source$endpoint, "/query?")) ||
        !is.character(record$item_modified_at) || length(record$item_modified_at) != 1L ||
        !is.character(record$license) || length(record$license) != 1L) {
      stop("Unrecognized or incomplete centre coordinate cache.")
    }
    record$cache_hit <- TRUE
    record
  }, error = function(e) {
    msg <- conditionMessage(e)
    cli::cli_warn(c("Ignoring an invalid WHO centre coordinate cache for {.val {code}}.", "x" = "{msg}"),
      class = "dsir_map_cache_warning")
    NULL
  })
}

.dsi_map_fetch_centres <- function(codes, source, item) {
  where <- paste0("ISO_3_CODE IN (", paste0("'", codes, "'", collapse = ","), ")")
  request <- .dsi_request(paste0(source$endpoint, "/query")) %>%
    httr2::req_url_query(where = where, f = "json", returnGeometry = "false",
      outFields = "OBJECTID,ISO_3_CODE,CENTER_LON,CENTER_LAT")
  body <- .dsi_map_json(request)
  if (is.null(body) || !is.list(body$features) || isTRUE(body$exceededTransferLimit)) {
    cli::cli_abort("No complete WHO ADM0 centre coordinate response was returned.")
  }
  rows <- lapply(body$features, function(feature) if (is.list(feature)) feature$attributes)
  returned <- vapply(rows, function(row) {
    code <- if (is.list(row)) row$ISO_3_CODE
    if (is.character(code) && length(code) == 1L) code else NA_character_
  }, character(1))
  if (anyNA(returned) || anyDuplicated(returned) || any(!returned %in% codes)) {
    cli::cli_abort("WHO ADM0 returned ambiguous or unexpected centre coordinate keys.")
  }
  missing <- setdiff(codes, returned)
  if (length(missing)) cli::cli_abort("WHO ADM0 centre coordinates are missing for {.val {missing}}.")
  valid <- vapply(rows, .dsi_map_valid_centre, logical(1))
  if (!all(valid)) cli::cli_abort("WHO ADM0 centre coordinates or feature identifiers are invalid for {.val {returned[!valid]}}.")
  retrieved.at <- .dsi_timestamp()
  lapply(rows[match(codes, returned)], function(row) {
    list(schema_version = 1L, item_id = source$item_id, endpoint = source$endpoint,
      layer_id = source$layer_id, row = row, retrieved_at = retrieved.at,
      item_modified_at = item$item_modified_at, license = item$license,
      query_url = request$url, cache_hit = FALSE)
  })
}

.dsi_map_who_centres <- function(codes, download, cache_dir, refresh) {
  cache_dir <- .dsi_map_cache_dir(cache_dir)
  source <- .dsi_map_source()
  files <- file.path(cache_dir, paste0("who-adm0-centres-", source$item_id, "-v1"), paste0(codes, ".rds"))
  records <- lapply(seq_along(codes), function(i) {
    if (refresh) NULL else .dsi_map_read_centre(files[[i]], codes[[i]], source)
  })
  missing <- which(vapply(records, is.null, logical(1)))
  if (length(missing)) {
    .dsi_map_permission(download, codes[missing], type = "point")
    item <- .dsi_map_item(source)
    # Keep request URLs short. Validate every response before refreshing any cache.
    batches <- split(missing, (seq_along(missing) - 1L) %/% 80L)
    for (indices in batches) records[indices] <- .dsi_map_fetch_centres(codes[indices], source, item)
  }
  object.ids <- vapply(records, function(record) record$row$OBJECTID, numeric(1))
  if (anyDuplicated(object.ids)) cli::cli_abort("WHO ADM0 returned duplicate centre coordinate feature identifiers.")
  for (i in missing) .dsi_map_write_cache(records[[i]], files[[i]])
  sources <- do.call(vctrs::vec_rbind, lapply(records, function(record) {
    row <- record$row
    tibble::tibble(iso3 = row$ISO_3_CODE, object_id = row$OBJECTID,
      longitude = row$CENTER_LON, latitude = row$CENTER_LAT,
      item_id = record$item_id, layer_id = record$layer_id, endpoint = record$endpoint,
      retrieved_at = record$retrieved_at, item_modified_at = record$item_modified_at,
      cache_hit = record$cache_hit, license = record$license, query_url = record$query_url)
  }))
  points <- sf::st_as_sf(sources[c("iso3", "longitude", "latitude")],
    coords = c("longitude", "latitude"), crs = 4326)
  # The Western Pacific display spans 88 to 219 degrees east and 48 S to 53 N.
  # Test the display extent without changing the original signed longitude.
  longitude <- sources$longitude %% 360
  outside <- codes %in% DSIR::wpro_cty & (longitude < 88 | longitude > 219 |
    sources$latitude < -48 | sources$latitude > 53)
  dates <- sort(unique(substr(sources$retrieved_at, 1L, 10L)))
  note <- paste0("WHO ADM0 centre-coordinate snapshot dates (UTC): ",
    paste(dates, collapse = ", "), ". Latest WHO GIS release status unverified.")
  list(data = points, metadata = list(origin = "who_gis", key = "ISO_3_CODE",
    type = "point", countries = codes, crs = sf::st_crs(points)$wkt, sources = sources,
    snapshot_dates = dates, note = note,
    outliers = sources[outside, c("iso3", "longitude", "latitude")]))
}

.dsi_map_draw_points <- function(data, keys, value, country, unit, crs, outliers) {
  flagged <- keys %in% outliers
  pacific <- all(keys %in% DSIR::wpro_cty)
  display <- crs %||% if (pacific) "+proj=eqearth +lon_0=150 +datum=WGS84" else 4326
  use.inset <- pacific && is.null(crs) && any(flagged) && any(!flagged)
  mapped <- data[[value]]
  limits <- if (any(!is.na(mapped))) range(mapped, na.rm = TRUE)
  colour <- ggplot2::scale_fill_viridis_c(end = 0.9, na.value = "grey85", name = unit, limits = limits)
  point <- function(rows) {
    ggplot2::geom_sf(data = rows, shape = 21, colour = "#24465A", stroke = 0.45, size = 3)
  }
  label <- function(rows) {
    ggplot2::geom_sf_text(ggplot2::aes(label = .data[[country]]), data = rows,
      size = 2.5, colour = "#24465A", hjust = -0.18, vjust = -1.45,
      show.legend = FALSE, fun.geometry = identity)
  }
  p <- ggplot2::ggplot(data, ggplot2::aes(fill = .data[[value]]))
  if (!use.inset) {
    return(p + point(data) + label(data) + colour +
      ggplot2::coord_sf(crs = display, datum = sf::st_crs(4326), expand = TRUE))
  }
  main <- data[!flagged, , drop = FALSE]
  other <- data[flagged, , drop = FALSE]
  centre <- sf::st_coordinates(other)
  locator.note <- if (nrow(other) == 1L) {
    sprintf("Reported lon %.2f, lat %.2f", centre[1L, "X"], centre[1L, "Y"])
  } else "Reported centre coordinates"
  locator <- ggplot2::ggplot(other, ggplot2::aes(fill = .data[[value]])) +
    point(other) + label(other) + colour +
    ggplot2::coord_sf(crs = "+proj=eqearth +datum=WGS84",
      xlim = c(-17700000, 17700000), ylim = c(-9000000, 9000000), expand = FALSE) +
    ggplot2::labs(title = "Outside the main view", subtitle = locator.note, x = NULL, y = NULL) +
    ggplot2::theme_minimal(base_size = 8) +
    ggplot2::theme(axis.text = ggplot2::element_blank(), legend.position = "none",
      plot.background = ggplot2::element_rect(fill = "#F3F8FA", colour = "#C1D6E1"),
      plot.margin = ggplot2::margin(6, 6, 6, 6))
  # Lay out the inset without opening a default output file.
  if (grDevices::dev.cur() == 1L) {
    grDevices::pdf(NULL)
    device <- grDevices::dev.cur()
    on.exit(grDevices::dev.off(device), add = TRUE)
  }
  # Reserve space to the right of all main-view points for the world locator.
  p + point(main) + label(main) + colour +
    ggplot2::coord_sf(crs = display, xlim = c(-6600000, 12400000), ylim = c(-6500000, 7400000),
      datum = sf::st_crs(4326), expand = FALSE) +
    ggplot2::annotation_custom(ggplot2::ggplotGrob(locator),
      xmin = 7000000, xmax = 12000000, ymin = 2400000, ymax = 6600000)
}
