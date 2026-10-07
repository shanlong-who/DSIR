# WHO xMart and Global Health Estimates

DSIR 0.11.0 keeps the legacy GHO OData service as its compatibility
default and supports WHO’s public production xMart service through
`backend = 'xmart'`. GHE always uses xMart. Downloads never switch
providers after a failure. Network examples below are shown without
running during vignette builds.

## Discover GHO codes and preserve named dimensions

``` r

gho_indicators('mortality', backend = 'xmart')
gho_dimensions('NCDMORT3070', 'DIM_SEX', backend = 'xmart')
ncd <- gho_data('NCDMORT3070', area = 'PHL', year_from = 2020,
                year_to = 2021, dimensions = list(DIM_SEX = 'TOTAL'),
                backend = 'xmart')
gho_clean(ncd, keep_dimensions = TRUE, keep_metadata = TRUE)
```

The public directory identifies a published route and indicator
identifier. Wide tables store named dimensions and numeric measure
families; long tables store explicit dimension type/member pairs. DSIR
maps both into its familiar raw columns.
[`gho_clean()`](https://shanlong-who.github.io/DSIR/reference/gho_clean.md)
keeps 15 columns by default. Optional named fields preserve category
meaning; optional metadata preserves units and a row-level `provider`
column. Raw GHO observations record `Provider` and a `who_provenance`
attribute. Missing labels are resolved with the recorded backend, even
if the session option has changed. Unknown imported origins remain `NA`.
Positions can differ from legacy `Dim1`-`Dim3`. Prefer named filters.

The xMart directory and old catalog cover different codes and
publication vintages. An unknown code warns; it is never replaced by a
similar code. All six GHO query functions accept `backend`. An explicit
argument overrides `DSIR.who_backend` without changing that option; an
unset option uses legacy. Use the same backend for code discovery,
dimensions, counts, coverage and data.

``` r

financial <- gho_data('FINANCIALHARDSHIP_PROPORTIONOFPOP', area = 'PHL',
                       backend = 'legacy')
gho_clean(financial, keep_dimensions = TRUE, keep_metadata = TRUE)

# Optional session default; explicit arguments still take precedence.
options(DSIR.who_backend = 'xmart')
gho_indicators('mortality', backend = 'legacy')
```

Successful empty observation selections give an informational message.
[`gho_has_data()`](https://shanlong-who.github.io/DSIR/reference/gho_has_data.md)
returns `FALSE` and
[`gho_count()`](https://shanlong-who.github.io/DSIR/reference/gho_count.md)
returns `0L` in that case. Requests or parsing failures warn and return
empty tables or `NA`. An unknown xMart directory code warns. Legacy HTTP
404 responses trigger a small directory check before an indicator is
reported absent. A failed directory check cannot establish absence.
There is no automatic fallback.

## Discover GHE selections

``` r

ghe_dimensions('year')
ghe_dimensions('area')
ghe_dimensions('sex')
ghe_dimensions('age')
ghe_dimensions('measure')
ghe_causes('diabetes')
ghe_causes('stroke')
```

Official year and sex references are small. Geography uses all-cause,
all-age, both-sex observations in the latest year. Age and cause lists
use a small slice for the first available WHO Member State in ISO3
order. This avoids expensive whole-database grouping. These are
discovery lists;
[`ghe_coverage()`](https://shanlong-who.github.io/DSIR/reference/ghe_coverage.md)
verifies the actual selection. Some observed age codes have no label in
the published age reference; their labels remain missing.

Cause `level`, `cause_group`, `rankable` and `single_cause` come from
the provider. It publishes no parent-code field; group codes are not
parents. Do not sum a hierarchy total together with its descendants.

## Download selected measures

``` r

phl_deaths <- ghe_data('PHL', year = 2023, age = 'TOTAL', sex = 'TOTAL',
                       cause = 0, measure = 'deaths')
phl_rates <- ghe_data('PHL', year = 2023, age = 'Y40T44',
                      sex = c('FEMALE', 'MALE'), cause = 0,
                      measure = 'death_rate')
ghe_coverage('PHL', age = 'TOTAL', sex = 'TOTAL', cause = 0)
ghe_clean(phl_rates, keep_dimensions = TRUE)
```

Counts are deaths or years, rates are per 100,000, and shares are
percentages. Counts retain published uncertainty bounds. The API
supplies no rate/share bounds: missing bounds are not filled by
calculation. `TOTAL` age rates are crude; a selected five-year group
gives an age-specific rate. Age aggregates can overlap: do not add every
returned age group to obtain a total.

`measure = NULL` returns all supported measures as separate rows. The
source-row count therefore differs from the length of the long result.
Coverage counts source observations. All-null filters are rejected; more
than one million source rows require narrower filters or an explicit
`DSIR.who_max_rows` setting. Large filters use a text-body POST
internally.

## Reproducible pulls and revised estimates

``` r

phl <- snapshot(
  ghe_data('PHL', year = 2023, age = 'TOTAL', sex = 'TOTAL', cause = 0,
            measure = 'deaths'),
  'data/phl_ghe_2023.rds'
)
attr(phl, 'who_provenance')
```

Reference caches expire after ten minutes and remain in memory.
[`snapshot()`](https://shanlong-who.github.io/DSIR/reference/snapshot.md)
writes only to the path you choose. GHE releases can revise earlier
years; the 2023 estimates published by WHO in 2026 are not automatically
comparable with the older 2021 release. DSIR uses `DEX_CMS/GHE_FULL`,
not the older `GHE_FULL_FOCUS` or `GHE_FULL_DD` views.

## WHO 2026 standard population

Beginning with DSIR 0.11.0, `who_std_pop` uses the WHO 2026 Standard
Population. The official table has 18 groups through `85+`. Its rounded
percentages sum to 100.02, so DSIR normalizes them to 100. `std_million`
is a proportional numeric count scaled to one million, derived without
integer rounding.

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
count <- seq_len(nrow(who_std_pop))
population <- rep(10000, nrow(who_std_pop))
age_standardize(count, population, who_std_pop$weight)
#> [1] 79.68206
```

The former object is replaced. Aggregate observed ages to the published
groups before using its weights; no finer split of `0-4` or `85+` is
supplied. Source: [WHO/HSA/DDA/GHE/2026.4, Table 1, page
6](https://cdn.who.int/media/docs/default-source/gho-documents/global-health-estimates/ghe2023_who_standard_population.pdf).
