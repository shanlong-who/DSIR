# Period Life Table from Age-Specific Mortality Rates

Builds a standard period life table from age-specific mortality rates
(nMx). Works with both abridged tables (age groups
`0, 1, 5, 10, ..., 85+`) and complete single-year tables
(`0, 1, 2, ..., 100+`); the last age group is always treated as
open-ended.

## Usage

``` r
life_table(
  age,
  mx,
  sex = c("total", "male", "female"),
  ax = NULL,
  radix = 1e+05
)
```

## Arguments

- age:

  Numeric vector of age-group lower bounds, strictly increasing, e.g.
  `c(0, 1, seq(5, 85, by = 5))` for a standard abridged table. The last
  group is open-ended.

- mx:

  Numeric vector of age-specific mortality rates (deaths per
  person-year), the same length as `age`. Must be non-negative, with no
  missing values.

- sex:

  Character. `"total"` (default), `"male"`, or `"female"`. Only used for
  the default infant and child `ax` (see Details).

- ax:

  Optional numeric vector overriding the default person-years
  assumptions, the same length as `age`. `NA` elements fall back to the
  defaults.

- radix:

  Numeric. The starting cohort size `l0`. Default `100000`; use `1` for
  survivorship proportions.

## Value

A tibble with one row per age group and columns:

- age:

  Age-group lower bound (as supplied).

- n:

  Width of the age interval; `Inf` for the open interval.

- mx:

  Age-specific mortality rate (as supplied).

- ax:

  Average person-years lived in the interval by those dying in it.

- qx:

  Probability of dying in the interval; 1 in the open interval.

- lx:

  Survivors at exact age `x` out of `radix`.

- dx:

  Deaths in the interval.

- Lx:

  Person-years lived in the interval.

- Tx:

  Person-years lived above exact age `x`.

- ex:

  Remaining life expectancy at exact age `x`. `NA` where `lx` has
  reached 0.

## Details

The conversion from the mortality rate `mx` to the probability of dying
`qx` uses the standard relation \$\${}\_nq_x = \frac{n \\ {}\_nm_x}{1 +
(n - {}\_na_x) \\ {}\_nm_x},\$\$ where \\{}\_na_x\\ is the average
number of person-years lived in the interval by those dying in it.
Values of `qx` are capped at 1 (with a warning, since capping signals
implausibly high rates). In the open interval, `qx = 1` and
`Lx = lx / mx`.

**The `ax` assumption.** By default:

- age 0 (when the first group is age 0 with width 1): the Coale-Demeny
  West formulas keyed on `m0` (Preston, Heuveline and Guillot 2001,
  Table 3.3), by `sex`. For `sex = "total"`, the male and female values
  are averaged.

- ages 1-4 (when the second group is ages 1-4): the corresponding
  Coale-Demeny West formula.

- all other closed intervals: `n / 2` (the midpoint assumption).

- open interval: `1 / mx` (the life expectancy implied by a constant
  rate).

Pass your own `ax` vector to override all of this, e.g. to match a
published table exactly.

Life expectancy at any tabulated age is read off the `ex` column:
`ex[1]` is life expectancy at birth when the table starts at age 0. The
table may also start above age 0 (e.g. `age = c(60, 65, ..., 85)`) to
compute remaining life expectancy conditional on survival to the first
age.

## References

Preston SH, Heuveline P, Guillot M (2001). *Demography: Measuring and
Modeling Population Processes.* Blackwell, Oxford. Chapter 3.

Coale AJ, Demeny P, Vaughan B (1983). *Regional Model Life Tables and
Stable Populations.* 2nd ed. Academic Press, New York.

## See also

[`age_standardize()`](https://shanlong-who.github.io/DSIR/reference/age_standardize.md)
for age-standardized rates;
[`aarr()`](https://shanlong-who.github.io/DSIR/reference/aarr.md) for
indicator progress tracking.

## Examples

``` r
# Abridged life table for a typical middle-income mortality schedule
age <- c(0, 1, seq(5, 85, by = 5))
mx  <- c(0.0200, 0.0010, 0.0004, 0.0003, 0.0005, 0.0007, 0.0009,
         0.0012, 0.0016, 0.0022, 0.0032, 0.0048, 0.0075, 0.0120,
         0.0190, 0.0310, 0.0520, 0.0860, 0.1500)
lt <- life_table(age, mx)
lt

# Life expectancy at birth and at age 60
lt$ex[1]
lt$ex[lt$age == 60]

# Sex-specific infant ax (affects e0 slightly)
life_table(age, mx, sex = "female")$ex[1]

# Survivorship proportions instead of a 100,000 radix
life_table(age, mx, radix = 1)$lx
```
