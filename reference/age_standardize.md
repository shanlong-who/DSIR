# Directly Age-Standardized Rate

Computes a directly age-standardized rate: the rate that would be
observed in a population with the age structure of a chosen standard.
Direct standardization removes the effect of differing age
distributions, so rates from different populations (countries, sexes,
time periods) become comparable.

## Usage

``` r
age_standardize(
  count,
  pop,
  stdpop,
  per = 1e+05,
  ci = FALSE,
  conf_level = 0.95,
  na.rm = TRUE
)
```

## Arguments

- count:

  Numeric vector of event counts (e.g. deaths) per age group.

- pop:

  Numeric vector of population denominators per age group, the same
  length as `count`. Must be positive.

- stdpop:

  Numeric vector of standard-population weights per age group, the same
  length as `count`. Relative values only; normalized internally. Pass
  `who_std_pop$std_million` (or `$weight`) for the WHO World Standard,
  aggregated to your age groups.

- per:

  Numeric. The rate is expressed per this many people. Default `1e5`
  (per 100,000). Use `1` for a proportion, `1000` for per-mille.

- ci:

  Logical. Return a confidence interval (Fay-Feuer gamma method)?
  Default `FALSE`.

- conf_level:

  Numeric in (0, 1). Confidence level for the interval. Default `0.95`.

- na.rm:

  Logical. Drop age groups with a missing `count`, `pop`, or `stdpop`
  before computing? Default `TRUE`. When `FALSE`, any missing value
  makes the result `NA`.

## Value

When `ci = FALSE`, a numeric scalar: the standardized rate per `per`.
When `ci = TRUE`, a named numeric vector with elements `rate`, `lower`,
and `upper`, all per `per`. Returns `NA` (scalar or in each element)
with a warning when no age groups remain after `NA` handling.

## Details

The age-specific rate in group \\i\\ is \\r_i = d_i / n_i\\
(`count / pop`). With standard weights \\w_i\\ (from `stdpop`,
normalized to sum to 1), the standardized rate is \$\$R = \left(\sum_i
w_i r_i\right) \times \mathrm{per}.\$\$ The three vectors `count`,
`pop`, and `stdpop` must be aligned: element \\i\\ of each refers to the
same age group, in the same order. `stdpop` may be supplied as counts, a
standard million, or percentages — only its relative values matter,
because it is normalized internally. The built-in
[who_std_pop](https://shanlong-who.github.io/DSIR/reference/who_std_pop.md)
dataset supplies the WHO World Standard.

**Confidence interval.** With `ci = TRUE`, a confidence interval is
returned using the gamma-distribution method of Fay and Feuer (1997),
which has good coverage even when rates are based on small numbers of
events. This is the method used by, for example, `epitools`. The
interval requires the age-specific event counts, so it is only available
when `count` and `pop` are supplied (not a pre-computed rate).

## References

Ahmad OB, Boschi-Pinto C, Lopez AD, Murray CJL, Lozano R, Inoue M
(2001). *Age standardization of rates: a new WHO standard.* GPE
Discussion Paper Series No. 31. World Health Organization.

Fay MP, Feuer EJ (1997). Confidence intervals for directly standardized
rates: a method based on the gamma distribution. *Statistics in
Medicine* 16(7):791-801.

## See also

[who_std_pop](https://shanlong-who.github.io/DSIR/reference/who_std_pop.md)
for the WHO World Standard Population;
[`geomean()`](https://shanlong-who.github.io/DSIR/reference/geomean.md)
for ratio-based aggregation.

## Examples

``` r
# Deaths and population in five age groups, standardized to the WHO
# World Standard collapsed to the same five groups.
deaths <- c(20, 15, 40, 90, 220)
pop    <- c(12000, 11000, 9000, 7000, 3000)
w      <- c(0.35, 0.25, 0.20, 0.12, 0.08)   # standard weights

age_standardize(deaths, pop, w)             # per 100,000
#> [1] 922.2655
age_standardize(deaths, pop, w, per = 1000) # per 1,000
#> [1] 9.222655

# With a 95% confidence interval
age_standardize(deaths, pop, w, ci = TRUE)
#>      rate     lower     upper 
#>  922.2655  831.1569 1021.1368 

# Using the bundled WHO World Standard for standard five-year groups.
# Aggregate who_std_pop to whatever age groups your data use, keeping
# the same order, then pass the weights:
std5 <- who_std_pop$std_million[1:5]
age_standardize(deaths, pop, std5)
#> [1] 1812.645
```
