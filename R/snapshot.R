#' Snapshot an Expensive Expression to a Local File
#'
#' Evaluates an expression — typically an API pull such as a
#' [gho_data()] / [gho_clean()] pipeline — and saves the result to an
#' `.rds` file. On later calls, the saved snapshot is read back instead
#' of re-evaluating the expression, so analyses re-run reproducibly and
#' offline once the data have been fetched.
#'
#' @details
#' The decision logic is:
#'
#' 1. If `file` exists, `refresh = FALSE`, and the snapshot is younger
#'    than `max_age` days, the snapshot is read and returned. `expr` is
#'    **not** evaluated.
#' 2. Otherwise `expr` is evaluated. A usable result (anything other
#'    than `NULL`, a 0-row data frame, or an empty list) is written to
#'    `file` (directories are created as needed) and returned.
#' 3. An *empty* result — the signature of an unreachable API, since
#'    DSIR's network functions fail soft — is never written, so a
#'    failed refresh cannot destroy a good snapshot. If an older
#'    snapshot exists it is returned instead, with a warning; otherwise
#'    the empty result is returned as-is.
#'
#' `snapshot()` deliberately does **not** invent file names, manage a
#' cache directory, or hash arguments: you choose the path, so a project
#' can use a fixed name (`data/indicators.rds`) or a dated one, and the
#' file is plain `saveRDS()` output readable without DSIR.
#'
#' To force a re-fetch, pass `refresh = TRUE` (or delete the file).
#'
#' @param expr An expression producing the object to snapshot. Evaluated
#'   lazily — only when no usable snapshot exists (see Details).
#' @param file Path of the snapshot file (conventionally `.rds`). Read
#'   with [readRDS()] and written with [saveRDS()].
#' @param refresh Logical. Re-evaluate `expr` even if a snapshot exists?
#'   Default `FALSE`.
#' @param max_age Numeric. Maximum acceptable snapshot age in **days**;
#'   an older snapshot triggers re-evaluation as if `refresh = TRUE`.
#'   Default `Inf` (a snapshot never expires).
#'
#' @return The snapshotted object: either the value of `expr` or the
#'   contents of `file`, per the logic above. A message states which of
#'   the two was used.
#' @seealso [gho_data()], [sdg_data()], [bind_indicators()] — the
#'   typical producers of snapshotted objects.
#' @export
#'
#' @examples
#' path <- tempfile(fileext = ".rds")
#'
#' # First call evaluates the expression and writes the snapshot
#' x <- snapshot(data.frame(a = 1:3), path)
#'
#' # Second call reads the snapshot; the expression is not evaluated
#' y <- snapshot(stop("not evaluated"), path)
#' identical(x, y)
#'
#' # Force a refresh
#' z <- snapshot(data.frame(a = 1:5), path, refresh = TRUE)
#' nrow(z)
#'
#' unlink(path)
#' \donttest{
#' # Typical use: pin an API pull for a reproducible report
#' ncd <- snapshot(
#'   gho_clean(gho_data("NCDMORT3070", "country", wpro_cty)),
#'   file.path(tempdir(), "ncdmort3070.rds")
#' )
#' }
snapshot <- function(expr, file, refresh = FALSE, max_age = Inf) {
  # ── Input validation ──────────────────────────────────────────
  if (!is.character(file) || length(file) != 1L || is.na(file) ||
      !nzchar(file)) {
    cli::cli_abort("{.arg file} must be a single, non-empty file path.")
  }
  if (!isTRUE(refresh) && !isFALSE(refresh)) {
    cli::cli_abort("{.arg refresh} must be a single logical value.")
  }
  if (!is.numeric(max_age) || length(max_age) != 1L || is.na(max_age) ||
      max_age <= 0) {
    cli::cli_abort("{.arg max_age} must be a single positive number of days.")
  }

  # ── Use the snapshot when allowed ─────────────────────────────
  has_snapshot <- file.exists(file)
  if (has_snapshot && !refresh) {
    age_days <- as.numeric(
      difftime(Sys.time(), file.mtime(file), units = "days")
    )
    if (age_days <= max_age) {
      cli::cli_inform(
        "Using snapshot {.file {file}} (saved {format(file.mtime(file))})."
      )
      return(readRDS(file))
    }
    cli::cli_inform(
      "Snapshot {.file {file}} is {round(age_days, 1)} days old \\
      (> {max_age}); re-evaluating."
    )
  }

  # ── Evaluate (lazy promise forced here) ───────────────────────
  obj <- expr

  # ── Empty result: never overwrite a good snapshot ─────────────
  if (.is_empty_result(obj)) {
    if (has_snapshot) {
      cli::cli_warn(c(
        "The expression returned an empty result; snapshot not updated.",
        "i" = "Returning the existing snapshot {.file {file}} \\
        (saved {format(file.mtime(file))})."
      ))
      return(readRDS(file))
    }
    cli::cli_warn(
      "The expression returned an empty result; no snapshot written."
    )
    return(obj)
  }

  # ── Write and return ──────────────────────────────────────────
  dir <- dirname(file)
  if (!dir.exists(dir)) {
    dir.create(dir, recursive = TRUE, showWarnings = FALSE)
  }
  saveRDS(obj, file)
  cli::cli_inform("Snapshot written to {.file {file}}.")
  obj
}


#' An "empty" result is the signature of a failed fail-soft API pull:
#' NULL, a data frame with no rows, or a bare list with no elements.
#'
#' @noRd
.is_empty_result <- function(obj) {
  is.null(obj) ||
    (is.data.frame(obj) && nrow(obj) == 0L) ||
    (is.list(obj) && !is.data.frame(obj) && length(obj) == 0L)
}
