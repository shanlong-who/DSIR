# DSIR

``` r

library(DSIR)
library(dplyr)
#> 
#> Attaching package: 'dplyr'
#> The following objects are masked from 'package:stats':
#> 
#>     filter, lag
#> The following objects are masked from 'package:base':
#> 
#>     intersect, setdiff, setequal, union
library(ggplot2)
```

![DSIR logo](../reference/figures/logo.jpg)

DSIR is a small R package for global health data work. It consists of
WHO Member State metadata, lightweight clients for the GHO and UN SDG
APIs, and reusable WHO-style `ggplot2` and `flextable` themes. DSIR is
designed for health professionals, WHO staff, and global health
researchers — the kind of users who do the same routine tasks every day.

This vignette walks through the typical workflow: looking up countries,
fetching data from GHO and SDG, cleaning the raw response, and producing
publication-style charts and tables.

## WHO Member State metadata

The `who_countries` tibble lists all 194 WHO Member States with their
ISO3, ISO2, UN M49 codes, official names, short names, and WHO region.
For Western Pacific countries, an extra column `is_pic` identifies the
14 Pacific Island Countries.

``` r

who_countries
#> # A tibble: 194 × 8
#>    iso3  iso2  m49_code name_official       name_short         who_region is_pic
#>    <chr> <chr> <chr>    <chr>               <chr>              <chr>      <lgl> 
#>  1 AFG   AF    004      Afghanistan         Afghanistan        EMR        FALSE 
#>  2 ALB   AL    008      Albania             Albania            EUR        FALSE 
#>  3 DZA   DZ    012      Algeria             Algeria            AFR        FALSE 
#>  4 AND   AD    020      Andorra             Andorra            EUR        FALSE 
#>  5 AGO   AO    024      Angola              Angola             AFR        FALSE 
#>  6 ATG   AG    028      Antigua and Barbuda Antigua and Barbu… AMR        FALSE 
#>  7 ARG   AR    032      Argentina           Argentina          AMR        FALSE 
#>  8 ARM   AM    051      Armenia             Armenia            EUR        FALSE 
#>  9 AUS   AU    036      Australia           Australia          WPR        FALSE 
#> 10 AUT   AT    040      Austria             Austria            EUR        FALSE 
#> # ℹ 184 more rows
#> # ℹ 1 more variable: wb_income_group <chr>
```

For convenience, DSIR offers pre-defined vectors of ISO3 codes for each
WHO region.

``` r

wpro_cty
#>  [1] "AUS" "BRN" "CHN" "COK" "FJI" "FSM" "IDN" "JPN" "KHM" "KIR" "KOR" "LAO"
#> [13] "MHL" "MNG" "MYS" "NIU" "NRU" "NZL" "PHL" "PLW" "PNG" "SGP" "SLB" "TON"
#> [25] "TUV" "VNM" "VUT" "WSM"
length(wpro_cty)   # 28 Member States in WPR (since May 2025)
#> [1] 28
```

The `is_pic` flag is useful because Pacific Island Countries are often
analysed as a group, given their distinct demographic and geographic
profiles.

``` r

who_countries |>
  filter(is_pic) |>
  select(iso3, name_short)
#> # A tibble: 14 × 2
#>    iso3  name_short      
#>    <chr> <chr>           
#>  1 COK   Cook Islands    
#>  2 FJI   Fiji            
#>  3 KIR   Kiribati        
#>  4 MHL   Marshall Islands
#>  5 FSM   Micronesia      
#>  6 NRU   Nauru           
#>  7 NIU   Niue            
#>  8 PLW   Palau           
#>  9 PNG   Papua New Guinea
#> 10 WSM   Samoa           
#> 11 SLB   Solomon Islands 
#> 12 TON   Tonga           
#> 13 TUV   Tuvalu          
#> 14 VUT   Vanuatu
```

When you have a vector of ISO3 codes and need to know which WHO region
each belongs to,
[`iso3_to_region()`](https://shanlong-who.github.io/DSIR/reference/iso3_to_region.md)
provides the lookup. It is vectorised and returns `NA` for codes that do
not match a WHO Member State.

``` r

iso3_to_region(c("PHL", "FRA", "ZAF", "USA", "XYZ"))
#> [1] "WPR" "EUR" "AFR" "AMR" NA
# "WPR" "EUR" "AFR" "AMR" NA
```

This is convenient when joining external datasets (which often arrive
keyed only by ISO3) to the WHO regional structure.

The companion helper
[`iso3_to_m49()`](https://shanlong-who.github.io/DSIR/reference/iso3_to_m49.md)
converts ISO3 codes to UN M49 numeric codes — useful because the WHO GHO
API is keyed by ISO3 (`"PHL"`) while the UN SDG API is keyed by M49
(`"608"`). The M49 values are returned as three-character zero-padded
strings, exactly as stored in `who_countries$m49_code`.

``` r

iso3_to_m49(c("PHL", "FRA", "JPN"))
#> [1] "608" "250" "392"
# "608" "250" "392"

# Case-insensitive; non-Member areas return NA
iso3_to_m49(c("phl", "PRI"))
#> [1] "608" NA
# "608" NA
```

In practice you can usually skip the explicit conversion:
[`sdg_data()`](https://shanlong-who.github.io/DSIR/reference/sdg_data.md)
and
[`sdg_coverage()`](https://shanlong-who.github.io/DSIR/reference/sdg_coverage.md)
accept ISO3 codes for their `area` argument and do the lookup internally
(see the SDG section below).

Network examples and the charts using their results are displayed
without execution during package builds. To run them when rendering this
vignette, set `DSIR_BUILD_LIVE_VIGNETTE=true` in the rendering session.

## Checking availability before fetching

The public GHO directory contains many indicators, but any single
indicator may not cover the countries or years you need. Before issuing
a full download with
[`gho_data()`](https://shanlong-who.github.io/DSIR/reference/gho_data.md),
three lightweight helpers let you ask the server what is available
without transferring any observations.

[`gho_has_data()`](https://shanlong-who.github.io/DSIR/reference/gho_has_data.md)
is a quick yes / no for a given indicator and filter — useful when
screening a list of candidate indicators.

``` r

# Does WHO have life-expectancy data for France?
gho_has_data("WHOSIS_000001", area = "FRA")
# TRUE

# Bulk-screen several indicators at once
inds <- c("WHOSIS_000001", "NCDMORT3070", "MDG_0000000026")
vapply(inds, gho_has_data, logical(1), area = "PHL")
```

It returns `TRUE`, `FALSE`, or `NA` (for request failures, including a a
code absent from the current public directory).

[`gho_count()`](https://shanlong-who.github.io/DSIR/reference/gho_count.md)
returns the number of rows the same filter would produce, which is
useful for sizing a download.

``` r

gho_count("WHOSIS_000001", area = wpro_cty)
```

[`gho_coverage()`](https://shanlong-who.github.io/DSIR/reference/gho_coverage.md)
summarises year coverage and observation counts per country. The payload
is small because only `SpatialDim` and `TimeDim` are requested from the
server.

``` r

gho_coverage("WHOSIS_000001", area = c("FRA", "DEU", "JPN"))
```

## Fetching indicator data from GHO

To fetch indicators from GHO, the typical workflow is three steps:
search for the indicator code, fetch the data, then clean the response.
The `area` argument accepts a long ISO3 vector, so a whole region can be
pulled in one call.

### Step 1: Search for an indicator

``` r

gho_indicators("UHC") |> head()
```

Pick an `IndicatorCode` from the result — this is the value you pass to
[`gho_data()`](https://shanlong-who.github.io/DSIR/reference/gho_data.md)
in the next step.

### Step 2: Fetch the data

``` r

uhc <- gho_data(
  indicator    = "UHC_INDEX_REPORTED",
  spatial_type = "country",
  area         = wpro_cty,
  year_from    = 2015
)

uhc |> glimpse()
```

Note that `area` accepts long ISO3 vectors — here we fetch all 28 WPR
countries in one call.

### Step 3: Clean the raw response

[`gho_clean()`](https://shanlong-who.github.io/DSIR/reference/gho_clean.md)
produces the **unified DSIR cleaned-indicator schema** — the same
15-column shape as
[`sdg_clean()`](https://shanlong-who.github.io/DSIR/reference/sdg_clean.md).
Columns include `source` (`"gho"`), `id`, `indicator`, `location`,
`iso3`, `location_name` (resolved for known locations), `year`, `value`,
`value_num`, `low`, `high`, `series` (resolved for known locations), and
the three optional GHO dimensions `dim1`–`dim3`. Columns absent from the
raw response are filled with typed `NA`.

``` r

uhc_clean <- gho_clean(uhc)
uhc_clean
```

## Aggregating indicators with geomean()

Some health indicators are constructed as the geometric mean of
component values rather than the arithmetic mean. The UHC Service
Coverage Index, for example, aggregates 14 tracer indicators using
nested geometric means. DSIR provides
[`geomean()`](https://shanlong-who.github.io/DSIR/reference/geomean.md)
for this:

``` r

# Unweighted geometric mean
geomean(c(0.6, 0.8, 0.95))
#> [1] 0.7697002
#> 0.7720589

# With optional weights — useful when tracers have different 
# methodological importance
geomean(c(0.6, 0.8, 0.95), w = c(2, 1, 1))
#> [1] 0.7232343
```

[`geomean()`](https://shanlong-who.github.io/DSIR/reference/geomean.md)
handles missing values, zeros, and negative values sensibly — see
[`?geomean`](https://shanlong-who.github.io/DSIR/reference/geomean.md)
for details. It is a small helper, but it removes a common source of
bugs when re-implementing index calculations from indicator components.

## Plotting with theme_dsi() and theme_dsi_facet()

DSIR provides two paired `ggplot2` themes tuned for WHO-style charts —
clean panels, modest grids, and a consistent accent colour. Use them as
drop-in replacements for
[`theme_minimal()`](https://ggplot2.tidyverse.org/reference/ggtheme.html)
and [`theme_bw()`](https://ggplot2.tidyverse.org/reference/ggtheme.html)
respectively whenever a chart is heading into a WHO deliverable.

The rule of thumb is simple: **single-panel plots use
[`theme_dsi()`](https://shanlong-who.github.io/DSIR/reference/theme_dsi.md),
faceted plots use
[`theme_dsi_facet()`](https://shanlong-who.github.io/DSIR/reference/theme_dsi_facet.md)**.
The two share typography, title treatment, and legend handling, but
differ in how they frame the data — the facet variant adds panel
borders, light strip backgrounds, and breathing room between panels, all
of which would look heavy on a single-panel chart.

### Single panel: `theme_dsi()`

[`theme_dsi()`](https://shanlong-who.github.io/DSIR/reference/theme_dsi.md)
keeps the chart chrome minimal — a half-frame axis, light grid lines,
and the WHO-blue accent on the axis line. By default the grid runs in
both directions; pass `grid = "y"` for the minimalist horizontal-only
look.

``` r

uhc_clean |>
  filter(iso3 %in% c("AUS", "CHN", "PHL", "FJI")) |>
  left_join(who_countries, by = "iso3") |>
  ggplot(aes(x = year, y = value_num, group = iso3, color = name_short)) +
  geom_line(linewidth = .8) +
  geom_point(size = 1.8) +
  theme_dsi() +
  labs(
    title    = "UHC Service Coverage Index, selected WPR Member States",
    subtitle = "2015 onwards",
    x = NULL, y = "SCI", color = NULL
  )
```

For bar charts, pair
[`theme_dsi()`](https://shanlong-who.github.io/DSIR/reference/theme_dsi.md)
with
[`scale_y_dsi_col()`](https://shanlong-who.github.io/DSIR/reference/scale_dsi_col.md)
(or
[`scale_x_dsi_col()`](https://shanlong-who.github.io/DSIR/reference/scale_dsi_col.md)
when `value` is mapped to `x`) — these are thin wrappers around
`scale_*_continuous()` that remove the lower axis expansion, so columns
sit flush with the axis instead of floating above it.

``` r

uhc_clean |>
  filter(year == max(year)) |>
  left_join(who_countries, by = "iso3") |>
  arrange(desc(value_num)) |>
  head(10) |>
  ggplot(aes(reorder(name_short, value_num), value_num)) +
  geom_col(fill = "#0093D5") +
  coord_flip() +
  scale_y_dsi_col() +
  theme_dsi(grid = "x") +
  labs(
    title    = "UHC Service Coverage Index, top 10 WPR Member States",
    subtitle = "Latest available year",
    x = NULL, y = "SCI"
  )
```

### Faceted: `theme_dsi_facet()`

When the same chart is split across many small panels, the half-frame
look becomes visually noisy — the accent-blue axis line repeats across
every facet.
[`theme_dsi_facet()`](https://shanlong-who.github.io/DSIR/reference/theme_dsi_facet.md)
switches to a full panel border, adds a light grey strip background to
clearly mark each facet’s label, and introduces panel spacing so
adjacent panels don’t run together.

``` r

uhc_clean |>
  left_join(who_countries, by = "iso3") |>
  filter(is_pic) |>
  ggplot(aes(x = year, y = value_num)) +
  geom_line(color = "#0093D5", linewidth = 0.8) +
  geom_point(color = "#0093D5", size = 1.5) +
  facet_wrap(~ name_short, ncol = 4) +
  theme_dsi_facet() +
  labs(
    title    = "UHC Service Coverage Index, Pacific Island Countries",
    subtitle = "Each panel shows one country's trajectory",
    x = NULL, y = "SCI"
  )
```

The `strip_fill` argument lets you change the strip background colour
for emphasis — for example, a light-blue tone derived from the WHO
accent for a deliverable where the strips themselves carry meaning:

``` r

uhc_clean |>
  left_join(who_countries, by = "iso3") |>
  filter(is_pic) |>
  ggplot(aes(x = year, y = value_num)) +
  geom_line(color = "#0093D5", linewidth = 0.8) +
  facet_wrap(~ name_short, ncol = 4) +
  theme_dsi_facet(strip_fill = "#E5F4FB") +
  labs(title = "UHC SCI, PIC — with custom strip colour",
       x = NULL, y = "SCI")
```

## Tables with dsi_flextable_defaults()

[`dsi_flextable_defaults()`](https://shanlong-who.github.io/DSIR/reference/dsi_flextable_defaults.md)
sets WHO-style defaults for `flextable` globally — booktabs theme, bold
headers, modest padding. Call it once near the top of your report and
every subsequent
[`flextable()`](https://davidgohel.github.io/flextable/reference/flextable.html)
picks up the formatting.

``` r

library(flextable)
dsi_flextable_defaults(font_family = "Geogria")

uhc_clean |>
  filter(year == max(year)) |>
  left_join(who_countries, by = "iso3") |>
  select(name_short, value_num) |>
  arrange(desc(value_num)) |>
  flextable() |>
  set_table_properties("autofit", width = .6) %>%
  set_caption("UHC SCI in WPR, latest year")
```

## Working with SDG indicators

[`sdg_data()`](https://shanlong-who.github.io/DSIR/reference/sdg_data.md)
and
[`sdg_clean()`](https://shanlong-who.github.io/DSIR/reference/sdg_clean.md)
follow the same fetch-then-tidy pattern as their GHO counterparts. The
main differences are that indicator codes use the dotted SDG format
(e.g. `"3.4.1"`) and that raw `value` is kept as character — the SDG API
returns non-numeric entries (`"<0.1"`, aggregate notes) for some rows.
The cleaned `value_num`, `low`, and `high` columns are numeric, with
`NA` where conversion is not possible.

[`sdg_indicators()`](https://shanlong-who.github.io/DSIR/reference/sdg_indicators.md)
accepts an optional `search` argument with the same behaviour as
[`gho_indicators()`](https://shanlong-who.github.io/DSIR/reference/gho_indicators.md)
— multiple keywords are AND-ed together and matched case-insensitively
against the indicator description. The filter runs client-side because
the UN SDG indicator list is short (~250 rows) and the endpoint is not
OData.

``` r

# All indicators that mention both mortality and cancer
sdg_indicators("mortality cancer")

# Same as above, but with explicit terms (allows whitespace inside a term)
sdg_indicators(c("maternal", "mortality"))
```

The `area` argument of
[`sdg_data()`](https://shanlong-who.github.io/DSIR/reference/sdg_data.md)
and
[`sdg_coverage()`](https://shanlong-who.github.io/DSIR/reference/sdg_coverage.md)
accepts either ISO3 codes (converted internally via
[`iso3_to_m49()`](https://shanlong-who.github.io/DSIR/reference/iso3_to_m49.md))
or UN M49 numeric codes — so DSIR’s regional vectors (`wpro_cty`,
`afro_cty`, etc.) work directly, the same way they do with the GHO
client. Do not mix the two formats in a single call.

``` r

# ISO3 — regional vector passed straight through
sdg <- sdg_data(
  indicator = "3.4.1",
  area      = wpro_cty
)
sdg |> glimpse()

# M49 also works (e.g. when copy-pasting codes from sdg_areas())
sdg_data("3.4.1", area = c("608", "250"))
```

``` r

sdg_clean(sdg)
```

By default,
[`sdg_clean()`](https://shanlong-who.github.io/DSIR/reference/sdg_clean.md)
produces the same 15-column schema as
[`gho_clean()`](https://shanlong-who.github.io/DSIR/reference/gho_clean.md),
so the two outputs can be combined directly with
[`bind_indicators()`](https://shanlong-who.github.io/DSIR/reference/bind_indicators.md).
SDG rows populate the `series` column (and the `iso3` column via
\[[`m49_to_iso3()`](https://shanlong-who.github.io/DSIR/reference/m49_to_iso3.md)\]
for Member States), while leaving the GHO-only `dim1`–`dim3` columns as
`NA`.

### Keeping named SDG dimensions

SDG dimensions are named fields in `sdg$dimensions`, not positional GHO
dimensions. The compact 15-column output omits them. For disaggregated
analysis, retain them explicitly:

``` r

raw <- sdg_data("3.8.2", area = "PHL")
unique(raw$dimensions)
sdg_clean(raw, keep_dimensions = TRUE)
```

This appends character columns such as `dim_age`, `dim_location`,
`dim_sex`, `dim_reporting_type`, `dim_quantile`, and
`dim_type_of_household`. Names depend on the dimensions actually
returned by the API. Codes are unchanged; absent categories are not
assigned total-population codes. Use `keep_metadata = TRUE` to also
retain units and other attributes in the cleaned table.

Select a series and strata with the exact source names and codes:

``` r

sdg_data(
  "3.8.2", area = "PHL",
  series = "SH_OOP_XPD_EARNNET40",
  dimensions = list(
    Age = "ALLAGE", Location = "ALLAREA", Sex = "BOTHSEX",
    Quantile = "_T", Type_of_household = "_T"
  )
) |>
  sdg_clean(keep_dimensions = TRUE)
```

These filters run locally after pagination. Values within one dimension
are OR-ed; different dimensions are AND-ed. An absent requested
dimension warns and returns no rows instead of silently ignoring a
population restriction.

The UN 3.8.2 catalogue checked on 2026-09-30 lists the revised
2025-definition series `SH_OOP_XPD_EARNNET40`. GHO’s
`FINANCIALHARDSHIP_PROPORTIONOFPOP` additionally includes large and
impoverishing expenditure components in `Dim1`. Those are not separate
series in that UN catalogue and cannot be reconstructed by retaining SDG
dimensions. See the [WHO definition and
components](https://www.who.int/data/gho/indicator-metadata-registry/imr-details/376).

### Showing dimension meaning and source context

Use
[`sdg_dimensions()`](https://shanlong-who.github.io/DSIR/reference/sdg_dimensions.md)
to see the official categories and labels for each series. This does not
download observations, and the listed categories need not occur in every
country:

``` r

sdg_dimensions("3.8.2", include_attributes = TRUE)
```

The `code` column contains the JSON API codes used for filtering; the
`sdmx` column is an alternative representation. `kind` distinguishes
dimensions from attributes such as units and nature.

To preserve source context as well as population dimensions:

``` r

detailed <- sdg_clean(raw, keep_dimensions = TRUE, keep_metadata = TRUE)
detailed |>
  select(any_of(c("iso3", "year", "value_num", "attr_units", "attr_nature", "data_source")))
head(detailed$footnotes, 1L)
```

`keep_metadata` retains all returned attributes as `attr_*` columns,
plus source, time detail/coverage, base period, value type, and
geographic information URL. Footnotes and all linked indicator, goal,
and target codes are list-columns, so multiple entries are preserved.
Use RDS for storage when retaining this structure.

For GHO, show each positional dimension’s type directly:

This financial-hardship code is not in the public xMart directory as of
2026-10-06. Select the legacy provider explicitly for this example.

``` r

gho_detailed <- gho_data("FINANCIALHARDSHIP_PROPORTIONOFPOP", area = "PHL",
                         backend = "legacy") |>
  gho_clean(keep_dimensions = TRUE, keep_metadata = TRUE)
gho_detailed |>
  select(provider, iso3, year, value_num, dim1_type, dim1, dim2_type, dim2)
```

Types are taken from each observation’s `Dim1Type`–`Dim3Type`. They are
never guessed from a code prefix or assumed constant for the whole
indicator. GHO metadata includes the retrieval `provider`, original
source codes, observation identifiers, comments (in `footnotes`),
location/time types, parent locations, update timestamps, and time
intervals. Neither optional flag changes the default 15-column output.

[`sdg_data()`](https://shanlong-who.github.io/DSIR/reference/sdg_data.md)
validates declared pagination and total row counts before local
filtering. An incomplete download returns no rows with a warning.
[`sdg_coverage()`](https://shanlong-who.github.io/DSIR/reference/sdg_coverage.md)
retains such warnings and accepts `series` and `dimensions` filters;
without filters, its observation counts combine all strata in each
location and series.

### Combining GHO and SDG with bind_indicators()

When an analysis pulls indicators from both sources,
[`bind_indicators()`](https://shanlong-who.github.io/DSIR/reference/bind_indicators.md)
stacks any number of cleaned tibbles into one. The `source` column
(`"gho"` / `"sdg"`) lets you filter or facet by origin without
remembering which frame came from which API.

Additional columns, including named SDG dimensions, are retained; inputs
without those columns receive typed missing values. Binding rows does
not harmonise codes or definitions across the sources.

``` r

# Two indicators on the same topic from different APIs:
#   GHO NCDMORT3070 (probability of premature NCD mortality)
#   SDG 3.4.1       (mortality rate from NCDs)
gho_ncd <- gho_data("NCDMORT3070", area = wpro_cty) |> gho_clean()
sdg_ncd <- sdg_data("3.4.1",        area = wpro_cty) |> sdg_clean()
bind_indicators(gho_ncd, sdg_ncd) |> glimpse()
```

### Exploring series with sdg_coverage()

A single SDG indicator often contains several **series** — for example
different vaccines, sex strata, or causes of death — each with its own
country and year coverage. Indicator `"3.b.1"` (vaccine coverage) is a
clear case: it is published as four separate series (DTP3, MCV2, PCV3,
HPV), and the year coverage of the newer vaccines is much shorter than
that of DTP3.

[`sdg_coverage()`](https://shanlong-who.github.io/DSIR/reference/sdg_coverage.md)
summarises the year range and observation count per
`(location, series)`, so you can inspect what series exist and how each
is covered before deciding which one to analyse.

``` r

sdg_coverage("3.b.1", area = c("156", "608"))
#>   location series      year_min year_max n_obs
#> 1 156      SH_ACS_DTP3     2000     2023    24
#> 2 156      SH_ACS_HPV      2018     2023     6
#> 3 156      SH_ACS_MCV2     2000     2023    24
#> 4 156      SH_ACS_PCV3     2017     2023     7
#> 5 608      SH_ACS_DTP3     2000     2023    24
#> 6 608      SH_ACS_HPV      2017     2023     7
#> 7 608      SH_ACS_MCV2     2000     2023    24
#> 8 608      SH_ACS_PCV3     2014     2023    10
```

Note that DSIR intentionally does *not* provide SDG analogues of
[`gho_has_data()`](https://shanlong-who.github.io/DSIR/reference/gho_has_data.md)
and
[`gho_count()`](https://shanlong-who.github.io/DSIR/reference/gho_count.md).
SDG data is generally complete enough that those screening helpers add
little value — the more useful pre-analysis question for SDG is “which
series are available?”, which is what
[`sdg_coverage()`](https://shanlong-who.github.io/DSIR/reference/sdg_coverage.md)
answers.

## Where to next

- Source code lives at <https://github.com/shanlong-who/DSIR>.
- Bug reports, feature requests, and pull requests are all welcome —
  please file them on the GitHub issue tracker.
