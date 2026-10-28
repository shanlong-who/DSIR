#' Compare Two Local GHO Data Snapshots
#'
#' Matches observations by their full semantic key and reports additions,
#' removals, value changes and metadata changes. Everything runs offline.
#'
#' @param old,new Objects returned by [data_snapshot()], or local RDS paths
#'   containing such objects. Plain data frames and [snapshot()] cache files
#'   do not carry the required comparison contract.
#' @param fields Optional character vector of non-key fields to compare.
#'   Default `NULL` compares the union of all non-key data columns, including
#'   labels, notes, service record IDs and provider-reported timestamps.
#'   Snapshot and retrieval times are context, not observation changes.
#' @param tolerance A single non-negative, finite absolute numeric tolerance.
#'   Default `0` compares numbers exactly. It applies to numeric fields, not
#'   dates, times, character strings or matching keys. Original values remain
#'   unrounded. A display string can still change when numbers are within
#'   tolerance; use `fields` explicitly to compare numeric fields alone.
#'
#' @details
#' Comparison stops when source, backend, indicator, layout, origin, query
#' scope, key columns or value definitions differ. Changes in the available
#' unit or measure-family codes also stop comparison: these can change the
#' meaning of a quantity. Equal scope is necessary, not sufficient proof of
#' scientific comparability. Imported data and local subsets require an
#' explicit, honest scope declaration when making their snapshots.
#'
#' Matching ignores row order, column order and row names. Missing values
#' match missing values. An entirely missing logical column from JSON can
#' be compared with a later typed column; integer and double numbers are
#' compatible. Other incompatible field types cause an actionable error.
#' Missing optional metadata columns are compared as missing values, with
#' their schema differences reported separately. List-column note order is
#' retained; NULL, an empty vector and a scalar NA denote an absent note.
#'
#' A matched observation is `modified` when at least one selected field
#' changes. `value_changed` concerns selected `value_fields`; other selected
#' fields determine `metadata_changed`. A modification with no selected
#' value change is labelled `"metadata_only"`. Selecting `fields` restricts
#' every change classification; unselected differences are not counted.
#'
#' `absolute_change` is the signed difference `new_value - old_value` in
#' the primary numeric field's units. `relative_change` is that difference
#' divided by the old value, a fraction rather than a percentage. It is NA
#' for zero/missing old values, missing new values or non-finite calculations.
#' These convenience columns concern the primary value even when another
#' field triggered the modification.
#'
#' This establishes differences between two saved extracts. It does not
#' establish their exact change date, revision reason or official WHO
#' publication status. Counts of added, removed and value-modified rows can
#' inform whether to review existing outputs; the caller decides whether
#' those rows or changed labels/notes affect a particular report.
#'
#' @return A list, classed `dsir_snapshot_comparison`, containing:
#' \describe{
#'   \item{summary}{A one-row tibble with old/new snapshot and retrieval
#'     times, source, backend, indicator, query scope, observation counts,
#'     `n_added`, `n_removed`, `n_modified`, `n_unchanged`,
#'     `n_value_modified`, `n_metadata_only`, `n_metadata_modified`,
#'     selected fields and tolerance.}
#'   \item{added,removed}{Complete new-only and old-only observation rows.}
#'   \item{modified}{Key columns, primary `old_value` and `new_value`,
#'     absolute/relative changes, change flags, `change_type`,
#'     a `changed_fields` list-column, and `old` / `new` data-frame columns
#'     containing complete old/new tables aligned with the modified rows.
#'     For example, `modified$old[1, ]` is the first original old row.}
#'   \item{unchanged}{Complete new rows whose selected fields are unchanged.}
#'   \item{schema_changes}{Non-key fields added, removed or changed in type,
#'     independent of whether their values changed.}
#'   \item{key,fields,value_fields}{The identity and selected comparison fields.}
#' }
#' @seealso [data_snapshot()], [gho_last_updated()].
#' @export
#'
#' @examples
#' # See data_snapshot() for a complete offline example.
#' \dontrun{
#' result <- compare_snapshots("snapshots/gho_old.rds",
#'                             "snapshots/gho_new.rds")
#' result$summary
#' result$modified
#' # For a report using numeric values and bounds only:
#' compare_snapshots("snapshots/gho_old.rds", "snapshots/gho_new.rds",
#'                   fields = c("NumericValue", "Low", "High"))
#' }
compare_snapshots <- function(old, new, fields = NULL, tolerance = 0) {
  if (!is.numeric(tolerance) || length(tolerance) != 1L ||
      is.na(tolerance) || !is.finite(tolerance) || tolerance < 0) {
    cli::cli_abort("{.arg tolerance} must be a single non-negative finite number.")
  }
  old <- .dsi_snapshot_read(old, "old")
  new <- .dsi_snapshot_read(new, "new")
  .dsi_snapshot_compatible(old, new)
  key <- old$key
  available <- setdiff(union(names(old$data), names(new$data)), key)
  if (is.null(fields)) fields <- available else
    fields <- .dsi_snapshot_columns(fields, available, "fields")
  if (!length(fields)) cli::cli_abort("No non-key fields are available for comparison.")
  old_key <- .dsi_snapshot_key_frame(old$data, key)
  new_key <- .dsi_snapshot_key_frame(new$data, key)
  # vctrs matches data-frame rows without pasted delimiters or numeric IDs.
  old_index <- vctrs::vec_match(new_key, old_key, na_equal = TRUE)
  matched_new <- which(!is.na(old_index))
  matched_old <- old_index[matched_new]
  added <- new$data[is.na(old_index), , drop = FALSE]
  removed <- old$data[!seq_len(nrow(old$data)) %in% matched_old, , drop = FALSE]
  changed <- matrix(FALSE, nrow = length(matched_new), ncol = length(fields),
                    dimnames = list(NULL, fields))
  for (field in fields) {
    pair <- .dsi_snapshot_field_pair(old$data, new$data, field)
    changed[, field] <- !.dsi_snapshot_equal(
      pair$old[matched_old], pair$new[matched_new], tolerance, field)
  }
  modified_index <- which(rowSums(changed) > 0L)
  unchanged <- new$data[matched_new[rowSums(changed) == 0L], , drop = FALSE]
  value_columns <- intersect(fields, old$value_fields)
  metadata_columns <- setdiff(fields, value_columns)
  value_changed <- rowSums(changed[modified_index, value_columns, drop = FALSE]) > 0L
  metadata_changed <- rowSums(changed[modified_index, metadata_columns, drop = FALSE]) > 0L
  old_rows <- matched_old[modified_index]
  new_rows <- matched_new[modified_index]
  old_value <- as.numeric(old$data[[old$primary_value]][old_rows])
  new_value <- as.numeric(new$data[[new$primary_value]][new_rows])
  absolute <- relative <- rep(NA_real_, length(old_rows))
  finite <- is.finite(old_value) & is.finite(new_value)
  absolute[finite] <- new_value[finite] - old_value[finite]
  absolute[!is.finite(absolute)] <- NA_real_
  ratio_ok <- finite & old_value != 0 & !is.na(absolute)
  relative[ratio_ok] <- absolute[ratio_ok] / old_value[ratio_ok]
  relative[!is.finite(relative)] <- NA_real_
  modified <- tibble::as_tibble(new$data[new_rows, key, drop = FALSE])
  modified$old_value <- old_value
  modified$new_value <- new_value
  modified$absolute_change <- absolute
  modified$relative_change <- relative
  modified$value_changed <- value_changed
  modified$metadata_changed <- metadata_changed
  modified$change_type <- ifelse(value_changed, "value", "metadata_only")
  modified$changed_fields <- lapply(modified_index, function(i) fields[changed[i, ]])
  # Data-frame columns preserve whole row tables without making one small
  # data frame per observation when an indicator has many revisions.
  modified$old <- old$data[old_rows, , drop = FALSE]
  modified$new <- new$data[new_rows, , drop = FALSE]
  summary <- tibble::tibble(
    old_created_at = old$created_at, new_created_at = new$created_at,
    old_retrieved_at = old$retrieved_at, new_retrieved_at = new$retrieved_at,
    source = old$source, backend = old$backend, indicator = old$indicator,
    scope = list(old$scope), n_old = nrow(old$data), n_new = nrow(new$data),
    n_added = nrow(added), n_removed = nrow(removed), n_modified = nrow(modified),
    n_unchanged = nrow(unchanged), n_value_modified = sum(value_changed),
    n_metadata_only = sum(!value_changed),
    n_metadata_modified = sum(metadata_changed), fields = list(fields),
    tolerance = tolerance)
  structure(list(summary = summary, added = added, removed = removed,
    modified = modified, unchanged = unchanged,
    schema_changes = .dsi_snapshot_schema_changes(old$data, new$data, key),
    key = key, fields = fields, value_fields = value_columns),
    class = "dsir_snapshot_comparison")
}


.dsi_snapshot_compatible <- function(old, new) {
  for (field in c("source", "backend", "indicator", "layout", "origin",
                  "scope", "key", "value_fields", "primary_value", "context_fields")) {
    left <- old[[field]]
    right <- new[[field]]
    if (field %in% c("key", "value_fields", "context_fields")) {
      left <- sort(left)
      right <- sort(right)
    }
    if (!identical(left, right)) {
      cli::cli_abort(c("Incompatible snapshots: {.val {field}} differs.",
        "i" = "Use the same source, backend, indicator, query selection and complete dimension schema. Do not interpret selection differences as revisions."))
    }
  }
  for (field in old$context_fields) {
    values <- function(data) sort(unique(as.character(data[[field]][!is.na(data[[field]])])))
    # No domain can be observed for a truly empty selection.
    if (nrow(old$data) && nrow(new$data) && !identical(values(old$data), values(new$data))) {
      cli::cli_abort("Unit or measure-family context changed in {.val {field}}; comparability cannot be confirmed.")
    }
  }
  if (length(old$context_fields) && nrow(old$data) && nrow(new$data)) {
    base_key <- setdiff(old$key, old$context_fields)
    old_base <- .dsi_snapshot_key_frame(old$data, base_key)
    new_base <- .dsi_snapshot_key_frame(new$data, base_key)
    old_full <- .dsi_snapshot_key_frame(old$data, old$key)
    new_full <- .dsi_snapshot_key_frame(new$data, old$key)
    changed_new <- is.na(vctrs::vec_match(new_full, old_full)) &
      !is.na(vctrs::vec_match(new_base, old_base))
    changed_old <- is.na(vctrs::vec_match(old_full, new_full)) &
      !is.na(vctrs::vec_match(old_base, new_base))
    if (any(changed_new) || any(changed_old)) {
      cli::cli_abort("Unit or measure-family context changed at matching observation coordinates; comparability cannot be confirmed.")
    }
  }
  invisible(NULL)
}


.dsi_snapshot_field_pair <- function(old, new, field) {
  x <- old[[field]]
  y <- new[[field]]
  if (is.null(x)) x <- vctrs::vec_init(y, nrow(old))
  if (is.null(y)) y <- vctrs::vec_init(x, nrow(new))
  # JSON null-only columns have unspecified logical type. Do not infer a
  # data change from a later type becoming known.
  unspecified <- function(z) is.logical(z) && !is.object(z) && all(is.na(z))
  if (unspecified(x)) x <- vctrs::vec_init(y, length(x))
  if (unspecified(y)) y <- vctrs::vec_init(x, length(y))
  if (is.factor(x)) x <- as.character(x)
  if (is.factor(y)) y <- as.character(y)
  tryCatch({
    prototype <- vctrs::vec_ptype_common(x, y)
    list(old = vctrs::vec_cast(x, prototype), new = vctrs::vec_cast(y, prototype))
  }, error = function(e) {
    cli::cli_abort("Incompatible types for comparison field {.val {field}}. Use the same data representation in both snapshots.")
  })
}


.dsi_snapshot_equal <- function(x, y, tolerance, field) {
  if (is.list(x) && !is.object(x)) {
    absent <- function(z) is.null(z) || !length(z) ||
      (is.atomic(z) && length(z) == 1L && is.na(z))
    return(vapply(seq_along(x), function(i) {
      if (absent(x[[i]]) && absent(y[[i]])) return(TRUE)
      # List cells are complete metadata values; preserve their internal order.
      isTRUE(all.equal(x[[i]], y[[i]], tolerance = 0, check.attributes = TRUE))
    }, logical(1)))
  }
  if (is.numeric(x) && !is.object(x)) {
    missing <- is.na(x) & is.na(y)
    same <- !is.na(x) & !is.na(y) & x == y
    close <- is.finite(x) & is.finite(y) & abs(y - x) <= tolerance
    return(missing | same | close)
  }
  tryCatch(vctrs::vec_equal(x, y, na_equal = TRUE), error = function(e) {
    cli::cli_abort("Unsupported comparison field {.val {field}}.")
  })
}


.dsi_snapshot_schema_changes <- function(old, new, key) {
  fields <- setdiff(union(names(old), names(new)), key)
  type <- function(data, field) {
    if (!field %in% names(data)) return(NA_character_)
    paste(c(typeof(data[[field]]), class(data[[field]])), collapse = "/")
  }
  old_type <- vapply(fields, function(field) type(old, field), character(1))
  new_type <- vapply(fields, function(field) type(new, field), character(1))
  kind <- ifelse(is.na(old_type), "added", ifelse(is.na(new_type), "removed", "type_changed"))
  keep <- is.na(old_type) | is.na(new_type) | old_type != new_type
  tibble::tibble(field = fields[keep], change = unname(kind[keep]),
                 old_type = unname(old_type[keep]), new_type = unname(new_type[keep]))
}
