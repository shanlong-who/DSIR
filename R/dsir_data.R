#' Explicitly Create an Experimental DSIR Data Object
#'
#' Adds a `dsir_data` tibble subclass to an already cleaned indicator table.
#' Cleaners return this subclass by default; `output = "tibble"` opts out.
#' Downloads and directory functions retain their existing return types.
#' This experimental interface and its metadata schema may change.
#'
#' @param x A data frame with the typed 15-column schema returned by
#'   [gho_clean()], [ghe_clean()] or [sdg_clean()]. Optional columns are kept.
#'
#' @return A tibble inheriting from `dsir_data`, with a `dsir_metadata`
#'   attribute. Use [dsir_metadata()] to inspect it.
#'
#' @details
#' Conversion does not retrieve data or recover discarded fields. Retain
#' dimensions and metadata when cleaning if they are needed for analysis.
#' Recorded `who_provenance` is moved into the metadata, not duplicated.
#' Unknown retrieval times and definitions remain unknown. The initial
#' `as_supplied` status describes the input; it does not certify its origin,
#' completeness, units or statistical validity.
#'
#' Row selection and ordering preserve the class. Column modifications,
#' including `dplyr::mutate()` and base replacement, preserve it while the
#' core schema remains valid. New columns are marked derived. Changes to
#' input fields mark their metadata as needing review; changes to values,
#' units or identifiers also flag related interpretation. This records field
#' changes, not an executable transformation history or inferred formulas.
#' Deleting a core column or changing its required type returns a plain
#' tibble. Removing optional input columns records the loss of information.
#'
#' Joins, row binding, persistent grouping and explicit conversion with
#' `tibble::as_tibble()` or `as.data.frame()` return ordinary tables without
#' object-level provenance. Per-row source and dimension columns remain.
#' Use `.by` for transient dplyr grouping. Summary operations create new
#' ordinary tables. Direct manipulation of attributes is outside this
#' experimental contract.
#'
#' [data_snapshot()] accepts an unchanged GHO object with the required
#' detailed fields and original provenance. Row-selected objects need an
#' explicit query scope. Objects whose metadata needs review are rejected;
#' retain the original observations for reproducible source snapshots.
#'
#' @seealso [dsir_metadata()], [plot.dsir_data()], [gho_catalog]
#' @export
#'
#' @examples
#' raw <- tibble::tibble(
#'   IndicatorCode = "EXAMPLE", IndicatorName = "Example indicator",
#'   SpatialDim = c("PHL", "LAO"), TimeDim = c(2022L, 2023L),
#'   NumericValue = c(10, 20), Value = c("10", "20")
#' )
#' x <- as_dsir_data(gho_clean(raw))
#' x
#' summary(x)
#' x$value_num <- x$value_num / 100
#' dsir_metadata(x)$processing
as_dsir_data <- function(x) {
  problem <- .dsi_data_problem(x)
  if (!is.null(problem)) cli::cli_abort("{problem}")
  if (inherits(x, c("grouped_df", "rowwise_df"))) {
    cli::cli_abort("Ungroup {.arg x} before converting it to {.cls dsir_data}.")
  }
  if (inherits(x, "dsir_data")) {
    .dsi_data_metadata(x)
    return(x)
  }
  provenance <- attr(x, "who_provenance", exact = TRUE)
  if (is.null(provenance)) provenance <- list()
  if (!is.list(provenance) || is.data.frame(provenance)) {
    cli::cli_abort("Recorded {.code who_provenance} must be a list.")
  }
  metadata <- list(
    schema_version = 1L, layout = "clean",
    provenance = list(sources = .dsi_data_values(x$source), retrieval = provenance),
    input = list(rows = nrow(x), columns = names(x)),
    fields = tibble::tibble(column = names(x), role = .dsi_data_roles(names(x)),
                           origin = "input", status = "as_supplied"),
    processing = list(state = "as_supplied", row_scope = "input",
                      semantics = "as_supplied", modified_columns = character(),
                      removed_columns = character(), review_columns = character())
  )
  acquisition <- attr(x, "dsir_metadata", exact = TRUE)
  if (isTRUE(acquisition$layout %in% c("retrieval", "cleaning"))) {
    fields <- intersect(c("source", "kind", "sources", "query", "result", "cleaning"), names(acquisition))
    metadata[fields] <- acquisition[fields]
  }
  .new_dsir_data(x, metadata)
}


#' Inspect DSIR Data, Catalog and Retrieval Metadata
#'
#' Reads metadata without network requests. For `dsir_data`, indicator
#' identities, dimension values and coverage describe the current rows;
#' provenance and input counts describe the original conversion input.
#'
#' @param x A download, directory or cleaned result carrying DSIR metadata,
#'   a [dsir_data][as_dsir_data] object, or one of the bundled
#'   [gho_catalog], [sdg_catalog] and [ghe_catalog] datasets.
#' @return A named list. For an analysis object it contains `schema_version`,
#'   `layout`, `provenance`, `input`, `fields`, `processing`, `current`,
#'   `indicators` and `dimensions`. Current indicator labels and dimension
#'   values are observations from the table, not independently fetched
#'   definitions. Read `processing$semantics` before interpreting them.
#'   Catalog metadata includes its snapshot version, package build version
#'   and source-specific retrieval records. `current` describes the supplied
#'   table; source record counts describe the complete bundled snapshot.
#' @section Retrieval metadata:
#' Downloads and directories retain their existing classes and columns.
#' `dsir_metadata(x)$sources` records the actual backend, endpoint, UTC
#' `retrieved_at`, retrieval status, cache use, source record count, reported
#' API version and release. Unknown versions and times remain `NA`.
#' Each source row includes its own server query. `query` records the public
#' selection, including local filters and reference-country/year restrictions.
#' `result` describes the function's original return; `current` is computed
#' from the supplied object. Source counts precede local filtering and GHE
#' measure pivoting, so they can differ from returned row counts.
#'
#' Result status distinguishes `success`, `empty`, `failed`, `incomplete`,
#' `invalid`, `partial` and `unverified`. Completeness concerns the requested
#' retrieval, not global indicator coverage. It is `NA` when the response
#' lacks sufficient completeness information. A successful HTTP response
#' alone does not establish completeness of an observation download.
#'
#' Cached records retain their original retrieval time and set `cache_hit`.
#' A historical fallback uses `retrieval_status = "bundled_snapshot"` and
#' retains the original collection date. It does not prove live availability.
#' Failed SDG list requests still return `NULL` with a warning; `NULL` cannot
#' carry metadata. Other empty failure results record no successful retrieval
#' time. Existing WHO `who_provenance` and `catalog_snapshot` attributes remain
#' available for compatibility.
#'
#' Cleaners preserve acquisition metadata even for empty input. This is
#' independent of `keep_metadata`, which controls optional data columns.
#' `as_dsir_data()` also retains `sources`, `query` and `result`. These are
#' historical acquisition records, not an audit of arbitrary changes to a
#' plain tibble. Use the S3 object's processing status to track supported
#' transformations. `saveRDS()` preserves attributes; CSV does not.
#'
#' Cleaning records live in `cleaning`, also for `output = "tibble"` and
#' user-supplied input without acquisition records. They contain the cleaner,
#' package version, UTC cleaning time, input/output sizes and columns, options,
#' and a profile of semantic fields. Each profile records its retained column
#' (or `NA`), distinct count including missing values, missing count and its
#' constant value, if any. Varying omitted values are not stored row by row.
#' Recorded aliases link equivalent core and named dimensions. Cleaning time
#' never substitutes for retrieval time. These records describe the cleaning
#' input; current coverage and subsequent field status remain separate.
#' @section Map metadata:
#' [dsir_map()] records `layout = "map"`, creation time, selected keys and
#' value/year columns, input metadata and boundary provenance. Downloaded
#' boundaries record per-country endpoints, queries, original retrieval times,
#' item modification times, source terms, checksums and cache use. Supplied
#' boundaries are labelled `user_supplied`, with no invented retrieval history.
#' This describes map creation, not later ggplot edits or additional layers.
#' @export
#' @examples
#' dsir_metadata(gho_catalog)$sources
dsir_metadata <- function(x) {
  metadata <- attr(x, "dsir_metadata", exact = TRUE)
  if (!is.list(metadata) || !identical(metadata$schema_version, 1L)) {
    cli::cli_abort("{.arg x} has no supported DSIR metadata.")
  }
  if (inherits(x, "dsir_data")) {
    metadata <- .dsi_data_metadata(x)
    metadata$current <- list(
      rows = nrow(x), columns = ncol(x), sources = .dsi_data_values(x$source),
      locations = .dsi_data_values(x$location),
      countries = .dsi_data_values(x$iso3), years = .dsi_data_values(x$year)
    )
    identity <- intersect(c("source", "provider", "id", "series", "indicator",
                            "unit", "attr_units", "measure_field"), names(x))
    plain <- .dsi_data_plain(x)
    metadata$indicators <- unique(plain[identity])
    dims <- names(x)[.dsi_data_roles(names(x)) == "dimension"]
    metadata$dimensions <- lapply(plain[dims], .dsi_data_values)
  } else if (identical(metadata$layout, "catalog") && is.data.frame(x)) {
    metadata$current <- list(rows = nrow(x), columns = ncol(x))
  } else if (isTRUE(metadata$layout %in% c("retrieval", "cleaning"))) {
    metadata$current <- if (is.data.frame(x)) list(rows = nrow(x), columns = ncol(x)) else list(length = length(x))
  } else if (identical(metadata$layout, "map") && inherits(x, "ggplot")) {
    # Map metadata describes creation, not later changes to layers or scales.
    return(metadata)
  } else {
    cli::cli_abort("{.arg x} must carry supported DSIR data, catalog or retrieval metadata.")
  }
  metadata
}


.dsi_data_problem <- function(x) {
  if (!is.data.frame(x)) return("Input must be a cleaned data frame.")
  if (is.null(names(x)) || anyNA(names(x)) || any(!nzchar(names(x))) || anyDuplicated(names(x))) {
    return("Column names must be unique and non-empty.")
  }
  schema <- .dsi_clean_schema()
  absent <- setdiff(names(schema), names(x))
  if (length(absent)) return(paste("Missing cleaned-schema columns:", paste(absent, collapse = ", ")))
  valid <- vapply(names(schema), function(field) {
    value <- x[[field]]
    is.null(dim(value)) && switch(schema[[field]],
      chr = is.character(value), int = is.integer(value),
      num = is.numeric(value) && !is.object(value))
  }, logical(1))
  if (any(!valid)) return(paste("Invalid cleaned-schema column types:", paste(names(schema)[!valid], collapse = ", ")))
  NULL
}

.dsi_data_plain <- function(x) {
  columns <- lapply(seq_along(x), function(i) x[[i]])
  names(columns) <- names(x)
  tibble::new_tibble(columns, nrow = nrow(x))
}

.new_dsir_data <- function(x, metadata) {
  out <- .dsi_data_plain(x)
  attr(out, "dsir_metadata") <- metadata
  class(out) <- c("dsir_data", class(out))
  out
}

.dsi_data_metadata <- function(x) {
  metadata <- attr(x, "dsir_metadata", exact = TRUE)
  if (!is.list(metadata) || !identical(metadata$schema_version, 1L) ||
      !identical(metadata$layout, "clean") || !is.list(metadata$processing) ||
      !is.data.frame(metadata$fields) || !identical(metadata$fields$column, names(x))) {
    cli::cli_abort("Invalid experimental DSIR metadata; use the original cleaned table.")
  }
  metadata
}

.dsi_data_values <- function(x) {
  if (is.list(x)) return(unique(x))
  sort(unique(x[!is.na(x)]))
}

.dsi_data_roles <- function(fields) {
  roles <- rep("metadata", length(fields))
  roles[grepl("^attr_", fields)] <- "dimension"
  roles[fields %in% c("source", "provider", "id", "series", "observation_id")] <- "identity"
  roles[fields %in% c("value", "value_num", "low", "high")] <- "value"
  roles[fields %in% c("unit", "attr_units", "attr_unit_multiplier", "attr_unit_mult",
                      "base_period", "measure_field")] <- "measure"
  roles[fields %in% c("location", "iso3", "location_name", "year", "spatial_type", "time_type") |
          grepl("^dim[123]($|_)|^dim_", fields)] <- "dimension"
  roles
}

.dsi_data_update <- function(data, template, compare = TRUE) {
  if (!is.data.frame(data)) return(data)
  if (!is.null(.dsi_data_problem(data))) return(.dsi_data_plain(data))
  metadata <- .dsi_data_metadata(template)
  old <- names(template)
  added <- setdiff(names(data), old)
  removed <- setdiff(old, names(data))
  common <- intersect(old, names(data))
  changed <- if (compare) common[!vapply(common, function(field) {
    identical(data[[field]], template[[field]])
  }, logical(1))] else character()
  fields <- metadata$fields[match(intersect(names(data), old), metadata$fields$column), ]
  fields$status[fields$column %in% changed] <- "modified"
  if (length(added)) {
    fields <- vctrs::vec_rbind(fields, tibble::tibble(
      column = added, role = .dsi_data_roles(added), origin = "derived", status = "derived"))
  }
  metadata$fields <- fields[match(names(data), fields$column), ]
  processing <- metadata$processing
  processing$modified_columns <- union(processing$modified_columns, changed)
  processing$removed_columns <- union(processing$removed_columns, removed)
  touched <- union(changed, removed)
  input.touched <- intersect(touched, metadata$input$columns)
  semantic.added <- added[.dsi_data_roles(added) != "metadata"]
  if (length(input.touched) || length(semantic.added)) {
    processing$semantics <- "needs_review"
    review <- union(input.touched, semantic.added)
    if (any(.dsi_data_roles(review) %in% c("identity", "dimension"))) {
      review <- union(review, metadata$input$columns)
    } else if (any(.dsi_data_roles(review) %in% c("value", "measure"))) {
      review <- union(review, intersect(c("value", "value_num", "low", "high", "unit",
                                         "attr_units", "measure_field", "indicator"), names(data)))
    }
    processing$review_columns <- union(processing$review_columns, review)
  }
  if (length(c(added, removed, changed))) processing$state <- "derived"
  if (nrow(data) != nrow(template)) {
    processing$row_scope <- "subset"
    if (processing$state == "as_supplied") processing$state <- "subset"
  }
  metadata$processing <- processing
  .new_dsir_data(data, metadata)
}


#' @rdname as_dsir_data
#' @param ... Arguments passed to the underlying tibble printer, or reserved
#'   for future summary options.
#' @export
print.dsir_data <- function(x, ...) {
  metadata <- dsir_metadata(x)
  retrieval <- metadata$provenance$retrieval
  if (!is.null(metadata$sources)) {
    retrieval$backend <- metadata$sources$backend
    retrieval$retrieved <- metadata$sources$retrieved_at
  }
  label <- function(value) {
    value <- value[!is.na(value) & nzchar(value)]
    if (!length(value)) "not recorded" else paste(unique(value), collapse = ", ")
  }
  cat("<dsir_data> ", metadata$processing$state,
      " | metadata: ", metadata$processing$semantics, "\n", sep = "")
  cat("Origin: ", label(metadata$source %||% metadata$provenance$sources),
      " | Backend: ", label(retrieval$backend),
      " | Retrieved: ", label(retrieval$retrieved), "\n", sep = "")
  codes <- .dsi_data_values(x$id)
  shown <- utils::head(codes, 3L)
  cat("Indicators: ", label(shown), if (length(codes) > 3L) " (...)" else "", "\n", sep = "")
  labels <- .dsi_data_values(x$indicator)
  if (length(labels)) cat("Names: ", substr(paste(utils::head(labels, 2L), collapse = "; "), 1L, 160L), "\n", sep = "")
  cleaning <- metadata$cleaning
  if (!is.null(cleaning)) {
    omitted <- cleaning$fields$column[is.na(cleaning$fields$retained_as) & cleaning$fields$distinct > 1L]
    cat("Cleaned: ", cleaning$function_name, " | At: ", cleaning$cleaned_at,
        " | Omitted varying fields: ", length(omitted), "\n", sep = "")
  }
  print(.dsi_data_plain(x), ...)
  invisible(x)
}


#' @rdname as_dsir_data
#' @param object A `dsir_data` object.
#' @details
#' `summary()` returns a structured list with current coverage, indicator
#' identities, dimension values, per-column missing counts and provenance.
#' Numeric diagnostics count missing and non-finite `value_num` entries.
#' This first version does not pool numerical statistics across indicators,
#' countries, units or demographic groups. Empty list entries and entries
#' containing only missing values count as missing in list columns.
#' @export
summary.dsir_data <- function(object, ...) {
  metadata <- dsir_metadata(object)
  missing <- vapply(object, function(column) {
    if (is.list(column)) {
      sum(vapply(column, function(value) !length(value) || all(is.na(value)), logical(1)))
    } else sum(is.na(column))
  }, integer(1))
  structure(list(
    current = metadata$current,
    indicators = metadata$indicators,
    dimensions = metadata$dimensions,
    missing = tibble::tibble(column = names(missing), n_missing = unname(missing)),
    numeric = list(n_missing = sum(is.na(object$value_num)),
                   n_nonfinite = sum(!is.na(object$value_num) & !is.finite(object$value_num))),
    provenance = metadata$provenance,
    sources = metadata$sources,
    query = metadata$query,
    result = metadata$result,
    cleaning = metadata$cleaning,
    processing = metadata$processing
  ), class = "summary_dsir_data")
}

#' @export
print.summary_dsir_data <- function(x, ...) {
  cat("<dsir_data summary> ", x$current$rows, " rows; ", x$current$columns, " columns\n", sep = "")
  cat("Current coverage: ", length(x$current$countries), " countries; ",
      length(x$current$locations), " locations; ", length(x$current$years), " years\n", sep = "")
  if (length(x$current$years)) cat("Year range:", paste(range(x$current$years), collapse = "-"), "\n")
  cat("State:", x$processing$state, "| Metadata:", x$processing$semantics, "\n")
  cat("Current indicators and series:\n")
  print(x$indicators, ...)
  cat("Missing values by column:\n")
  print(x$missing, ...)
  cat("Non-finite numeric values:", x$numeric$n_nonfinite, "\n")
  invisible(x)
}
