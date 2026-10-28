#' Save GHO Observations as an Auditable Data Snapshot
#'
#' Wraps an already retrieved GHO data frame with its identity, query context
#' and creation time. It makes no network requests and never fills, rounds,
#' aggregates or otherwise changes observations.
#'
#' @param data A data frame returned by [gho_data()], or by
#'   `gho_clean(..., keep_dimensions = TRUE, keep_metadata = TRUE)`.
#'   The default 15-column cleaned output has insufficient identity context.
#'   The first schema supports one GHO indicator and one backend per snapshot.
#' @param file Optional local RDS path. Parent directories are created as
#'   needed. With `NULL`, return an in-memory snapshot without writing a file.
#' @param source Optional source identifier. Currently only `"gho"` is
#'   supported. Recorded source information must agree with this argument.
#' @param indicator Optional indicator code, normally read from the data.
#'   Supply it for an explicitly declared, empty selection.
#' @param backend Optional `"legacy"` or `"xmart"`, normally read from
#'   `Provider` / `provider` or `who_provenance`. Session options are never
#'   used to guess an imported data frame's origin.
#' @param scope Optional, non-empty named list describing the complete query
#'   and any local filtering, for example
#'   `list(area = "PHL", year_from = 2020, year_to = NULL)`. Names and sets of
#'   values are canonicalized for comparison. With `NULL`, use the recorded
#'   request URL or xMart table/filter from a complete DSIR retrieval whose
#'   recorded row count still matches `data`. After local subsetting, supply
#'   an explicit scope; do not infer query limits from observed coverage.
#' @param key Optional additional semantic identity columns. Required GHO
#'   identity and dimension columns are always included. This argument can
#'   resolve a genuinely additional dimension, not hide duplicate observations.
#' @param value_fields Optional fields classified as values. Defaults to
#'   numeric value, bounds and the original display value, when present.
#'   The primary numeric field is always required.
#' @param overwrite Logical. Replace an existing file? Default `FALSE`.
#'
#' @details
#' The result is an ordinary R list, classed `dsir_data_snapshot`, with
#' `schema_version = 1L`, `created_at` (UTC POSIXct), `source`, `backend`,
#' `indicator`, `layout`, `origin`, `scope`, `provenance`, `retrieved_at`,
#' `source_timestamp_fields`, `key`, `value_fields`, `primary_value`,
#' `context_fields` and the complete, unmodified `data` frame. Read a saved
#' snapshot with [readRDS()]. This is distinct from [snapshot()], which caches
#' an expression and returns its value without this comparison contract.
#'
#' Default identity includes indicator, geographical type/code, temporal
#' type/value, all positional dimension type/code pairs and every named
#' `DIM_*` (or cleaned `dim_*`) column. Available detailed time coordinates,
#' unit and measure family also participate. A legacy data-source dimension
#' is identity; xMart's free-text source provenance is metadata. Row numbers,
#' service record IDs and modification timestamps are not matching keys.
#' Duplicate keys, untyped active dimensions and missing core identifiers
#' are errors. An inactive dimension may have both type and code missing.
#'
#' Four different times must remain separate:
#' * Source modification time: a provider-reported field, if supplied.
#'   `Date` / `updated` is preserved verbatim. Its presence does not establish
#'   an authoritative observation revision time; xMart system commits can
#'   reflect processing.
#' * Retrieval time: the original DSIR `who_provenance$retrieved` string
#'   (recorded in UTC by the clients), or `NA` when unavailable.
#' * Snapshot creation time: when this wrapper was made, explicitly UTC.
#' * Latest observation year: a property of the data, never an update time.
#'
#' Only information present in the supplied frame and declared arguments is
#' recorded. No credentials, environment variables, session options or HTTP
#' request objects are collected. Credential-like field names, authenticated
#' URLs and unsupported objects are rejected. Callers remain responsible for
#' checking their own free-text observations and metadata before saving.
#'
#' A declared scope is an auditable caller assertion, not proof of completeness.
#' Local edits that preserve the original row count cannot be detected from
#' provenance alone. Always declare a new scope after changing selection.
#' Snapshots record what DSIR returned; fields already discarded upstream or
#' by a cleaner cannot be recovered. No content hash is used: comparison
#' operates on keys and values rather than R serialization bytes.
#'
#' @return The snapshot, invisibly when written to `file` and visibly otherwise.
#' @seealso [compare_snapshots()], [snapshot()], [gho_data()],
#'   [gho_last_updated()].
#' @export
#'
#' @examples
#' x <- data.frame(
#'   IndicatorCode = "EXAMPLE", SpatialDimType = "COUNTRY",
#'   SpatialDim = "PHL", TimeDimType = "YEAR", TimeDim = 2020L,
#'   Dim1Type = "SEX", Dim1 = "SEX_BTSX",
#'   Dim2Type = NA_character_, Dim2 = NA_character_,
#'   Dim3Type = NA_character_, Dim3 = NA_character_, NumericValue = 10
#' )
#' old <- data_snapshot(x, backend = "legacy",
#'                      scope = list(area = "PHL", year_from = 2020))
#' x$NumericValue <- 12
#' new <- data_snapshot(x, backend = "legacy",
#'                      scope = list(area = "PHL", year_from = 2020))
#' compare_snapshots(old, new)$modified
#'
#' \dontrun{
#' old_data <- gho_data("WHS4_100")
#' data_snapshot(old_data, file = "snapshots/gho_old.rds")
#'
#' # Later, repeat exactly the same query using the same backend.
#' new_data <- gho_data("WHS4_100")
#' data_snapshot(new_data, file = "snapshots/gho_new.rds")
#' result <- compare_snapshots("snapshots/gho_old.rds",
#'                             "snapshots/gho_new.rds")
#' result$summary
#' result$modified
#' }
data_snapshot <- function(data, file = NULL, source = NULL, indicator = NULL,
                          backend = NULL, scope = NULL, key = NULL,
                          value_fields = NULL, overwrite = FALSE) {
  .dsi_check_flag(overwrite, "overwrite")
  if (!is.null(file)) {
    .dsi_snapshot_scalar(file, "file")
    if (dir.exists(file)) cli::cli_abort("{.arg file} is a directory.")
    if (file.exists(file) && !overwrite) {
      cli::cli_abort("Snapshot file already exists; choose another path or set {.code overwrite = TRUE}.")
    }
  }
  .dsi_snapshot_frame(data)
  layout <- .dsi_snapshot_layout(data)
  provenance <- attr(data, "who_provenance", exact = TRUE)
  if (is.null(provenance)) provenance <- list()
  if (!is.list(provenance) || is.data.frame(provenance)) {
    cli::cli_abort("The recorded {.code who_provenance} must be a list.")
  }
  if (!is.null(provenance$retrieved) &&
      (!is.character(provenance$retrieved) || length(provenance$retrieved) != 1L)) {
    cli::cli_abort("Recorded retrieval time must be a single character string or missing.")
  }
  for (field in intersect(c("base_url", "table", "query_url", "filter"), names(provenance))) {
    .dsi_snapshot_scalar(provenance[[field]], field)
  }
  source_values <- if ("source" %in% names(data)) data$source else character()
  source <- .dsi_snapshot_identity(source, source_values, "source", "gho")
  if (source != "gho") cli::cli_abort("Data snapshots currently support GHO only.")
  provider <- intersect(c("Provider", "provider"), names(data))
  if (length(provider) && is.null(backend) &&
      any(vapply(data[provider], function(x) any(is.na(x) | !nzchar(trimws(as.character(x)))), logical(1)))) {
    cli::cli_abort("Missing recorded backend codes; supply an explicit {.arg backend} only if all rows have that origin.")
  }
  backend_values <- c(unlist(data[provider], use.names = FALSE), provenance$backend)
  backend <- .dsi_snapshot_identity(backend, backend_values, "backend")
  if (!backend %in% c("legacy", "xmart")) {
    cli::cli_abort("{.arg backend} must be the recorded legacy or xmart origin.")
  }
  code_field <- if (layout == "gho_raw") "IndicatorCode" else "id"
  indicator <- .dsi_snapshot_identity(indicator, data[[code_field]], "indicator")
  definition <- .dsi_snapshot_definition(data, layout, backend, key, value_fields)
  .dsi_snapshot_check_keys(data, definition$key, layout, backend)
  if (!is.null(provenance$complete) && !isTRUE(provenance$complete)) {
    cli::cli_abort("The retrieval is marked incomplete; do not snapshot a failed download.")
  }
  if (is.null(scope)) {
    if (!isTRUE(provenance$complete) || !identical(as.numeric(provenance$rows), as.numeric(nrow(data)))) {
      cli::cli_abort(c("Query scope cannot be verified from this data frame.",
        "i" = "Supply {.arg scope} with the full query and local filters. A recorded row count must match the supplied frame."))
    }
    query <- if (backend == "legacy") {
      if (is.null(provenance$query_url)) cli::cli_abort("Recorded legacy scope lacks a query URL; supply {.arg scope}.")
      list(query_url = provenance$query_url)
    } else {
      if (is.null(provenance$table) || is.null(provenance$filter)) {
        cli::cli_abort("Recorded xMart scope lacks its table/filter; supply {.arg scope}.")
      }
      list(table = provenance$table, filter = provenance$filter)
    }
    scope <- list(kind = "recorded", query = .dsi_snapshot_scope(query))
  } else {
    scope <- list(kind = "declared", query = .dsi_snapshot_scope(scope))
  }
  origin <- provenance[intersect(c("base_url", "table"), names(provenance))]
  if (length(origin)) origin <- origin[order(names(origin))]
  created_at <- Sys.time()
  attr(created_at, "tzone") <- "UTC"
  out <- c(list(schema_version = 1L, created_at = created_at, source = source,
    backend = backend, indicator = indicator, layout = layout, origin = origin,
    scope = scope, provenance = provenance,
    retrieved_at = if (is.null(provenance$retrieved)) NA_character_ else provenance$retrieved,
    source_timestamp_fields = intersect(c("Date", "updated", "Sys_CommitDateUtc"), names(data))),
    definition, list(data = data))
  class(out) <- "dsir_data_snapshot"
  if (is.null(file)) return(out)
  parent <- dirname(file)
  if (!dir.exists(parent) && !dir.create(parent, recursive = TRUE, showWarnings = FALSE)) {
    cli::cli_abort("Cannot create snapshot directory {.file {parent}}.")
  }
  saveRDS(out, file)
  invisible(out)
}


.dsi_snapshot_scalar <- function(x, name) {
  if (!is.character(x) || length(x) != 1L || is.na(x) || !nzchar(trimws(x))) {
    cli::cli_abort("{.arg {name}} must be a single non-empty string.")
  }
  invisible(x)
}


.dsi_snapshot_identity <- function(supplied, recorded, name, default = NULL) {
  recorded <- unique(as.character(recorded[!is.na(recorded)]))
  recorded <- recorded[nzchar(trimws(recorded))]
  if (length(recorded) > 1L) cli::cli_abort("A snapshot must contain one {.arg {name}}.")
  if (!is.null(supplied)) {
    .dsi_snapshot_scalar(supplied, name)
    if (length(recorded) && supplied != recorded) {
      cli::cli_abort("Declared {.arg {name}} disagrees with the recorded data.")
    }
    return(supplied)
  }
  if (length(recorded)) return(recorded)
  if (!is.null(default)) return(default)
  cli::cli_abort("No recorded {.arg {name}} is available; supply it explicitly.")
}


.dsi_snapshot_safe <- function(x, depth = 0L) {
  if (depth > 20L || !(is.null(x) || is.atomic(x) || is.list(x)) ||
      inherits(x, c("httr2_request", "httr2_response", "connection"))) {
    cli::cli_abort("Snapshots cannot contain environments, request objects or other unsupported objects.")
  }
  sensitive <- "(^|[_.-])(api[_.-]?key|access[_.-]?token|refresh[_.-]?token|token|password|secret|credential[s]?|authorization|cookie)([_.-]|$)"
  if (!is.null(names(x)) && any(grepl(sensitive, names(x), ignore.case = TRUE))) {
    cli::cli_abort("Credential-like field names are not allowed in snapshots; remove sensitive fields before saving.")
  }
  if (is.character(x)) {
    pattern <- paste0("https?://[^[:space:]/]+@|",
      "[?&](api[_-]?key|access[_-]?token|token|password|secret|authorization)=|",
      "(^|[[:space:]])Bearer[[:space:]]+[A-Za-z0-9+/_.=-]{8,}")
    if (any(grepl(pattern, x[!is.na(x)], ignore.case = TRUE)) ||
        .dsi_snapshot_basic_auth(x[!is.na(x)])) {
      cli::cli_abort("Credential-like content or an authenticated URL was found; remove it before saving.")
    }
  }
  if (is.list(x)) for (item in x) .dsi_snapshot_safe(item, depth + 1L)
  attrs <- attributes(x)
  if (length(attrs)) {
    if (any(grepl(sensitive, names(attrs), ignore.case = TRUE))) {
      cli::cli_abort("Credential-like attributes are not allowed in snapshots.")
    }
    for (item in attrs) .dsi_snapshot_safe(item, depth + 1L)
  }
  invisible(NULL)
}


.dsi_snapshot_basic_auth <- function(x) {
  # Ordinary health labels contain phrases such as "basic sanitation".
  # A Basic credential must instead decode to a printable user:password pair.
  tokens <- unlist(regmatches(x, gregexpr(
    "(^|[[:space:]])Basic[[:space:]]+[A-Za-z0-9+/]+={0,2}",
    x, ignore.case = TRUE)), use.names = FALSE)
  if (!length(tokens)) return(FALSE)
  alphabet <- strsplit("ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/", "", fixed = TRUE)[[1L]]
  any(vapply(tokens, function(token) {
    token <- sub("^[[:space:]]*Basic[[:space:]]+", "", token, ignore.case = TRUE)
    valid <- grepl("^([A-Za-z0-9+/]{4})*([A-Za-z0-9+/]{2}==|[A-Za-z0-9+/]{3}=)?$", token)
    if (!valid || nchar(token) < 4L) return(FALSE)
    padding <- nchar(token) - nchar(sub("=+$", "", token))
    chars <- strsplit(gsub("=", "A", token, fixed = TRUE), "", fixed = TRUE)[[1L]]
    values <- matrix(match(chars, alphabet) - 1L, nrow = 4L)
    bytes <- as.vector(rbind(
      bitwOr(bitwShiftL(values[1L, ], 2L), bitwShiftR(values[2L, ], 4L)),
      bitwOr(bitwShiftL(bitwAnd(values[2L, ], 15L), 4L), bitwShiftR(values[3L, ], 2L)),
      bitwOr(bitwShiftL(bitwAnd(values[3L, ], 3L), 6L), values[4L, ])
    ))
    bytes <- bytes[seq_len(length(bytes) - padding)]
    any(bytes == 58L) && all(bytes >= 32L & bytes != 127L)
  }, logical(1)))
}


.dsi_snapshot_frame <- function(data) {
  if (!is.data.frame(data) || !ncol(data) || is.null(names(data)) ||
      anyNA(names(data)) || any(!nzchar(names(data))) || anyDuplicated(names(data))) {
    cli::cli_abort("{.arg data} must be a data frame with unique, non-empty column names and a GHO identity schema.")
  }
  .dsi_snapshot_safe(data)
  supported <- vapply(data, function(x) {
    is.null(dim(x)) && (is.character(x) || is.logical(x) ||
      (is.numeric(x) && !is.object(x)) || is.factor(x) ||
      inherits(x, "Date") || inherits(x, "POSIXct") || is.list(x))
  }, logical(1))
  if (any(!supported)) {
    cli::cli_abort("Unsupported snapshot column types: {.val {names(data)[!supported]}}.")
  }
  invisible(NULL)
}


.dsi_snapshot_layout <- function(data) {
  if (all(c("IndicatorCode", "SpatialDim", "TimeDim", "NumericValue") %in% names(data))) return("gho_raw")
  if (all(c("source", "id", "location", "year", "value_num") %in% names(data))) return("gho_clean")
  cli::cli_abort("Supply GHO data from {.fn gho_data} or a GHO cleaner with dimensions and metadata retained.")
}


.dsi_snapshot_columns <- function(x, available, name) {
  if (!is.character(x) || !length(x) || anyNA(x) || any(!nzchar(x)) ||
      anyDuplicated(x) || !all(x %in% available)) {
    cli::cli_abort("{.arg {name}} must name unique columns present in the data.")
  }
  x
}


.dsi_snapshot_definition <- function(data, layout, backend, key = NULL, value_fields = NULL) {
  raw <- layout == "gho_raw"
  required <- if (raw) {
    c("IndicatorCode", "SpatialDimType", "SpatialDim", "TimeDimType", "TimeDim",
      paste0("Dim", rep(1:3, each = 2L), rep(c("Type", ""), 3L)))
  } else {
    c("id", "spatial_type", "location", "time_type", "year",
      paste0("dim", rep(1:3, each = 2L), rep(c("_type", ""), 3L)))
  }
  missing <- setdiff(required, names(data))
  if (length(missing)) {
    cli::cli_abort(c("Missing GHO identity columns: {.val {missing}}.",
      "i" = "Prefer raw {.fn gho_data} output, or use {.code gho_clean(..., keep_dimensions = TRUE, keep_metadata = TRUE)}."))
  }
  extra <- if (raw) grep("^DIM_|^Dim[0-9]+(Type)?$", names(data), value = TRUE) else
    grep("^dim_|^dim[0-9]+(_type)?$", names(data), value = TRUE)
  time <- if (raw) c("TimeDimensionValue", "TimeDimensionBegin", "TimeDimensionEnd", "SpatialDimTypeOriginal") else
    c("time_detail", "time_start", "time_end", "spatial_type_source", "series")
  context <- intersect(if (raw) c("Unit", "MeasureField") else c("unit", "measure_field"), names(data))
  source_dim <- if (backend == "legacy") {
    intersect(if (raw) c("DataSourceDimType", "DataSourceDim") else c("data_source_type", "data_source"), names(data))
  } else character()
  if (!is.null(key)) key <- .dsi_snapshot_columns(key, names(data), "key")
  non_identity <- c("Id", "observation_id", "Date", "updated", "Sys_CommitDateUtc",
                    "NumericValue", "Low", "High", "Value", "value_num", "low", "high", "value")
  if (any(key %in% non_identity)) {
    cli::cli_abort("Record IDs, update timestamps and value columns cannot be observation keys.")
  }
  key <- unique(c(required, sort(extra), intersect(time, names(data)), context, source_dim, key))
  if (any(vapply(data[key], is.list, logical(1)))) cli::cli_abort("Observation keys must use scalar columns, not list-columns.")
  primary <- if (raw) "NumericValue" else "value_num"
  if (!(is.numeric(data[[primary]]) && !is.object(data[[primary]])) &&
      !(is.logical(data[[primary]]) && all(is.na(data[[primary]])))) {
    cli::cli_abort("The primary value column {.val {primary}} must be numeric (or entirely missing).")
  }
  if (is.null(value_fields)) value_fields <- intersect(
    if (raw) c("NumericValue", "Low", "High", "Value") else c("value_num", "low", "high", "value"), names(data))
  value_fields <- .dsi_snapshot_columns(value_fields, names(data), "value_fields")
  if (!primary %in% value_fields || any(value_fields %in% key)) {
    cli::cli_abort("{.arg value_fields} must include the primary numeric value and must not overlap the observation key.")
  }
  reserved <- c("old_value", "new_value", "absolute_change", "relative_change",
                "value_changed", "metadata_changed", "change_type", "changed_fields", "old", "new")
  if (any(key %in% reserved)) cli::cli_abort("Key columns conflict with comparison output names.")
  list(key = key, value_fields = value_fields, primary_value = primary, context_fields = context)
}


.dsi_snapshot_key_frame <- function(data, key) {
  out <- lapply(data[key], function(x) {
    if (inherits(x, "POSIXct") || (is.numeric(x) && !is.object(x))) {
      # Round-trip precision prevents distinct numeric keys being rounded
      # together by default character/date-time formatting.
      # Positive and negative zero have the same observation identity.
      value <- sprintf("%.17g", as.numeric(x) + 0)
      value[is.na(x)] <- NA_character_
      return(value)
    }
    as.character(x)
  })
  tibble::as_tibble(out)
}


.dsi_snapshot_check_keys <- function(data, key, layout, backend) {
  raw <- layout == "gho_raw"
  core <- if (raw) c("IndicatorCode", "SpatialDimType", "SpatialDim", "TimeDimType", "TimeDim") else
    c("id", "spatial_type", "location", "time_type", "year")
  keys <- .dsi_snapshot_key_frame(data, key)
  for (field in core) {
    if (any(is.na(keys[[field]]) | !nzchar(trimws(keys[[field]])))) {
      cli::cli_abort("Missing core observation identity in {.val {field}}.")
    }
  }
  pair_types <- if (raw) grep("^Dim[0-9]+Type$|^DIM_[0-9]+_CODE$", names(data), value = TRUE) else
    grep("^dim[0-9]+_type$|^dim_[0-9]+_code$", names(data), value = TRUE)
  if (backend == "legacy") pair_types <- c(pair_types,
    intersect(if (raw) "DataSourceDimType" else "data_source_type", names(data)))
  for (field in pair_types) {
    value <- if (raw) sub("Type$", "", field) else sub("_type$", "", field)
    if (grepl(if (raw) "^DIM_[0-9]+_CODE$" else "^dim_[0-9]+_code$", field)) {
      value <- sub(if (raw) "^DIM_" else "^dim_", if (raw) "DIM_MEMBER_" else "dim_member_", field)
      if (!value %in% names(data)) value <- sub(if (raw) "DIM_MEMBER_" else "dim_member_", if (raw) "DIM_MEMBER" else "dim_member", value, fixed = TRUE)
    }
    if (!value %in% names(data)) cli::cli_abort("Dimension {.val {field}} lacks its matching code column.")
    type_missing <- is.na(keys[[field]]) | !nzchar(trimws(keys[[field]]))
    code_missing <- is.na(keys[[value]]) | !nzchar(trimws(keys[[value]]))
    if (any(xor(type_missing, code_missing))) {
      cli::cli_abort("Dimension {.val {field}} has a missing type or code; observation identity is ambiguous.")
    }
  }
  measure <- intersect(if (raw) "MeasureField" else "measure_field", key)
  if (length(measure) && any(is.na(keys[[measure]]) | !nzchar(keys[[measure]]))) {
    cli::cli_abort("A missing measure family prevents safe matching; retain an unambiguous measure identifier.")
  }
  duplicate <- which(vctrs::vec_duplicate_detect(keys))
  if (length(duplicate)) {
    cli::cli_abort(c("Duplicate observation key at rows {.val {utils::head(duplicate, 6L)}}.",
      "i" = "Inspect dimensions and query completeness. Use {.arg key} only to add a genuine semantic dimension; do not use row numbers or record IDs to force uniqueness."))
  }
  invisible(keys)
}


.dsi_snapshot_scope <- function(scope) {
  .dsi_snapshot_safe(scope)
  normalize <- function(x) {
    if (is.null(x)) return(NULL)
    if (is.list(x)) {
      if (!length(x) || is.null(names(x)) || anyNA(names(x)) ||
          any(!nzchar(names(x))) || anyDuplicated(names(x))) {
        cli::cli_abort("{.arg scope} and nested lists must have unique, non-empty names.")
      }
      return(lapply(x[order(names(x))], normalize))
    }
    if (is.object(x) || !(is.character(x) || is.numeric(x) || is.logical(x)) ||
        !length(x) || anyNA(x) || (is.numeric(x) && any(!is.finite(x)))) {
      cli::cli_abort("Scope values must be non-missing code sets, numbers, logicals or NULL.")
    }
    if (is.character(x) && any(!nzchar(trimws(x)))) cli::cli_abort("Scope codes must not be empty.")
    if (is.numeric(x)) x <- as.numeric(x)
    sort(unique(unname(x)), method = "radix")
  }
  if (!is.list(scope) || is.data.frame(scope)) cli::cli_abort("{.arg scope} must be a non-empty named list.")
  normalize(scope)
}


.dsi_snapshot_read <- function(x, name) {
  if (is.character(x)) {
    .dsi_snapshot_scalar(x, name)
    if (!file.exists(x) || dir.exists(x)) cli::cli_abort("Snapshot file does not exist: {.file {x}}.")
    x <- readRDS(x)
  }
  required <- c("schema_version", "created_at", "source", "backend", "indicator",
    "layout", "origin", "scope", "provenance", "retrieved_at", "source_timestamp_fields",
    "key", "value_fields", "primary_value", "context_fields", "data")
  if (!inherits(x, "dsir_data_snapshot") || !is.list(x) ||
      !all(required %in% names(x)) || anyDuplicated(names(x)) ||
      !identical(x$schema_version, 1L)) {
    cli::cli_abort("{.arg {name}} must be a schema-version 1 snapshot made by {.fn data_snapshot}.")
  }
  if (!inherits(x$created_at, "POSIXct") || length(x$created_at) != 1L ||
      is.na(x$created_at) || !identical(attr(x$created_at, "tzone"), "UTC")) {
    cli::cli_abort("Snapshot creation time must be a non-missing UTC POSIXct value.")
  }
  .dsi_snapshot_safe(x)
  .dsi_snapshot_frame(x$data)
  if (!identical(x$layout, .dsi_snapshot_layout(x$data))) cli::cli_abort("Snapshot layout does not match its data.")
  for (field in c("source", "backend", "indicator")) .dsi_snapshot_scalar(x[[field]], field)
  if (x$source != "gho" || !x$backend %in% c("legacy", "xmart")) cli::cli_abort("Unsupported snapshot source or backend.")
  .dsi_snapshot_identity(x$source, if ("source" %in% names(x$data)) x$data$source else character(), "source")
  code <- if (x$layout == "gho_raw") "IndicatorCode" else "id"
  .dsi_snapshot_identity(x$indicator, x$data[[code]], "indicator")
  provider <- intersect(c("Provider", "provider"), names(x$data))
  .dsi_snapshot_identity(x$backend, c(unlist(x$data[provider], use.names = FALSE), x$provenance$backend), "backend")
  definition <- .dsi_snapshot_definition(x$data, x$layout, x$backend, x$key, x$value_fields)
  if (!all(vapply(names(definition), function(field) identical(x[[field]], definition[[field]]), logical(1)))) {
    cli::cli_abort("Snapshot identity specification does not match its data.")
  }
  .dsi_snapshot_check_keys(x$data, x$key, x$layout, x$backend)
  if (!is.list(x$scope) || !identical(names(x$scope), c("kind", "query")) ||
      !is.character(x$scope$kind) || length(x$scope$kind) != 1L ||
      is.na(x$scope$kind) || !x$scope$kind %in% c("recorded", "declared")) {
    cli::cli_abort("Malformed snapshot query scope.")
  }
  x$scope$query <- .dsi_snapshot_scope(x$scope$query)
  x
}
