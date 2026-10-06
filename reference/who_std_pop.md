# WHO 2026 Standard Population

Beginning with DSIR 0.11.0, `who_std_pop` uses the WHO 2026 Standard
Population, based on projected world population during 2026-2050.

## Usage

``` r
who_std_pop
```

## Format

A tibble with 18 rows: five-year groups `0-4` to `80-84`, followed by
`85+`, and four columns:

- age_group:

  Character age-group label.

- age_start:

  Integer lower bound in years.

- weight:

  Percentage normalized to sum to 100. WHO's rounded published values
  sum to 100.02: divide each by 100.02 and multiply by 100.

- std_million:

  Numeric weight scaled to sum to 1,000,000, without integer rounding.
  Derived counts, not separately published WHO counts.

## Source

World Health Organization (2026). *Revised WHO standard population for
calculating age-standardized rates*. WHO/HSA/DDA/GHE/2026.4, Table 1,
page 6. Accessed 2026-10-06.
<https://cdn.who.int/media/docs/default-source/gho-documents/global-health-estimates/ghe2023_who_standard_population.pdf>

## Details

Aggregate weights by summation for coarser age groups. Both weight
columns give identical standardized rates. The published table does not
split `0-4` or `85+`: aggregate finer observed ages to these groups. The
four column names are retained; the dataset now has 18 rather than 21
rows and `std_million` is numeric rather than integer.

## See also

[`age_standardize()`](https://shanlong-who.github.io/DSIR/reference/age_standardize.md)

## Examples

``` r
who_std_pop
#> # A tibble: 18 × 4
#>    age_group age_start weight std_million
#>    <chr>         <int>  <dbl>       <dbl>
#>  1 0-4               0   7.21      72086.
#>  2 5-9               5   7.13      71286.
#>  3 10-14            10   7.11      71086.
#>  4 15-19            15   7.12      71186.
#>  5 20-24            20   7.15      71486.
#>  6 25-29            25   7.08      70786.
#>  7 30-34            30   6.89      68886.
#>  8 35-39            35   6.66      66587.
#>  9 40-44            40   6.35      63487.
#> 10 45-49            45   6.04      60388.
#> 11 50-54            50   5.75      57489.
#> 12 55-59            55   5.41      54089.
#> 13 60-64            60   4.97      49690.
#> 14 65-69            65   4.43      44291.
#> 15 70-74            70   3.77      37692.
#> 16 75-79            75   2.98      29794.
#> 17 80-84            80   2.08      20796.
#> 18 85+              85   1.89      18896.
grp <- cut(who_std_pop$age_start, c(0, 25, 65, Inf), right = FALSE,
           labels = c('0-24', '25-64', '65+'))
tapply(who_std_pop$std_million, grp, sum)
#>     0-24    25-64      65+ 
#> 357128.6 491401.7 151469.7 
```
