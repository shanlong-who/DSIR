# WHO World Standard Population

The WHO World Standard Population (world average population 2000-2025)
of Ahmad et al. (2001), used for direct age standardization of rates so
that populations with different age structures can be compared. This is
the standard used for WHO indicators such as age-standardized NCD
mortality.

## Usage

``` r
who_std_pop
```

## Format

A tibble with 21 rows (five-year age groups `"0-4"` to `"100+"`) and 4
columns:

- age_group:

  Age-group label, e.g. `"0-4"`, `"85-89"`, `"100+"`.

- age_start:

  Integer lower bound of the age group.

- weight:

  The published WHO percentage for the age group. The published values
  sum to 100.035 (not exactly 100); this is carried verbatim from the
  source and is harmless, since weights are normalized wherever they are
  used.

- std_million:

  The SEER "standard million" form: the weight scaled to a population of
  exactly 1,000,000 (the only adjustment is the 90-94 group rounded from
  1,499.48 up to 1,500 so the total is exact).

## Source

Ahmad OB, Boschi-Pinto C, Lopez AD, Murray CJL, Lozano R, Inoue M
(2001). *Age standardization of rates: a new WHO standard.* GPE
Discussion Paper Series No. 31. World Health Organization. Cross-checked
against the SEER standard-population tables:
<https://seer.cancer.gov/stdpopulations/world.who.html>

## Details

To standardize data on coarser age groups (e.g. `0-4, 5-14, ..., 85+`),
aggregate the weights by summing `weight` (or `std_million`) over the
constituent five-year groups, then pass them to
[`age_standardize()`](https://shanlong-who.github.io/DSIR/reference/age_standardize.md).
Only relative weights matter, so either column gives identical results.

The original publication does not split ages 0 and 1-4; the finest first
group is `0-4`. Splits of the first group circulating in some registries
are downstream constructions, not part of the WHO standard.

## See also

[`age_standardize()`](https://shanlong-who.github.io/DSIR/reference/age_standardize.md),
which consumes these weights.

## Examples

``` r
who_std_pop
#> # A tibble: 21 × 4
#>    age_group age_start weight std_million
#>    <chr>         <int>  <dbl>       <int>
#>  1 0-4               0   8.86       88569
#>  2 5-9               5   8.69       86870
#>  3 10-14            10   8.6        85970
#>  4 15-19            15   8.47       84670
#>  5 20-24            20   8.22       82171
#>  6 25-29            25   7.93       79272
#>  7 30-34            30   7.61       76073
#>  8 35-39            35   7.15       71475
#>  9 40-44            40   6.59       65877
#> 10 45-49            45   6.04       60379
#> # ℹ 11 more rows

# Aggregate to broad age groups (0-24, 25-64, 65+) for coarser data
breaks <- c(0, 25, 65, Inf)
grp <- cut(who_std_pop$age_start, breaks, right = FALSE,
           labels = c("0-24", "25-64", "65+"))
tapply(who_std_pop$std_million, grp, sum)
#>   0-24  25-64    65+ 
#> 428250 489428  82322 
```
