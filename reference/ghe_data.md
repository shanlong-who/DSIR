# Fetch WHO Global Health Estimates

Retrieves current GHE estimates from `DEX_CMS/GHE_FULL` on the public
production xMart host, without credentials. Returns one row per selected
measure and country/year/sex/age/cause combination. Filters run
server-side.

## Usage

``` r
ghe_data(
  area = NULL,
  year = NULL,
  year_from = NULL,
  year_to = NULL,
  sex = NULL,
  age = NULL,
  cause = NULL,
  measure = NULL
)
```

## Arguments

- area:

  ISO3 country/area codes. See
  [`ghe_dimensions()`](https://shanlong-who.github.io/DSIR/reference/ghe_dimensions.md).

- year:

  Integer years; mutually exclusive with a year range.

- year_from, year_to:

  Inclusive scalar year bounds.

- sex:

  Exact codes, e.g. `"TOTAL"`, `"FEMALE"`, `"MALE"`.

- age:

  Exact age codes, e.g. `"TOTAL"`, `"Y40T44"`, `"Y_GE85"`. Totals and
  overlapping age groups must not be summed together.

- cause:

  Exact cause codes from
  [`ghe_causes()`](https://shanlong-who.github.io/DSIR/reference/ghe_causes.md),
  numeric or character. Code `0` is all causes. Hierarchy totals overlap
  with their components.

- measure:

  Codes from
  [`ghe_dimensions()`](https://shanlong-who.github.io/DSIR/reference/ghe_dimensions.md)
  with `dimension = "measure"`: `deaths`, `death_rate`, `yll`,
  `yll_rate`, `yld`, `yld_rate`, `daly`, `daly_rate`, `deaths_percent`,
  `yld_percent`, `daly_percent`. `NULL` returns all supported measures,
  including missing values.

## Value

A tibble with `iso3`, `location_name`, `year`, `sex`, `age`,
`cause_code`, `cause_name`, `measure`, `value`, `low`, `high`,
`population`, `unit`, `level`, `cause_group`, and `rankable`. A
`who_provenance` attribute records the backend, table and retrieval.

## Details

Supply at least one filter. Queries over 1,000,000 source rows warn and
return no rows; narrow the selection or explicitly set
`options(DSIR.who_max_rows = ...)`. This limit applies before pivoting
measures. Completeness is checked across pages; failed or incomplete
downloads return an empty tibble with a warning. No legacy fallback
occurs.

Counts have published lower/upper bounds where available. The API does
not expose bounds for rates or percentages; those remain `NA` and are
not derived from population. Counts are persons or years, not thousands.
Rates are age-specific or all-age crude rates as selected, not newly
age-standardized rates. Published GHE vintages can revise earlier years.

## Retrieval metadata

Downloads and directories retain their existing classes and columns.
`dsir_metadata(x)$sources` records the actual backend, endpoint, UTC
`retrieved_at`, retrieval status, cache use, source record count,
reported API version and release. Unknown versions and times remain
`NA`. Each source row includes its own server query. `query` records the
public selection, including local filters and reference-country/year
restrictions. `result` describes the function's original return;
`current` is computed from the supplied object. Source counts precede
local filtering and GHE measure pivoting, so they can differ from
returned row counts.

Result status distinguishes `success`, `empty`, `failed`, `incomplete`,
`invalid`, `partial` and `unverified`. Completeness concerns the
requested retrieval, not global indicator coverage. It is `NA` when the
response lacks sufficient completeness information. A successful HTTP
response alone does not establish completeness of an observation
download.

Cached records retain their original retrieval time and set `cache_hit`.
A historical fallback uses `retrieval_status = "bundled_snapshot"` and
retains the original collection date. It does not prove live
availability. Failed SDG list requests still return `NULL` with a
warning; `NULL` cannot carry metadata. Other empty failure results
record no successful retrieval time. Existing WHO `who_provenance` and
`catalog_snapshot` attributes remain available for compatibility.

Cleaners preserve acquisition metadata even for empty input. This is
independent of `keep_metadata`, which controls optional data columns.
[`as_dsir_data()`](https://shanlong-who.github.io/DSIR/reference/as_dsir_data.md)
also retains `sources`, `query` and `result`. These are historical
acquisition records, not an audit of arbitrary changes to a plain
tibble. Use the S3 object's processing status to track supported
transformations. [`saveRDS()`](https://rdrr.io/r/base/readRDS.html)
preserves attributes; CSV does not.

## See also

[`ghe_causes()`](https://shanlong-who.github.io/DSIR/reference/ghe_causes.md),
[`ghe_dimensions()`](https://shanlong-who.github.io/DSIR/reference/ghe_dimensions.md),
[`ghe_coverage()`](https://shanlong-who.github.io/DSIR/reference/ghe_coverage.md),
[`ghe_clean()`](https://shanlong-who.github.io/DSIR/reference/ghe_clean.md),
[`snapshot()`](https://shanlong-who.github.io/DSIR/reference/snapshot.md)

## Examples

``` r
# \donttest{
ghe_data(area = 'PHL', year = 2023, age = 'TOTAL', sex = 'TOTAL',
         cause = 0, measure = 'deaths')
ghe_data(area = 'PHL', year = 2023, age = 'Y40T44',
         sex = c('FEMALE', 'MALE'), cause = 0, measure = 'death_rate')
# }
```
