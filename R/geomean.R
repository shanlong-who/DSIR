#' Geometric Mean
#'
#' Computes the geometric mean of a numeric vector, with optional
#' weights. Useful for aggregating multiplicative quantities such as
#' ratio-based health indicators (e.g. UHC service-coverage tracers,
#' where the composite index is the geometric mean of component
#' coverage values).
#'
#' Pass `w` to compute a weighted geometric mean, defined as
#' `exp(weighted.mean(log(x), w))`.
#'
#' @param x A numeric vector. Zeros produce a result of `0`.
#'   Negative values produce `NaN` with a warning, since the
#'   geometric mean is undefined for negative numbers.
#' @param w Optional numeric vector of weights, the same length as
#'   `x`. Must be non-negative. If `NULL` (default), the unweighted
#'   geometric mean is returned.
#' @param na.rm Logical. Should missing values in `x` (and `w`, if
#'   provided) be removed before computation? Default `TRUE`.
#'
#' @return A numeric scalar. Returns `NA_real_` when the input is
#'   empty, when it is entirely `NA`, or when `na.rm = FALSE` and
#'   any element is `NA`. Returns `NaN` with a warning when `x`
#'   contains negative values, or when all weights are zero.
#' @export
#'
#' @examples
#' # Unweighted
#' geomean(c(1, 4, 16))                # 4
#' geomean(c(0.6, 0.8, 0.95))          # ~0.772 — typical UHC tracer aggregation
#' geomean(c(1, NA, 4))                # 2
#' geomean(c(1, NA, 4), na.rm = FALSE) # NA_real_
#' geomean(c(1, 0, 4))                 # 0
#'
#' # Weighted
#' geomean(c(1, 4, 16), w = c(1, 1, 1))     # 4 (equal weights = unweighted)
#' geomean(c(1, 4, 16), w = c(1, 2, 1))     # weighted toward 4
#' geomean(c(0.6, 0.8, 0.95), w = c(2, 1, 1))

geomean <- function(x, w = NULL, na.rm = TRUE) {
  # ── Input validation ──────────────────────────────────────────
  if (is.logical(x)) {
    x <- as.numeric(x)
  }
  if (!is.numeric(x)) {
    cli::cli_abort("{.arg x} must be numeric or logical, not {.cls {class(x)}}.")
  }
  if (!isTRUE(na.rm) && !isFALSE(na.rm)) {
    cli::cli_abort("{.arg na.rm} must be a single logical value.")
  }
  
  weighted <- !is.null(w)
  
  if (weighted) {
    if (!is.numeric(w)) {
      cli::cli_abort("{.arg w} must be numeric, not {.cls {class(w)}}.")
    }
    if (length(x) != length(w)) {
      cli::cli_abort(
        "{.arg x} and {.arg w} must have the same length \\
        ({length(x)} vs {length(w)})."
      )
    }
  }
  
  # ── NA filtering ──────────────────────────────────────────────
  if (na.rm) {
    ok <- if (weighted) !is.na(x) & !is.na(w) else !is.na(x)
    x <- x[ok]
    if (weighted) w <- w[ok]
  }
  
  # ── Empty / remaining NA handling ─────────────────────────────
  if (length(x) == 0L) return(NA_real_)
  if (anyNA(x)) return(NA_real_)
  if (weighted && anyNA(w)) return(NA_real_)
  
  # ── Weight-specific checks ────────────────────────────────────
  if (weighted) {
    if (any(w < 0)) {
      cli::cli_abort("{.arg w} must be non-negative.")
    }
    if (sum(w) == 0) {
      cli::cli_warn(
        "All weights are zero; weighted geometric mean is undefined."
      )
      return(NaN)
    }
  }
  
  # ── Domain checks on x ────────────────────────────────────────
  if (any(x < 0)) {
    cli::cli_warn(
      "Negative values in {.arg x}; geometric mean is undefined."
    )
    return(NaN)
  }
  if (any(x == 0)) return(0)
  
  # ── Compute ───────────────────────────────────────────────────
  if (weighted) {
    exp(stats::weighted.mean(log(x), w))
  } else {
    exp(mean(log(x)))
  }
}