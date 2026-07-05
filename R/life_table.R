#' Period Life Table from Age-Specific Mortality Rates
#'
#' Builds a standard period life table from age-specific mortality rates
#' (nMx). Works with both abridged tables (age groups `0, 1, 5, 10, ...,
#' 85+`) and complete single-year tables (`0, 1, 2, ..., 100+`); the last
#' age group is always treated as open-ended.
#'
#' @details
#' The conversion from the mortality rate `mx` to the probability of
#' dying `qx` uses the standard relation
#' \deqn{{}_nq_x = \frac{n \, {}_nm_x}{1 + (n - {}_na_x) \, {}_nm_x},}
#' where \eqn{{}_na_x} is the average number of person-years lived in the
#' interval by those dying in it. Values of `qx` are capped at 1 (with a
#' warning, since capping signals implausibly high rates). In the open
#' interval, `qx = 1` and `Lx = lx / mx`.
#'
#' **The `ax` assumption.** By default:
#'
#' * age 0 (when the first group is age 0 with width 1): the Coale-Demeny
#'   West formulas keyed on `m0` (Preston, Heuveline and Guillot 2001,
#'   Table 3.3), by `sex`. For `sex = "total"`, the male and female
#'   values are averaged.
#' * ages 1-4 (when the second group is ages 1-4): the corresponding
#'   Coale-Demeny West formula.
#' * all other closed intervals: `n / 2` (the midpoint assumption).
#' * open interval: `1 / mx` (the life expectancy implied by a constant
#'   rate).
#'
#' Pass your own `ax` vector to override all of this, e.g. to match a
#' published table exactly.
#'
#' Life expectancy at any tabulated age is read off the `ex` column:
#' `ex[1]` is life expectancy at birth when the table starts at age 0.
#' The table may also start above age 0 (e.g. `age = c(60, 65, ..., 85)`)
#' to compute remaining life expectancy conditional on survival to the
#' first age.
#'
#' @param age Numeric vector of age-group lower bounds, strictly
#'   increasing, e.g. `c(0, 1, seq(5, 85, by = 5))` for a standard
#'   abridged table. The last group is open-ended.
#' @param mx Numeric vector of age-specific mortality rates (deaths per
#'   person-year), the same length as `age`. Must be non-negative, with
#'   no missing values.
#' @param sex Character. `"total"` (default), `"male"`, or `"female"`.
#'   Only used for the default infant and child `ax` (see Details).
#' @param ax Optional numeric vector overriding the default person-years
#'   assumptions, the same length as `age`. `NA` elements fall back to
#'   the defaults.
#' @param radix Numeric. The starting cohort size `l0`. Default
#'   `100000`; use `1` for survivorship proportions.
#'
#' @return A tibble with one row per age group and columns:
#' \describe{
#'   \item{age}{Age-group lower bound (as supplied).}
#'   \item{n}{Width of the age interval; `Inf` for the open interval.}
#'   \item{mx}{Age-specific mortality rate (as supplied).}
#'   \item{ax}{Average person-years lived in the interval by those dying
#'   in it.}
#'   \item{qx}{Probability of dying in the interval; 1 in the open
#'   interval.}
#'   \item{lx}{Survivors at exact age `x` out of `radix`.}
#'   \item{dx}{Deaths in the interval.}
#'   \item{Lx}{Person-years lived in the interval.}
#'   \item{Tx}{Person-years lived above exact age `x`.}
#'   \item{ex}{Remaining life expectancy at exact age `x`. `NA` where
#'   `lx` has reached 0.}
#' }
#' @references
#' Preston SH, Heuveline P, Guillot M (2001). *Demography: Measuring and
#' Modeling Population Processes.* Blackwell, Oxford. Chapter 3.
#'
#' Coale AJ, Demeny P, Vaughan B (1983). *Regional Model Life Tables and
#' Stable Populations.* 2nd ed. Academic Press, New York.
#' @seealso [age_standardize()] for age-standardized rates; [aarr()] for
#'   indicator progress tracking.
#' @export
#'
#' @examples
#' # Abridged life table for a typical middle-income mortality schedule
#' age <- c(0, 1, seq(5, 85, by = 5))
#' mx  <- c(0.0200, 0.0010, 0.0004, 0.0003, 0.0005, 0.0007, 0.0009,
#'          0.0012, 0.0016, 0.0022, 0.0032, 0.0048, 0.0075, 0.0120,
#'          0.0190, 0.0310, 0.0520, 0.0860, 0.1500)
#' lt <- life_table(age, mx)
#' lt
#'
#' # Life expectancy at birth and at age 60
#' lt$ex[1]
#' lt$ex[lt$age == 60]
#'
#' # Sex-specific infant ax (affects e0 slightly)
#' life_table(age, mx, sex = "female")$ex[1]
#'
#' # Survivorship proportions instead of a 100,000 radix
#' life_table(age, mx, radix = 1)$lx
life_table <- function(age, mx, sex = c("total", "male", "female"),
                       ax = NULL, radix = 1e5) {
  # ── Input validation ──────────────────────────────────────────
  sex <- match.arg(sex)
  if (!is.numeric(age)) {
    cli::cli_abort("{.arg age} must be numeric, not {.cls {class(age)}}.")
  }
  if (!is.numeric(mx)) {
    cli::cli_abort("{.arg mx} must be numeric, not {.cls {class(mx)}}.")
  }
  k <- length(age)
  if (length(mx) != k) {
    cli::cli_abort(
      "{.arg age} and {.arg mx} must have the same length \\
      ({k} vs {length(mx)})."
    )
  }
  if (k < 2L) {
    cli::cli_abort("At least two age groups are needed for a life table.")
  }
  if (anyNA(age) || !all(is.finite(age))) {
    cli::cli_abort("{.arg age} must not contain missing or non-finite values.")
  }
  if (any(diff(age) <= 0)) {
    cli::cli_abort("{.arg age} must be strictly increasing.")
  }
  if (anyNA(mx) || !all(is.finite(mx))) {
    cli::cli_abort(
      "{.arg mx} must not contain missing or non-finite values; a life \\
      table needs a complete mortality schedule."
    )
  }
  if (any(mx < 0)) {
    cli::cli_abort("{.arg mx} must be non-negative.")
  }
  if (!is.numeric(radix) || length(radix) != 1L || !is.finite(radix) ||
      radix <= 0) {
    cli::cli_abort("{.arg radix} must be a single positive number.")
  }
  if (!is.null(ax)) {
    if (!is.numeric(ax) || length(ax) != k) {
      cli::cli_abort(
        "{.arg ax} must be a numeric vector the same length as {.arg age} \\
        ({k})."
      )
    }
  }

  # ── Interval widths ───────────────────────────────────────────
  n <- c(diff(age), Inf)
  open <- k  # index of the open interval

  # ── Default ax ────────────────────────────────────────────────
  ax_default <- n / 2
  m0 <- mx[1]
  if (age[1] == 0 && n[1] == 1) {
    ax_default[1] <- .cd_west_a0(m0, sex)
  }
  if (age[1] == 0 && k >= 2L && age[2] == 1 && n[2] == 4) {
    ax_default[2] <- .cd_west_4a1(m0, sex)
  }
  ax_default[open] <- if (mx[open] > 0) 1 / mx[open] else NA_real_

  if (is.null(ax)) {
    ax <- ax_default
  } else {
    ax[is.na(ax)] <- ax_default[is.na(ax)]
  }

  # ── qx ────────────────────────────────────────────────────────
  qx <- n * mx / (1 + (n - ax) * mx)
  qx[open] <- 1
  capped <- which(qx[-open] > 1)
  if (length(capped) > 0L) {
    cli::cli_warn(
      "{.field qx} exceeded 1 in {length(capped)} age group{?s} and was \\
      capped; check {.arg mx} for implausibly high rates."
    )
    qx[qx > 1] <- 1
  }

  # ── lx, dx, Lx, Tx, ex ────────────────────────────────────────
  lx <- radix * cumprod(c(1, 1 - qx[-open]))
  dx <- lx * qx

  Lx <- n * (lx - dx) + ax * dx
  if (mx[open] > 0) {
    Lx[open] <- lx[open] / mx[open]
  } else {
    cli::cli_warn(
      "{.arg mx} is zero in the open interval; {.field ex} is undefined \\
      and returned as {.val NA}."
    )
    Lx[open] <- NA_real_
  }

  Tx <- rev(cumsum(rev(Lx)))
  ex <- Tx / lx
  ex[lx == 0] <- NA_real_

  tibble::tibble(
    age = age, n = n, mx = mx, ax = ax, qx = qx,
    lx = lx, dx = dx, Lx = Lx, Tx = Tx, ex = ex
  )
}


#' Coale-Demeny West a0 (average person-years lived by infants who die),
#' keyed on m0. Preston, Heuveline and Guillot (2001), Table 3.3.
#' "total" averages the male and female values.
#'
#' @noRd
.cd_west_a0 <- function(m0, sex) {
  male   <- if (m0 >= 0.107) 0.330 else 0.045 + 2.684 * m0
  female <- if (m0 >= 0.107) 0.350 else 0.053 + 2.800 * m0
  switch(sex,
    male   = male,
    female = female,
    total  = (male + female) / 2
  )
}


#' Coale-Demeny West 4a1 for ages 1-4, keyed on m0. Same source as
#' .cd_west_a0().
#'
#' @noRd
.cd_west_4a1 <- function(m0, sex) {
  male   <- if (m0 >= 0.107) 1.352 else 1.651 - 2.816 * m0
  female <- if (m0 >= 0.107) 1.361 else 1.522 - 1.518 * m0
  switch(sex,
    male   = male,
    female = female,
    total  = (male + female) / 2
  )
}
