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
#> # A tibble: 19 × 10
#>      age     n     mx    ax      qx      lx     dx      Lx       Tx    ex
#>    <dbl> <dbl>  <dbl> <dbl>   <dbl>   <dbl>  <dbl>   <dbl>    <dbl> <dbl>
#>  1     0     1 0.02   0.104 0.0196  100000   1965.  98239. 7563915. 75.6 
#>  2     1     4 0.001  1.54  0.00399  98035.   391. 391180. 7465676. 76.2 
#>  3     5     5 0.0004 2.5   0.00200  97644.   195. 487732. 7074496. 72.5 
#>  4    10     5 0.0003 2.5   0.00150  97449.   146. 486880. 6586764. 67.6 
#>  5    15     5 0.0005 2.5   0.00250  97303.   243. 485907. 6099884. 62.7 
#>  6    20     5 0.0007 2.5   0.00349  97060.   339. 484452. 5613977. 57.8 
#>  7    25     5 0.0009 2.5   0.00449  96721.   434. 482518. 5129525. 53.0 
#>  8    30     5 0.0012 2.5   0.00598  96287.   576. 479993. 4647007. 48.3 
#>  9    35     5 0.0016 2.5   0.00797  95711.   763. 476646. 4167014. 43.5 
#> 10    40     5 0.0022 2.5   0.0109   94948.  1039. 472143. 3690368. 38.9 
#> 11    45     5 0.0032 2.5   0.0159   93909.  1491. 465819. 3218225. 34.3 
#> 12    50     5 0.0048 2.5   0.0237   92419.  2192. 456614. 2752406. 29.8 
#> 13    55     5 0.0075 2.5   0.0368   90227.  3321. 442831. 2295792. 25.4 
#> 14    60     5 0.012  2.5   0.0583   86906.  5062. 421872. 1852961. 21.3 
#> 15    65     5 0.019  2.5   0.0907   81843.  7423. 390659. 1431089. 17.5 
#> 16    70     5 0.031  2.5   0.144    74421. 10706. 345339. 1040430. 14.0 
#> 17    75     5 0.052  2.5   0.230    63715. 14660. 281925.  695091. 10.9 
#> 18    80     5 0.086  2.5   0.354    49055. 17361. 201872.  413165.  8.42
#> 19    85   Inf 0.15   6.67  1        31694. 31694. 211293.  211293.  6.67

# Life expectancy at birth and at age 60
lt$ex[1]
#> [1] 75.63915
lt$ex[lt$age == 60]
#> [1] 21.32154

# Sex-specific infant ax (affects e0 slightly)
life_table(age, mx, sex = "female")$ex[1]
#> [1] 75.63891

# Survivorship proportions instead of a 100,000 radix
life_table(age, mx, radix = 1)$lx
#>  [1] 1.0000000 0.9803522 0.9764404 0.9744894 0.9730288 0.9705993 0.9672081
#>  [8] 0.9628654 0.9571055 0.9494792 0.9390920 0.9241858 0.9022684 0.8690560
#> [15] 0.8184314 0.7442061 0.6371509 0.4905498 0.3169396
```
