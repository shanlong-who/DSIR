#' Geometric Mean
#'
#' Computes the geometric mean of a numeric vector. Useful for
#' aggregating multiplicative quantities such as ratio-based health
#' indicators (e.g. UHC service-coverage tracers, where the composite
#' index is the geometric mean of component coverage values).
#'
#' @param x A numeric vector. Zeros produce a result of `0`.
#'   Negative values produce `NaN` with a warning, since the
#'   geometric mean is undefined for negative numbers.
#' @param na.rm Logical. Should missing values be removed before
#'   computation? Default `TRUE`.
#'
#' @return A numeric scalar. Returns `NA_real_` when the input is
#'   empty, when it is entirely `NA`, or when `na.rm = FALSE` and
#'   any element is `NA`.
#' @export
#'
#' @examples
#' geomean(c(1, 4, 16))                # 4
#' geomean(c(0.6, 0.8, 0.95))          # ~0.772 — typical UHC tracer aggregation
#' geomean(c(1, NA, 4))                # 2
#' geomean(c(1, NA, 4), na.rm = FALSE) # NA_real_
#' geomean(c(1, 0, 4))                 # 0
geomean <- function(x, na.rm = TRUE) {
  if (!is.numeric(x)) {
    cli::cli_abort("{.arg x} must be numeric, not {.cls {class(x)}}.")
  }
  if (!isTRUE(na.rm) && !isFALSE(na.rm)) {
    cli::cli_abort("{.arg na.rm} must be a single logical value.")
  }

  if (na.rm) x <- x[!is.na(x)]
  if (length(x) == 0L) return(NA_real_)
  if (anyNA(x))        return(NA_real_)
  if (any(x < 0)) {
    cli::cli_warn("Negative values in {.arg x}; geometric mean is undefined.")
    return(NaN)
  }
  if (any(x == 0)) return(0)

  exp(mean(log(x)))
}
