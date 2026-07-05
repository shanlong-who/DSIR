# Common indicator codes

Codes below were verified against the live catalogs on 2026-07-05. For
anything not listed, search the catalog — do not guess codes:

```r
DSIR::gho_indicators(search = "measles")       # matches IndicatorName
DSIR::sdg_indicators(search = "suicide")       # matches description
```

## GHO indicator codes (verified)

| Code | Indicator |
|---|---|
| `WHOSIS_000001` | Life expectancy at birth (years) |
| `WHOSIS_000002` | Healthy life expectancy (HALE) at birth (years) |
| `WHOSIS_000003` | Neonatal mortality rate (per 1000 live births) |
| `MDG_0000000001` | Infant mortality rate (per 1000 live births) |
| `MDG_0000000007` | Under-five mortality rate (per 1000 live births) |
| `MDG_0000000026` | Maternal mortality ratio (per 100 000 live births) |
| `NCDMORT3070` | Probability (%) of dying between 30 and 70 from CVD, cancer, diabetes, or CRD |
| `UHC_INDEX_REPORTED` | UHC Service Coverage Index (SDG 3.8.1) |
| `WHS4_100` | DTP3 immunization coverage among 1-year-olds (%) |
| `WHS4_544` | Polio (Pol3) immunization coverage among 1-year-olds (%) — note: Pol3, **not** measles |
| `M_Est_smk_curr_std` | Current tobacco smoking prevalence (%), age-standardized |

## GHO dimension values

Most mortality/life-expectancy indicators break down by sex in `Dim1`.
The codes are **prefixed**:

- `SEX_BTSX` (both sexes), `SEX_MLE` (male), `SEX_FMLE` (female)
- A bare `BTSX` silently returns 0 rows — the scripts auto-prefix the
  three bare sex codes, but nothing else.

Other indicators use other Dim1 domains (age groups, wealth quintiles).
List the values actually present before filtering:

```r
DSIR::gho_dimensions("NCDMORT3070", "Dim1")
```

## SDG indicator codes

`sdg_data()` takes the indicator code (e.g. `"3.4.1"`). One indicator
usually returns **several series** (different measures / units); the
series code lands in the `series` column after `sdg_clean()`. Common
health-related indicators:

| Indicator | Topic |
|---|---|
| `3.1.1` | Maternal mortality ratio |
| `3.2.1` | Under-five mortality rate |
| `3.2.2` | Neonatal mortality rate |
| `3.4.1` | Mortality from NCDs (e.g. series `SH_DTH_NCD` = number of deaths) |
| `3.4.2` | Suicide mortality rate |
| `3.8.1` | UHC service coverage index |
| `1.1.1` | International poverty (large pull — always filter by `area`) |

Use `sdg_coverage("3.4.1", area = "PHL")` (or
`scripts/check_availability.R --sdg 3.4.1 --area PHL`) to see which
series exist before pulling, and filter the cleaned data to one
`series` before computing AARR — SDG series also carry sub-dimensions
(sex, age) that the 15-column schema does not extract, so a single
series can still contain multiple observations per year. The
`aarr_note` column in `aarr_summary.csv` flags this.

## GHO vs SDG for the same indicator

Many indicators exist in both databases (U5MR, MMR, UHC index). Values
can differ slightly (estimation rounds, revision cycles). For WHO
deliverables prefer the GHO figure; pull SDG when the user needs the
official SDG-monitoring series or non-WHO areas (regional aggregates,
"World").
