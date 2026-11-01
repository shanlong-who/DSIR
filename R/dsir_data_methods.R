# Small reconstruction hooks rather than a separate data manipulation API.

#' @export
`[.dsir_data` <- function(x, i, j, drop = FALSE) {
  out <- NextMethod()
  out <- .dsi_data_update(out, x, compare = FALSE)
  if (inherits(out, "dsir_data") && !missing(i) && nargs() >= 3L) {
    metadata <- .dsi_data_metadata(out)
    metadata$processing$row_scope <- "subset"
    if (metadata$processing$state == "as_supplied") metadata$processing$state <- "subset"
    out <- .new_dsir_data(out, metadata)
  }
  out
}

#' @export
`names<-.dsir_data` <- function(x, value) {
  out <- .dsi_data_plain(x)
  names(out) <- value
  .dsi_data_update(out, x)
}

#' @export
`$<-.dsir_data` <- function(x, name, value) {
  out <- .dsi_data_plain(x)
  out[[name]] <- value
  .dsi_data_update(out, x)
}

#' @export
`[[<-.dsir_data` <- function(x, ..., value) {
  out <- .dsi_data_plain(x)
  out[[...]] <- value
  .dsi_data_update(out, x)
}

#' @export
`[<-.dsir_data` <- function(x, ..., value) {
  out <- .dsi_data_plain(x)
  out[...] <- value
  .dsi_data_update(out, x)
}

#' @exportS3Method tibble::as_tibble
as_tibble.dsir_data <- function(x, ...) {
  tibble::as_tibble(.dsi_data_plain(x), ...)
}

#' @export
as.data.frame.dsir_data <- function(x, row.names = NULL, optional = FALSE, ...) {
  as.data.frame(.dsi_data_plain(x), row.names = row.names, optional = optional, ...)
}

#' @exportS3Method dplyr::dplyr_row_slice
dplyr_row_slice.dsir_data <- function(data, i, ...) {
  out <- vctrs::vec_slice(.dsi_data_plain(data), i)
  metadata <- .dsi_data_metadata(data)
  indices <- seq_len(nrow(data))[i]
  if (!identical(sort(indices, na.last = TRUE), seq_len(nrow(data)))) {
    metadata$processing$row_scope <- "subset"
    if (metadata$processing$state == "as_supplied") metadata$processing$state <- "subset"
  }
  .new_dsir_data(out, metadata)
}

#' @exportS3Method dplyr::dplyr_col_modify
dplyr_col_modify.dsir_data <- function(data, cols) {
  out <- dplyr::dplyr_col_modify(.dsi_data_plain(data), cols)
  .dsi_data_update(out, data)
}

#' @exportS3Method dplyr::dplyr_reconstruct
dplyr_reconstruct.dsir_data <- function(data, template) {
  # Joins and bind_rows cannot infer provenance from their first input.
  .dsi_data_plain(data)
}

#' @exportS3Method dplyr::group_by
group_by.dsir_data <- function(.data, ..., .add = FALSE,
                               .drop = dplyr::group_by_drop_default(.data)) {
  dplyr::group_by(.dsi_data_plain(.data), ..., .add = .add, .drop = .drop)
}

#' @exportS3Method dplyr::rowwise
rowwise.dsir_data <- function(data, ...) {
  dplyr::rowwise(.dsi_data_plain(data), ...)
}

#' @exportS3Method vctrs::vec_restore
vec_restore.dsir_data <- function(x, to, ...) .dsi_data_plain(x)

#' @exportS3Method vctrs::vec_ptype2
vec_ptype2.dsir_data.dsir_data <- function(x, y, ...) {
  vctrs::tib_ptype2(.dsi_data_plain(x), .dsi_data_plain(y), ...)
}

#' @exportS3Method vctrs::vec_ptype2
vec_ptype2.dsir_data.tbl_df <- function(x, y, ...) {
  vctrs::tib_ptype2(.dsi_data_plain(x), y, ...)
}

#' @exportS3Method vctrs::vec_ptype2
vec_ptype2.tbl_df.dsir_data <- function(x, y, ...) {
  vctrs::tib_ptype2(x, .dsi_data_plain(y), ...)
}

#' @exportS3Method vctrs::vec_ptype2
vec_ptype2.dsir_data.data.frame <- function(x, y, ...) {
  vctrs::tib_ptype2(.dsi_data_plain(x), y, ...)
}

#' @exportS3Method vctrs::vec_ptype2
vec_ptype2.data.frame.dsir_data <- function(x, y, ...) {
  vctrs::tib_ptype2(x, .dsi_data_plain(y), ...)
}

#' @exportS3Method vctrs::vec_cast
vec_cast.tbl_df.dsir_data <- function(x, to, ...) {
  vctrs::tib_cast(.dsi_data_plain(x), to, ...)
}

#' @exportS3Method vctrs::vec_cast
vec_cast.data.frame.dsir_data <- function(x, to, ...) {
  vctrs::df_cast(.dsi_data_plain(x), to, ...)
}

#' @export
rbind.dsir_data <- function(..., deparse.level = 1) {
  inputs <- lapply(list(...), function(x) if (inherits(x, "dsir_data")) .dsi_data_plain(x) else x)
  do.call(rbind, c(inputs, list(deparse.level = deparse.level)))
}

#' @export
cbind.dsir_data <- function(..., deparse.level = 1) {
  inputs <- lapply(list(...), function(x) if (inherits(x, "dsir_data")) .dsi_data_plain(x) else x)
  do.call(cbind, c(inputs, list(deparse.level = deparse.level)))
}
