# Average Annual Rate of Reduction (AARR)

Computes the average annual rate of reduction of an indicator over time
— the standard WHO / UNICEF metric for tracking progress in declining
indicators such as maternal, neonatal, and under-five mortality,
stunting prevalence, or premature NCD mortality.

## Usage

``` r
aarr(year, value, method = c("regression", "endpoint"), na.rm = TRUE)
```

## Arguments

- year:

  Numeric vector of years.

- value:

  Numeric vector of indicator values, the same length as `year`. Values
  must be positive (the computation is on the log scale); any zero or
  negative value yields `NA_real_` with a warning.

- method:

  Character. `"regression"` (default) or `"endpoint"`. See Details.

- na.rm:

  Logical. Should pairs with a missing `year` or `value` be removed
  before computation? Default `TRUE`. When `FALSE`, any missing element
  makes the result `NA_real_`.

## Value

A numeric scalar: the average annual rate of reduction as a *fraction*
(`0.024` = 2.4% per year). Multiply by 100 to compare with published WHO
/ UNICEF tables, which print percentages. Returns `NA_real_` (with a
warning) when fewer than two distinct years remain after `NA` handling,
when any value is zero or negative, or when `year` or `value` contains
non-finite values.

## Details

Two estimation methods are offered:

- `"regression"` (default; the UNICEF-recommended approach): an ordinary
  least-squares line is fitted to `log(value)` against `year`, and the
  AARR is `1 - exp(b)`, where `b` is the fitted slope. All observations
  contribute, so the estimate is robust to noise in individual years.

- `"endpoint"`: only the earliest and latest years are used:
  `1 - (v1 / v0) ^ (1 / (y1 - y0))`, where `v0` and `v1` are the values
  at the earliest year `y0` and the latest year `y1`. Intermediate
  observations are ignored. If several observations share the earliest
  or latest year, their mean is used (but see the note on duplicated
  years below).

**Sign convention.** A *positive* AARR means the indicator is
*declining* (progress, for a mortality-type indicator): `0.024` means an
average decline of 2.4% per year. A *negative* AARR means the indicator
is increasing. Note this is the reverse of a growth rate.

**Duplicated years** usually mean the data still mix several strata —
for example both sexes plus male / female in `dim1`, or several `series`
codes in data cleaned by
[`gho_clean()`](https://shanlong-who.github.io/DSIR/reference/gho_clean.md)
/
[`sdg_clean()`](https://shanlong-who.github.io/DSIR/reference/sdg_clean.md).
`aarr()` warns and proceeds (the regression pools the strata), but you
almost always want to filter to a single stratum first.

**Relation to published figures.** Published WHO / UNICEF tables print
the AARR as a percentage (`4.4` meaning 4.4% per year); multiply the
value returned by this function by 100 to compare. Note also that WHO's
*Trends in Maternal Mortality* reports print a continuous-time rate,
`-log(v1 / v0) / (y1 - y0)` (there called ARR), which agrees closely but
not exactly with the discrete AARR computed here — small differences
from those tables are expected.

## See also

[`geomean()`](https://shanlong-who.github.io/DSIR/reference/geomean.md)
for ratio-based indicator aggregation.

## Examples

``` r
# A perfectly exponential 2.4%/yr decline recovers exactly 0.024
years  <- 2000:2015
values <- 100 * (1 - 0.024) ^ (years - 2000)
aarr(years, values)                       # 0.024
#> [1] 0.024
100 * aarr(years, values)                 # 2.4 — as printed in reports
#> [1] 2.4

# Endpoint method uses only the earliest and latest years
aarr(years, values, method = "endpoint")  # also 0.024 here
#> [1] 0.024

# An increasing indicator gives a negative AARR
aarr(2010:2020, 50 * 1.01 ^ (0:10))       # about -0.01
#> [1] -0.01

# Back-of-envelope projection to 2030 at the observed AARR
r <- aarr(years, values)
values[length(values)] * (1 - r) ^ (2030 - 2015)
#> [1] 48.24969
```
