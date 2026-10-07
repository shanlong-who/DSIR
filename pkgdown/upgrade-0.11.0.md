# DSIR 0.11.0 technical upgrade report

Prepared for Shanlong Ding. Investigation date: 2026-10-06.
This is the release candidate prepared for GitHub publication. No CRAN
submission or GitHub release was made.

Backend selection was revised on 2026-10-07 before any 0.11.0 CRAN release.
GHO now retains the legacy compatibility default, supports per-call `backend`
arguments, and records row-level provider metadata. GHE remains on xMart.
The provider/schema comparisons below retain their original investigation date.

## A. Main files

| Area | Files |
|---|---|
| Shared WHO transport and configuration | `R/who_backend.R` |
| GHO provider adapters | `R/who_gho.R`, `R/who_legacy.R`, `R/gho.R` |
| Separate GHE module | `R/ghe.R` |
| Cleaning and binding | `R/clean_metadata.R`, `R/clean_schema.R`, `R/bind_indicators.R` |
| WHO standard population | `data-raw/who_std_pop.R`, `data/who_std_pop.rda`, `R/data.R`, `R/age_standardize.R` |
| Reproducible API inspection | `data-raw/verify_who_backend.R` |
| Offline regression tests | `tests/testthat/test-who-xmart.R`, `test-ghe.R`, `helper-who-mock.R`, `test-who_std_pop.R`, existing GHO/standardization tests |
| Package documentation | `DESCRIPTION`, `NEWS.md`, `README.md`, `R/DSIR-package.R`, generated `NAMESPACE` and `man/` |
| Vignettes and website source | `vignettes/ghe-xmart.Rmd`, `vignettes/DSIR.Rmd`, `_pkgdown.yml` |
| Maintained development guidance | `AGENTS.md`, `.github/maintenance/design-notes.md` |
| Release preparation | `cran-comments.md`, `inst/CITATION`, `inst/WORDLIST` |

The previously modified `CRAN-SUBMISSION` file was preserved. It records the
earlier 0.10.0 submission; it is not evidence of a 0.11.0 submission.
The author remains Shanlong Ding only. No dependencies were added.

## B. Production API investigation

The verified public origin is `https://xmart-api-public.who.int`.
Named marts, their object lists and their `/$metadata` endpoints work without
credentials. The bare host root is not a useful discovery URL.

Official documentation:
[WHO xMart API](https://extranet.who.int/xmart4/docs/xmart_api/use_API.html),
[World Health Data Hub infrastructure](https://data.who.int/about/data/whdh/xmart).
Production XML and selected JSON responses were inspected directly, rather than
assuming the example schemas or UAT hosts in documentation were current.

### GHO

`DATA_/IND_DIRECTORY_WIDE`, filtered to English, supplies the official catalog
and download routes. The observed directory has 1,053 rows and 927 distinct,
nonempty GHO codes. Perspective rows can repeat a code. Routes are taken from
`DWNL_QUERY`, then `IND_PUBLISH_TABLE`. Only the mart/object path is extracted;
private, UAT or misspelled directory hostnames are never followed.

There is no single fact object for every indicator. The verified examples use
`DATA_/RELAY_WHS` (wide measure families) and `DATA_/RELAY_GHO` (long type/member
pairs). Other official `RELAY_*` routes are resolved through the same adapter,
subject to supported schemas and public access. They were not all downloaded.

| Concept | xMart source | Canonical GHO field |
|---|---|---|
| Indicator download identifier | Directory `IND_ID` | `IndicatorCode` remains the requested public GHO code |
| Label and unit | `IND_NAME_FULL`, fallback `IND_NAME`; `IND_UNIT` | `IndicatorName`, `Unit` |
| Geography | `DIM_GEO_CODE_M49` + `REF_GEO.GEO_CODE_ISO_3` | `SpatialDim` |
| Geography type | `DIM_GEO_CODE_TYPE` | `SpatialDimType`; original retained separately |
| Time | `DIM_TIME`, `DIM_TIME_TYPE` | Integer `TimeDim`, `TimeDimType`, unmodified `TimeDimensionValue` |
| Sex/age and other wide dimensions | Named `DIM_*` columns | Canonical positions plus all named source columns |
| Long dimensions | `DIM_n_CODE` + `DIM_MEMBER_n_CODE` | Row-specific dimension types and members, including positions beyond three |
| Wide estimates and bounds | Active `*_N`, matching `*_NL`, `*_NU` family | `NumericValue`, `Low`, `High` |
| Long estimates and bounds | `VALUE_NUMERIC`, `VALUE_NUMERIC_LOWER`, `VALUE_NUMERIC_UPPER` | `NumericValue`, `Low`, `High` |
| Display value | `VALUE_LABEL` | `Value`, with numeric text only when the display value is missing |
| Observation identity/update | `_RecordID`, `Sys_CommitDateUtc` | `Id`, `Date` |

Wide rows with more than one active numeric family are rejected as ambiguous.
Values and uncertainty limits are not rounded or recomputed.

The WHO regional codes are mapped to the verified reference groups 953-958;
`GLOBAL` maps to `001`. WHO Africa (953) must not be confused with UN Africa
(002), which has the same short name. Source `WHOREGION` becomes canonical
`REGION`; optional metadata retains the original type.

Verified sex families include `DIM_SEX` (`TOTAL`, `MALE`, `FEMALE`) and
`DIM_POP_SEX` (`BTSX`, `MLE`, `FMLE`). Both map to legacy `SEX_*` codes in the
canonical positions. `DIM_AGE` and `DIM_POP_AGE_GRP` retain native named values
and map to the canonical `AGEGROUP_` namespace. Other types are retained without
guessing their meaning. Named filters use native field/type names and codes.

### GHE

The backend is `DEX_CMS/GHE_FULL`, a separate GHE data product.

| Object | Observed years/rows | Observed dimensions and suitability |
|---|---|---|
| `GHE_FULL` | 2000-2023; 65,511,072 source rows | 183 areas, 24 years, 22 age codes, 3 sexes, 226 causes; selected for current longitudinal research |
| `GHE_FULL_FOCUS` | 2021 only; 2,596,770 rows | 183 areas; 22 ages and 3 sexes verified in a Philippine slice; 215 causes in its Philippine all-age/both-sex slice; older single-year product |
| `GHE_FULL_DD` | 2021 only in year discovery | Additional death/ranking display fields and differently typed codes; not selected |

The name `FOCUS` alone was not used to infer that it was a visualization subset.
Its older year coverage and code system were verified. Current `GHE_FULL` uses
`TOTAL/FEMALE/MALE` and SDMX-style age codes; the older focus view uses
`BTSX/FMLE/MLE`, `ALLAges`, and `YEARS...` ages. These vintages are not combined.
The current row count equals the product of discovered dimension sizes; the
entire 65-million-row table was not downloaded to verify every cell.

Current age codes are `TOTAL`, `D0T27`, `M1T11`, `Y0T1`, `Y1T4`, the five-year
groups `Y5T9` through `Y80T84`, and `Y_GE85`. The official age reference gives
20 labels. `D0T27` and `M1T11` occur in facts but have no labels in that reference;
their labels remain `NA`.

Year and sex discovery use `REF_YEAR_COD` and `REF_SEX_COD`. Area discovery uses
latest-year/all-cause/all-age/both-sex facts. Age and cause discovery use small
slices for the first available WHO Member State in ISO3 order (currently AFG).
These discovery lists describe the latest release, not historical completeness.

| Friendly measure | Provider field | Unit/bounds |
|---|---|---|
| `deaths` | `VAL_DTHS_COUNT_NUMERIC` | Deaths; `VAL_DTHS_COUNT_LOW/HIGH` |
| `death_rate` | `VAL_DTHS_RATE100K_NUMERIC` | Per 100,000; no published bounds |
| `yll`, `yld`, `daly` | `VAL_YLL/YLD/DALY_COUNT_NUMERIC` | Years; corresponding count bounds |
| `yll_rate`, `yld_rate`, `daly_rate` | `VAL_YLL/YLD/DALY_RATE100K_NUMERIC` | Per 100,000; no published bounds |
| `deaths_percent`, `yld_percent`, `daly_percent` | `VAL_PROP_DTHS/YLD/DALY_PERCENT` | Percent; no published bounds |

The supported set is intersected with the actual provider fields. Counts are
not thousands. Rates for `TOTAL` age are crude rates, not new age-standardized
rates. Missing rate/share uncertainty limits are not derived from population.

Cause fields include code, title, `FLAG_LEVEL`, `DIM_CAUSE_GROUP`,
`FLAG_RANKABLE`, and `FLAG_SINGLE_CAUSE`. No parent-code field was found.
`cause_group` is therefore not presented as a parent identifier. Hierarchy
totals and their components overlap and must not be added indiscriminately.

Current release context:
[WHO Global Health Estimates](https://www.who.int/data/gho/data/themes/mortality-and-global-health-estimates/ghe-leading-causes-of-death).

### Request contract and limits

Production tests confirmed `$top`, `$skip`, `$count`, CSV responses and
read-only POST `/$query` with a `text/plain` query-string body. JSON requests
have a documented 120,000-row cap. CSV supports streaming with different limits;
DSIR deliberately uses validated JSON paging rather than treating CSV as a
single unlimited download.

Ordinary downloads sort by `Sys_PK`, request 5,000 rows per page, verify the
declared count across all pages, reject repeated identifiers/pages and discard
incomplete results. The default one-million-source-row guard applies before
GHE measures are pivoted. Count/existence requests transfer at most one row.
Long encoded queries use POST above 1,800 bytes.

Observed production limits are six `$orderby` clauses and a 100-node filter
expression. Compact `in` lists support regional vectors; long-table type
discovery is batched into at most six ordering fields. A large OR expression
for `wpro_cty` was rejected; the compact equivalent returned 252 UHC rows.

Grouped `@odata.count` can count underlying facts instead of returned groups.
Grouped downloads therefore use bounded short-page completion and stable
ordering rather than trusting that count. Small references require a short
page and valid schema. Expensive full-GHE grouping is avoided.

xMart may cache identical query URLs until its publication cycle refreshes
(documented delay up to 60 minutes). DSIR reference caches expire after ten
minutes, are scoped to provider/origin, and remain in memory. No startup
requests, API keys or automatic disk writes are introduced.

## C. Public API

New functions:

```r
ghe_data(area = NULL, year = NULL, year_from = NULL, year_to = NULL,
         sex = NULL, age = NULL, cause = NULL, measure = NULL)
ghe_causes(search = NULL)
ghe_dimensions(dimension = "measure")
ghe_coverage(area = NULL, year = NULL, year_from = NULL, year_to = NULL,
             sex = NULL, age = NULL, cause = NULL)
ghe_clean(df, keep_dimensions = FALSE)
```

`ghe_data()` returns 16 named columns and one row per selected measure.
`ghe_coverage()` counts source observations before measure expansion.
Unfiltered full-database requests are rejected. Download codes are exact;
name searching is confined to catalog functions.

The existing GHO argument order remains intact. `dimensions = NULL` adds named
filters to the four observation queries. `backend = NULL` is appended to all
six query functions, including `gho_indicators(search = NULL, backend = NULL)`
and `gho_dimensions(indicator, dimension = "SpatialDimType", backend = NULL)`.
`gho_clean(df, keep_dimensions = FALSE, keep_metadata = FALSE)` is unchanged.

```r
gho_data(indicator, spatial_type = NULL, area = NULL,
         year_from = NULL, year_to = NULL, dim1 = NULL,
         dim2 = NULL, dim3 = NULL, dimensions = NULL, backend = NULL)
gho_has_data(indicator, spatial_type = NULL, area = NULL,
             year_from = NULL, year_to = NULL, dim1 = NULL,
             dim2 = NULL, dim3 = NULL, dimensions = NULL, backend = NULL)
gho_count(indicator, spatial_type = NULL, area = NULL,
          year_from = NULL, year_to = NULL, dim1 = NULL,
          dim2 = NULL, dim3 = NULL, dimensions = NULL, backend = NULL)
gho_coverage(indicator, spatial_type = "country", area = NULL,
             year_from = NULL, year_to = NULL, dim1 = NULL,
             dim2 = NULL, dim3 = NULL, dimensions = NULL, backend = NULL)
```

All six GHO query functions accept `backend = "legacy"` or `"xmart"`.
Selection follows: explicit argument, then `DSIR.who_backend`, then `"legacy"`.
Per-call selection never changes session options. Other advanced options are
`DSIR.who_base_url` (xMart HTTPS origin), `DSIR.who_page_size` and `DSIR.who_max_rows`.
GHE always uses xMart. Failed xMart queries never switch providers.

## D. Compatibility

The default cleaned schema remains:

```text
source id indicator location iso3 location_name year value value_num low high series dim1 dim2 dim3
```

`ghe_clean()` uses `source = "ghe"`, cause code as `id`, measure as `series`,
sex as `dim1` and age as `dim2`. Optional named context, units, population and
hierarchy fields are retained by `bind_indicators()`. Binding does not harmonize
source definitions or dimension codes. Keep source pulls/snapshots when
provenance from multiple downloads must be retained; binding is not a provenance
merger.

Validated calls include three-country/two-year GHO selections, native named
sex filters, legacy positional sex/age filters on wide and long tables, WHO
region/world queries, dimension discovery, and the 28-area `wpro_cty` UHC pull.

Intentional changes:

- The optional xMart provider has directory coverage, published precision and
  estimates that can differ from legacy; legacy remains the default.
- Wide-table positions follow source schema, ordered by sex, age, then other
  names; they need not match every legacy indicator's positions. Prefer named
  filters. Long tables preserve explicit row-specific positions.
- `keep_dimensions = TRUE` adds meaningful native `dim_*` columns; metadata
  adds units, measure field, raw time, source geography type, row-level `provider`
  and provenance. Raw `Provider` columns survive combining raw observations.
  Cleaner label lookups use recorded origin, even after session options change.
- `who_std_pop` has 18 rows instead of 21, and `std_million` is double instead
  of integer. Existing analyses must align age groups again.

`FINANCIALHARDSHIP_PROPORTIONOFPOP` was absent from the public English directory
and the checked GHO/WHS fact selections. It uses legacy by default; an explicit
`backend = "legacy"` also works when the session default is xMart.
No substitute is guessed.

## E. WHO 2026 standard population

Source: [WHO technical report](https://cdn.who.int/media/docs/default-source/gho-documents/global-health-estimates/ghe2023_who_standard_population.pdf),
WHO/HSA/DDA/GHE/2026.4, September 2026, Table 1, page 6. Accessed 2026-10-06.
It uses projected world population for 2026-2050 based on WPP 2024.

Beginning with DSIR 0.11.0, `who_std_pop` uses the WHO 2026 Standard Population.
It contains `0-4`, successive five-year groups, and `85+`: 18 groups total.
Published percentages sum to 100.02 because of rounding. DSIR stores:

| Column | Type/meaning |
|---|---|
| `age_group` | Character age label |
| `age_start` | Integer lower boundary |
| `weight` | Published percentage divided by 100.02 and multiplied by 100 |
| `std_million` | Published percentage divided by 100.02 and multiplied by 1,000,000 |

The stored sums are 100 and 1,000,000 within floating-point tolerance.
The standard million is a proportional derived quantity, not a separate
published WHO integer table. Raw published percentages are preserved in the
rebuild script. No split of `0-4` or `85+` is invented; no old population object
is exported or retained in the current package.

`age_standardize()` needs no implementation or signature change: `stdpop` was
already a required argument, with no implicit dataset default. Supplying
`who_std_pop$weight` or `$std_million` now uses the revised standard. Count,
population and standard vectors must be aligned. For GHE, neonatal/sub-infant
ages overlap with the under-one total and must not be double-counted when
forming the `0-4` observed group.

## F. Validation

The initial offline baseline had 808 passing assertions. The final suite spans
281 test blocks in 35 files and has 953 passing assertions, no failures,
no test warnings or errors, and 29 skips. The skipped cases require explicit
live-test opt-in; separate live validation was performed as described below.

Offline regression scope includes exact query filters and quoting, long POST,
query limits, stable paging, changing counts, duplicate/empty/malformed pages,
typed empty results, no fallback, scoped caching, GHO wide/long mappings,
named and legacy dimensions, geography aliases, GHE measures/units/bounds,
cause and dimension validation, coverage, schema binding, and the new standard
population. Live tests require `DSIR_RUN_LIVE_TESTS=true` and skip on CRAN.
Network vignette examples require separate explicit opt-in.

Live evidence saved under `scratch/upgrade_0110/`:

- Philippine 2023 all-age/both-sex/all-cause deaths: one row with valid bounds.
- Philippine 2023 `Y40T44` death rates for female/male: two rows with missing
  rate bounds, as published.
- All 11 measures for Philippine 2023 all-age/both-sex/all-cause facts. Each
  of the four published rates equals count / population * 100,000 rounded
  to two decimal places; unrounded differences are at most 0.004680.
- Philippine all-cause/all-age/both-sex coverage: 2000-2023, 24 source rows.
- Philippine 2023 all-sex/all-age/all-cause-code death selections: 14,916 rows,
  three validated pages.
- Diabetes/stroke cause searches and 22 observed age codes.
- Wide and long GHO selections, named filters, legacy aliases, region/world
  selections, and the 252-row regional UHC example.

Legacy/xMart parity matched canonical geography/year/sex/age keys:

| Indicator/selection | Rows in each provider | Matched | Value differences | Largest absolute value difference |
|---|---:|---:|---:|---:|
| `NCDMORT3070`, FRA/JPN/PHL, 2020-2021 | 18 | 18 | 0 | 0 |
| `WHOSIS_000001`, same selection | 18 | 18 | 18 | 0.808969 years |
| `MDG_0000000001`, same selection | 18 | 18 | 18 | 0.104890 |
| `NCD_BMI_18C`, PHL, 2020-2021 | 6 | 6 | 6 | 0.342987 percentage points |

NCDMORT bounds also agreed exactly. Life-expectancy maximum lower/upper
differences were 1.020664/0.618293; infant mortality 0.313967/0.297104;
BMI 1.140638/1.023136. Matching age namespaces fixed adapter-key mismatches.
The remaining differences are present in the provider payloads. One-decimal
rounding did not remove all life-expectancy/infant-mortality differences.
The first three xMart fact update timestamps were 2026-05-18, versus legacy
timestamps 2024-12-18, 2026-10-01 and 2026-08-04 respectively. Update timestamps
do not prove a particular estimation revision or publication vintage.
DSIR does not change values to force parity.

The initial native installation crash also occurred for unmodified DSIR 0.9.0
and a minimal package importing `rlang`. A dependency-only session completed
its work but crashed on exit. The tool process lacked Windows
`PROCESSOR_ARCHITECTURE`; supplying the verified `AMD64` architecture fixed
normal shutdown and installation. This setting is confined to the validation
process, with no global R configuration or package workaround.
The [cli thread source](https://github.com/r-lib/cli/blob/main/src/thread.c)
explains its use of this environment variable during shutdown.

Final validation on 2026-10-06 used R 4.6.1 (2026-06-24 ucrt), Windows 11 x64
(build 22631), roxygen2 8.1.0 and Pandoc 3.10:

| Validation | Result |
|---|---|
| `devtools::document()` | Completed; generated namespace and help files are current |
| `devtools::test()` | 953 passing assertions; 0 failures/errors/warnings; 29 skips |
| Standard `devtools::check(cran = FALSE)` | 0 errors, 0 warnings, 0 notes |
| `devtools::check(cran = FALSE, args = "--as-cran", remote = TRUE, incoming = TRUE)` | 0 errors, 0 warnings, 1 note |
| Normal examples, tests, vignette checks and vignette rebuilds | Passed in both check runs |
| Network examples under `--run-donttest` | Passed in the `--as-cran` run (231 seconds) |

The only `--as-cran` note is the CRAN incoming feasibility message
`Days since last update: 5`. It reflects release frequency, rather than a
code or documentation finding. Incoming and remote checks were enabled;
the note was not suppressed. Both runs use devtools' default `--no-manual`;
PDF-manual compilation was not checked.

Reproducible validation files include `final_validation.R`,
`final_test_counts.csv`, `final_tests.rds`, `check_standard.rds`,
`check_as_cran.rds`, `final_standard/DSIR.Rcheck/00check.log`,
`final_as_cran/DSIR.Rcheck/00check.log`, `validate_rates.R` and
`rate_units.csv`, all under `scratch/upgrade_0110/`. Research scripts,
selected source responses, live-example results and parity tables are saved
there as development evidence and excluded from the package build.

## G. Remaining limits

1. The public directory is not a replacement catalog for every legacy GHO
   code. Financial-hardship coverage remains a confirmed gap. Other routed
   products and their publication perspectives need indicator-specific QA.
2. Estimates and uncertainty bounds can differ across providers. Backend and
   retrieval provenance must accompany reproducible comparisons.
3. Two GHE age labels are absent from the official reference; no labels or
   cause-parent relationships are fabricated.
4. Latest-year GHE discovery slices are practical code lists, not a guarantee
   that every code is available in every historical selection. Verify coverage.
5. Server-side data can change between requests. Counts and stable identifiers
   detect many incomplete downloads, but the API provides no immutable snapshot
   token. A same-count revision during paging cannot be ruled out entirely.
6. Local Windows checks do not replace Linux/macOS, R-devel/win-builder or
   reverse-dependency checks. CRAN submission and GitHub release creation
   were not performed.
7. The current `--as-cran` incoming note flags only five days since the previous
   CRAN update. Review release timing before a later submission.
