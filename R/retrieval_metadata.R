# Acquisition records describe the original request, not later user edits.
.dsi_timestamp <- function() format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC")

.dsi_timestamp_utc <- function(x) {
  if (is.null(x) || !length(x) || is.na(x[[1]])) return(NA_character_)
  if (inherits(x, "POSIXt")) return(format(x[[1]], "%Y-%m-%dT%H:%M:%SZ", tz = "UTC"))
  pattern <- if (grepl("T", x[[1]], fixed = TRUE)) "%Y-%m-%dT%H:%M:%SZ" else "%Y-%m-%d %H:%M:%S"
  time <- as.POSIXct(strptime(x[[1]], pattern, tz = "UTC"))
  format(time, "%Y-%m-%dT%H:%M:%SZ", tz = "UTC")
}

.dsi_record_count <- function(x) {
  if (is.data.frame(x)) nrow(x) else length(x)
}

.dsi_record <- function(data, source, backend, endpoint, kind = "response",
                        query = list(), retrieved_at = NA_character_,
                        status = if (.dsi_record_count(data)) "success" else "empty",
                        complete = NA, record_count = .dsi_record_count(data),
                        retrieval_status = "live", api_version = NA_character_,
                        source_release = NA_character_) {
  if (is.null(data)) return(NULL)
  attr(data, "dsir_metadata") <- list(
    schema_version = 1L, layout = "retrieval", source = source, kind = kind,
    sources = tibble::tibble(
      component = kind, backend = backend, endpoint = endpoint,
      retrieved_at = .dsi_timestamp_utc(retrieved_at), retrieval_status = retrieval_status,
      record_count = as.numeric(record_count), api_version = api_version,
      source_release = source_release, cache_hit = FALSE,
      status = status, complete = complete, query = list(query)
    ),
    query = query,
    result = list(status = status, complete = complete, rows = .dsi_record_count(data))
  )
  data
}

.dsi_copy_metadata <- function(data, origin) {
  if (is.null(data)) return(NULL)
  for (name in c("dsir_metadata", "who_provenance", "catalog_snapshot")) {
    attr(data, name) <- attr(origin, name, exact = TRUE)
  }
  data
}

# Adapt public outputs without changing their classes, columns or failure shapes.
.dsi_result <- function(data, source, kind, query = list(), origin = data,
                        backend = NA_character_, endpoint = NA_character_,
                        status = NULL, sources = NULL) {
  if (is.null(data)) return(NULL)
  metadata <- attr(origin, "dsir_metadata", exact = TRUE)
  if (is.null(metadata) || !identical(metadata$layout, "retrieval")) {
    legacy <- attr(origin, "who_provenance", exact = TRUE)
    if (!is.null(legacy$backend)) backend <- legacy$backend
    if (!is.null(legacy$query_url)) endpoint <- sub("[?].*$", "", legacy$query_url)
    if (!is.null(legacy$table)) endpoint <- paste0(legacy$base_url, "/", legacy$table)
    recorded <- isTRUE(legacy$complete)
    unverified <- !recorded && .dsi_record_count(data) > 0L
    seed <- .dsi_record(data, source, backend, endpoint, kind,
      retrieved_at = legacy$retrieved,
      status = if (recorded) if (.dsi_record_count(data)) "success" else "empty" else if (unverified) "unverified" else "failed",
      complete = if (unverified) NA else recorded,
      record_count = if (recorded) legacy$rows %||% .dsi_record_count(origin) else NA_real_,
      retrieval_status = if (recorded) "live" else if (unverified) "unknown" else "not_retrieved")
    metadata <- attr(seed, "dsir_metadata", exact = TRUE)
  }
  if (!is.null(sources)) {
    metadata$sources <- sources
    metadata$result$complete <- all(sources$complete)
    if (is.null(status) && any(sources$status %in% c("failed", "invalid", "incomplete"))) {
      status <- if (.dsi_record_count(data)) "partial" else "failed"
    }
  }
  metadata$source <- source
  metadata$kind <- kind
  metadata$query <- query
  if (is.null(status)) {
    status <- metadata$result$status
    if (status %in% c("success", "empty")) {
      status <- if (.dsi_record_count(data)) "success" else "empty"
    }
  }
  metadata$result$status <- status
  if (status %in% c("failed", "invalid", "incomplete", "partial")) metadata$result$complete <- FALSE
  metadata$result$rows <- .dsi_record_count(data)
  attr(data, "dsir_metadata") <- metadata
  data
}

.dsi_cached_metadata <- function(data) {
  metadata <- attr(data, "dsir_metadata", exact = TRUE)
  if (!is.null(metadata$sources)) {
    metadata$sources$cache_hit <- TRUE
    attr(data, "dsir_metadata") <- metadata
  }
  data
}

.dsi_source_rows <- function(origins) {
  rows <- lapply(origins, function(x) attr(x, "dsir_metadata", exact = TRUE)$sources)
  rows <- Filter(Negate(is.null), rows)
  if (!length(rows)) return(NULL)
  unique(do.call(vctrs::vec_rbind, rows))
}

.dsi_sdg_releases <- function(x) {
  if (!is.list(x)) return(character())
  keys <- names(x)
  if (is.null(keys)) keys <- rep("", length(x))
  found <- as.character(unlist(x[keys %in% "release"], use.names = FALSE))
  nested <- x[!keys %in% "release"]
  found <- c(found, unlist(lapply(nested, .dsi_sdg_releases), use.names = FALSE))
  sort(unique(found[!is.na(found) & nzchar(found)]))
}
