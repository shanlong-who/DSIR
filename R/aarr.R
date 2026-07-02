#' Average Annual Rate of Reduction (AARR)
#'
#' Computes the average annual rate of reduction of an indicator over
#' time — the standard WHO / UNICEF metric for tracking progress in
#' declining indicators such as maternal, neonatal, and under-five
#' mortality, stunting prevalence, or premature NCD mortality.
#'
#' @details
#' Two estimation methods are offered:
#'
#' * `"regression"` (default; the UNICEF-recommended approach): an
#'   ordinary least-squares line is fitted to `log(value)` against
#'   `year`, and the AARR is `1 - exp(b)`, where `b` is the fitted
#'   slope. All observations contribute, so the estimate is robust to
#'   noise in individual years.
#' * `"endpoint"`: only the earliest and latest years are used:
#'   `1 - (v1 / v0) ^ (1 / (y1 - y0))`, where `v0` and `v1` are the
#'   values at the earliest year `y0` and the latest year `y1`.
#'   Intermediate observations are ignored. If several observations
#'   share the earliest or latest year, their mean is used (but see
#'   the note on duplicated years below).
#'
#' **Sign convention.** A *positive* AARR means the indicator is
#' *declining* (progress, for a mortality-type indicator): `0.024`
#' means an average decline of 2.4% per year. A *negative* AARR means
#' the indicator is increasing. Note this is the reverse of a growth
#' rate.
#'
#' **Duplicated years** usually mean the data still mix several strata
#' — for example both sexes plus male / female in `dim1`, or several
#' `series` codes in data cleaned by [gho_clean()] / [sdg_clean()].
#' `aarr()` warns and proceeds (the regression pools the strata), but
#' you almost always want to filter to a single stratum first.
#'
#' **Relation to published figures.** Published WHO / UNICEF tables
#' print the AARR as a percentage (`4.4` meaning 4.4% per year);
#' multiply the value returned by this function by 100 to compare.
#' Note also that WHO's *Trends in Maternal Mortality* reports print a
#' continuous-time rate, `-log(v1 / v0) / (y1 - y0)` (there called
#' ARR), which agrees closely but not exactly with the discrete AARR
#' computed here — small differences from those tables are expected.
#'
#' @param year Numeric vector of years.
#' @param value Numeric vector of indicator values, the same length as
#'   `year`. Values must be positive (the computation is on the log
#'   scale); any zero or negative value yields `NA_real_` with a
#'   warning.
#' @param method Character. `"regression"` (default) or `"endpoint"`.
#'   See Details.
#' @param na.rm Logical. Should pairs with a missing `year` or `value`
#'   be removed before computation? Default `TRUE`. When `FALSE`, any
#'   missing element makes the result `NA_real_`.
#'
#' @return A numeric scalar: the average annual rate of reduction as a
#'   *fraction* (`0.024` = 2.4% per year). Multiply by 100 to compare
#'   with published WHO / UNICEF tables, which print percentages.
#'   Returns `NA_real_` (with a warning) when fewer than two distinct
#'   years remain after `NA` handling, when any value is zero or
#'   negative, or when `year` or `value` contains non-finite values.
#' @seealso [geomean()] for ratio-based indicator aggregation.
#' @export
#'
#' @examples
#' # A perfectly exponential 2.4%/yr decline recovers exactly 0.024
#' years  <- 2000:2015
#' values <- 100 * (1 - 0.024) ^ (years - 2000)
#' aarr(years, values)                       # 0.024
#' 100 * aarr(years, values)                 # 2.4 — as printed in reports
#'
#' # Endpoint method uses only the earliest and latest years
#' aarr(years, values, method = "endpoint")  # also 0.024 here
#'
#' # An increasing indicator gives a negative AARR
#' aarr(2010:2020, 50 * 1.01 ^ (0:10))       # about -0.01
#'
#' # Back-of-envelope projection to 2030 at the observed AARR
#' r <- aarr(years, values)
#' values[length(values)] * (1 - r) ^ (2030 - 2015)
aarr <- function(year, value, method = c("regression", "endpoint"),
                 na.rm = TRUE) {
  # ── Input validation ──────────────────────────────────────────
  method <- match.arg(method)
  if (!is.numeric(year)) {
    cli::cli_abort("{.arg year} must be numeric, not {.cls {class(year)}}.")
  }
  if (!is.numeric(value)) {
    cli::cli_abort("{.arg value} must be numeric, not {.cls {class(value)}}.")
  }
  if (length(year) != length(value)) {
    cli::cli_abort(
      "{.arg year} and {.arg value} must have the same length \\
      ({length(year)} vs {length(value)})."
    )
  }
  if (!isTRUE(na.rm) && !isFALSE(na.rm)) {
    cli::cli_abort("{.arg na.rm} must be a single logical value.")
  }

  # ── NA filtering ──────────────────────────────────────────────
  if (na.rm) {
    ok <- !is.na(year) & !is.na(value)
    year  <- year[ok]
    value <- value[ok]
  }
  if (anyNA(year) || anyNA(value)) return(NA_real_)

  # ── Domain checks ─────────────────────────────────────────────
  # NA and NaN are handled above, so this catches infinite values,
  # which would otherwise abort inside stats::lm().
  if (!all(is.finite(year)) || !all(is.finite(value))) {
    cli::cli_warn(
      "Non-finite values in {.arg year} or {.arg value}; the AARR is \\
      undefined."
    )
    return(NA_real_)
  }
  if (length(unique(year)) < 2L) {
    cli::cli_warn(
      "At least two distinct years are needed to compute the AARR."
    )
    return(NA_real_)
  }
  if (any(value <= 0)) {
    cli::cli_warn(
      "Zero or negative values in {.arg value}; the AARR is undefined \\
      on the log scale."
    )
    return(NA_real_)
  }
  if (anyDuplicated(year)) {
    cli::cli_warn(c(
      "Duplicated years in {.arg year}.",
      "i" = "This usually means the data still mix several strata \\
      (e.g. {.field dim1} or {.field series}); filter to a single \\
      stratum first."
    ))
  }

  # ── Compute ───────────────────────────────────────────────────
  if (method == "regression") {
    b <- stats::coef(stats::lm(log(value) ~ year))[["year"]]
    return(1 - exp(b))
  }

  # method == "endpoint"
  y0 <- min(year)
  y1 <- max(year)
  v0 <- mean(value[year == y0])
  v1 <- mean(value[year == y1])
  1 - (v1 / v0) ^ (1 / (y1 - y0))
}
