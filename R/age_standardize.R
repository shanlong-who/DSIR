#' Directly Age-Standardized Rate
#'
#' Computes a directly age-standardized rate: the rate that would be
#' observed in a population with the age structure of a chosen standard.
#' Direct standardization removes the effect of differing age
#' distributions, so rates from different populations (countries, sexes,
#' time periods) become comparable.
#'
#' @details
#' The age-specific rate in group \eqn{i} is \eqn{r_i = d_i / n_i}
#' (`count / pop`). With standard weights \eqn{w_i} (from `stdpop`,
#' normalized to sum to 1), the standardized rate is
#' \deqn{R = \left(\sum_i w_i r_i\right) \times \mathrm{per}.}
#' The three vectors `count`, `pop`, and `stdpop` must be aligned: element
#' \eqn{i} of each refers to the same age group, in the same order.
#' `stdpop` may be supplied as counts, a standard million, or percentages
#' — only its relative values matter, because it is normalized internally.
#' The built-in [who_std_pop] dataset supplies the WHO World Standard.
#'
#' **Confidence interval.** With `ci = TRUE`, a confidence interval is
#' returned using the gamma-distribution method of Fay and Feuer (1997),
#' which has good coverage even when rates are based on small numbers of
#' events. This is the method used by, for example, `epitools`. The
#' interval requires the age-specific event counts, so it is only
#' available when `count` and `pop` are supplied (not a pre-computed
#' rate).
#'
#' @param count Numeric vector of event counts (e.g. deaths) per age
#'   group.
#' @param pop Numeric vector of population denominators per age group, the
#'   same length as `count`. Must be positive.
#' @param stdpop Numeric vector of standard-population weights per age
#'   group, the same length as `count`. Relative values only; normalized
#'   internally. Pass `who_std_pop$std_million` (or `$weight`) for the WHO
#'   World Standard, aggregated to your age groups.
#' @param per Numeric. The rate is expressed per this many people. Default
#'   `1e5` (per 100,000). Use `1` for a proportion, `1000` for per-mille.
#' @param ci Logical. Return a confidence interval (Fay-Feuer gamma
#'   method)? Default `FALSE`.
#' @param conf_level Numeric in (0, 1). Confidence level for the interval.
#'   Default `0.95`.
#' @param na.rm Logical. Drop age groups with a missing `count`, `pop`, or
#'   `stdpop` before computing? Default `TRUE`. When `FALSE`, any missing
#'   value makes the result `NA`.
#'
#' @return When `ci = FALSE`, a numeric scalar: the standardized rate per
#'   `per`. When `ci = TRUE`, a named numeric vector with elements
#'   `rate`, `lower`, and `upper`, all per `per`. Returns `NA` (scalar or
#'   in each element) with a warning when no age groups remain after `NA`
#'   handling.
#' @references
#' Ahmad OB, Boschi-Pinto C, Lopez AD, Murray CJL, Lozano R, Inoue M
#' (2001). *Age standardization of rates: a new WHO standard.* GPE
#' Discussion Paper Series No. 31. World Health Organization.
#'
#' Fay MP, Feuer EJ (1997). Confidence intervals for directly
#' standardized rates: a method based on the gamma distribution.
#' *Statistics in Medicine* 16(7):791-801.
#' @seealso [who_std_pop] for the WHO World Standard Population;
#'   [geomean()] for ratio-based aggregation.
#' @export
#'
#' @examples
#' # Deaths and population in five age groups, standardized to the WHO
#' # World Standard collapsed to the same five groups.
#' deaths <- c(20, 15, 40, 90, 220)
#' pop    <- c(12000, 11000, 9000, 7000, 3000)
#' w      <- c(0.35, 0.25, 0.20, 0.12, 0.08)   # standard weights
#'
#' age_standardize(deaths, pop, w)             # per 100,000
#' age_standardize(deaths, pop, w, per = 1000) # per 1,000
#'
#' # With a 95% confidence interval
#' age_standardize(deaths, pop, w, ci = TRUE)
#'
#' # Using the bundled WHO World Standard for standard five-year groups.
#' # Aggregate who_std_pop to whatever age groups your data use, keeping
#' # the same order, then pass the weights:
#' std5 <- who_std_pop$std_million[1:5]
#' age_standardize(deaths, pop, std5)
age_standardize <- function(count, pop, stdpop, per = 1e5,
                            ci = FALSE, conf_level = 0.95, na.rm = TRUE) {
  # ── Input validation ──────────────────────────────────────────
  for (nm in c("count", "pop", "stdpop")) {
    x <- get(nm)
    if (!is.numeric(x)) {
      cli::cli_abort("{.arg {nm}} must be numeric, not {.cls {class(x)}}.")
    }
  }
  n <- length(count)
  if (length(pop) != n || length(stdpop) != n) {
    cli::cli_abort(
      "{.arg count}, {.arg pop}, and {.arg stdpop} must have the same \\
      length ({length(count)}, {length(pop)}, {length(stdpop)})."
    )
  }
  if (!isTRUE(na.rm) && !isFALSE(na.rm)) {
    cli::cli_abort("{.arg na.rm} must be a single logical value.")
  }
  if (!isTRUE(ci) && !isFALSE(ci)) {
    cli::cli_abort("{.arg ci} must be a single logical value.")
  }
  if (!is.numeric(per) || length(per) != 1L || !is.finite(per) || per <= 0) {
    cli::cli_abort("{.arg per} must be a single positive number.")
  }
  if (!is.numeric(conf_level) || length(conf_level) != 1L ||
      conf_level <= 0 || conf_level >= 1) {
    cli::cli_abort("{.arg conf_level} must be a single number in (0, 1).")
  }

  # ── NA filtering ──────────────────────────────────────────────
  if (na.rm) {
    ok     <- !is.na(count) & !is.na(pop) & !is.na(stdpop)
    count  <- count[ok]
    pop    <- pop[ok]
    stdpop <- stdpop[ok]
  }
  empty_result <- if (ci) c(rate = NA_real_, lower = NA_real_, upper = NA_real_) else NA_real_
  if (length(count) == 0L) {
    cli::cli_warn("No age groups remain; the standardized rate is undefined.")
    return(empty_result)
  }
  if (anyNA(count) || anyNA(pop) || anyNA(stdpop)) return(empty_result)

  # ── Domain checks ─────────────────────────────────────────────
  if (any(pop <= 0)) {
    cli::cli_abort("{.arg pop} must be positive in every age group.")
  }
  if (any(count < 0)) {
    cli::cli_abort("{.arg count} must be non-negative.")
  }
  if (any(stdpop < 0)) {
    cli::cli_abort("{.arg stdpop} must be non-negative.")
  }
  if (sum(stdpop) == 0) {
    cli::cli_warn("All standard weights are zero; the rate is undefined.")
    return(empty_result)
  }

  # ── Compute ───────────────────────────────────────────────────
  rate  <- count / pop
  w     <- stdpop / sum(stdpop)
  dsr   <- sum(w * rate)

  if (!ci) {
    return(dsr * per)
  }

  # Fay-Feuer (1997) gamma-distribution confidence interval.
  alpha   <- 1 - conf_level
  dsr_var <- sum(w^2 * count / pop^2)
  if (dsr == 0 || dsr_var == 0) {
    # A degenerate variance (e.g. zero events) leaves the gamma method
    # undefined; report the point estimate without a usable interval.
    cli::cli_warn(
      "Zero events or zero variance; the confidence interval is undefined."
    )
    return(c(rate = dsr * per, lower = NA_real_, upper = NA_real_))
  }
  wm    <- max(w / pop)
  lower <- dsr_var / dsr * stats::qgamma(alpha / 2, shape = dsr^2 / dsr_var)
  upper <- (dsr_var + wm^2) / (dsr + wm) *
    stats::qgamma(1 - alpha / 2, shape = (dsr + wm)^2 / (dsr_var + wm^2))

  c(rate = dsr * per, lower = lower * per, upper = upper * per)
}
