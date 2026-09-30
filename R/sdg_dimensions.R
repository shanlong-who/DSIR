#' Extract named SDG dimensions without losing rows or source codes
#'
#' @noRd
.sdg_dimensions_frame <- function(df) {
  .sdg_nested_frame(df, "dimensions")
}


#' Extract named dimension or attribute records
#'
#' @noRd
.sdg_nested_frame <- function(df, field) {
  n <- nrow(df)
  dims <- df[[field]]
  empty <- tibble::new_tibble(list(), nrow = n)
  if (is.null(dims)) return(empty)
  if (is.atomic(dims) && length(dims) == n && all(is.na(dims))) return(empty)

  # jsonlite usually simplifies JSON objects to a packed data frame.
  # Null objects can instead produce a list of named records.
  if (is.data.frame(dims)) {
    out <- dims
  } else if (is.list(dims) && length(dims) == n) {
    rows <- lapply(dims, function(row) {
      if (length(row) == 0L) {
        return(tibble::new_tibble(list(), nrow = 1L))
      }
      tibble::as_tibble(lapply(row, function(value) {
        if (length(value) == 0L) NA_character_ else as.character(value)
      }))
    })
    if (length(rows) == 0L) return(empty)
    out <- do.call(vctrs::vec_rbind, rows)
  } else {
    cli::cli_abort("The {.field {field}} column must contain named SDG records.")
  }

  if (nrow(out) != n) {
    cli::cli_abort("SDG {.field {field}} must have one record per observation.")
  }
  out[] <- lapply(out, function(column) {
    if (is.list(column)) {
      vapply(column, function(value) {
        if (length(value) == 0L) NA_character_ else as.character(value)
      }, character(1))
    } else {
      as.character(column)
    }
  })
  tibble::as_tibble(out)
}


#' Append flat, named dimensions to the 15-column core
#'
#' @noRd
.sdg_append_dimensions <- function(out, df) {
  dims <- .sdg_dimensions_frame(df)
  if (ncol(dims) == 0L) return(out)

  dim_names <- .sdg_field_names(names(dims), "dim_")
  for (i in seq_along(dims)) out[[dim_names[[i]]]] <- dims[[i]]
  out
}


#' @noRd
.sdg_field_names <- function(fields, prefix) {
  if (length(fields) == 0L) return(character())
  column_names <- tolower(fields)
  column_names <- gsub("[^a-z0-9]+", "_", column_names)
  column_names <- gsub("^_+|_+$", "", column_names)
  column_names <- paste0(prefix, column_names)
  if (anyDuplicated(column_names)) {
    cli::cli_abort(c(
      "SDG field names are not unique after conversion to snake_case.",
      "i" = "Inspect the raw dimensions or attributes and rename conflicting fields before cleaning."
    ))
  }
  column_names
}


#' Validate SDG series and dimension filters before downloading
#'
#' @noRd
.sdg_validate_filters <- function(series, dimensions) {
  valid_codes <- function(x) {
    is.character(x) && length(x) > 0L && !anyNA(x) && all(nzchar(x))
  }
  if (!is.null(series) && !valid_codes(series)) {
    cli::cli_abort("{.arg series} must be NULL or a non-empty character vector of codes.")
  }
  if (is.null(dimensions)) return(invisible(NULL))
  if (!is.list(dimensions) || is.data.frame(dimensions) ||
      (length(dimensions) > 0L &&
       (is.null(names(dimensions)) || anyNA(names(dimensions)) ||
        any(!nzchar(names(dimensions))) || anyDuplicated(names(dimensions)) ||
        !all(vapply(dimensions, valid_codes, logical(1)))))) {
    cli::cli_abort(c(
      "{.arg dimensions} must be a named list of non-empty character vectors.",
      "i" = 'For example, {.code list(Sex = "BOTHSEX", Quantile = "_T")}; names must be unique.'
    ))
  }
  invisible(NULL)
}


#' Filter using the original UN dimension names and codes
#'
#' @noRd
.sdg_filter_observations <- function(df, series, dimensions) {
  keep <- rep(TRUE, nrow(df))
  if (!is.null(series)) {
    if (!"series" %in% names(df)) {
      cli::cli_warn("Cannot apply series filter: {.field series} column missing; returning no rows.")
      return(df[integer(0), , drop = FALSE])
    }
    keep <- keep & df$series %in% series
  }
  if (length(dimensions) > 0L) {
    dims <- .sdg_dimensions_frame(df)
    missing_dims <- setdiff(names(dimensions), names(dims))
    if (length(missing_dims) > 0L) {
      cli::cli_warn(c(
        "Requested SDG dimension{?s} not present: {.val {missing_dims}}.",
        "i" = "Returning no rows; inspect the raw dimensions for available names."
      ))
      return(df[integer(0), , drop = FALSE])
    }
    for (nm in names(dimensions)) {
      keep <- keep & dims[[nm]] %in% dimensions[[nm]]
    }
  }
  df[keep, , drop = FALSE]
}
