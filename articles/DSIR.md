# DSIR

``` r

library(DSIR)
library(dplyr)
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

*Code chunks below are not evaluated when this vignette is built, since
they make network calls. Run them in your own R session to see the
output.*

## WHO Member State metadata

The `who_countries` tibble lists all 194 WHO Member States with their
ISO3, ISO2, UN M49 codes, official names, short names, and WHO region.
For Western Pacific countries, an extra column `is_pic` identifies the
14 Pacific Island Countries.

``` r

who_countries
```

For convenience, DSIR offers pre-defined vectors of ISO3 codes for each
WHO region.

``` r

wpro_cty
length(wpro_cty)   # 28 Member States in WPR (since May 2025)
```

The `is_pic` flag is useful because Pacific Island Countries are often
analysed as a group, given their distinct demographic and geographic
profiles.

``` r

who_countries |>
  filter(is_pic) |>
  select(iso3, name_short)
```

When you have a vector of ISO3 codes and need to know which WHO region
each belongs to,
[`iso3_to_region()`](https://shanlong-who.github.io/DSIR/reference/iso3_to_region.md)
provides the lookup. It is vectorised and returns `NA` for codes that do
not match a WHO Member State.

``` r

iso3_to_region(c("PHL", "FRA", "ZAF", "USA", "XYZ"))
# "WPR" "EUR" "AFR" "AMR" NA
```

This is convenient when joining external datasets (which often arrive
keyed only by ISO3) to the WHO regional structure.

## Checking availability before fetching

GHO has thousands of indicators, but any single indicator may not cover
the countries or years you need. Before issuing a full download with
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

It returns `TRUE`, `FALSE`, or `NA` (for request failures, including a
non-existent indicator code — GHO returns HTTP 404 in that case).

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
#>   location year_min year_max n_obs
#> 1 DEU          2000     2021    66
#> 2 FRA          2000     2021    66
#> 3 JPN          2000     2021    66
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
drops the internal OData columns and renames what remains, leaving a
compact tibble with `indicator`, `location`, `year`, three optional
dimensions, and `value` / `low` / `high`.

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
#> 0.7720589

# With optional weights — useful when tracers have different 
# methodological importance
geomean(c(0.6, 0.8, 0.95), w = c(2, 1, 1))
```

[`geomean()`](https://shanlong-who.github.io/DSIR/reference/geomean.md)
handles missing values, zeros, and negative values sensibly — see
[`?geomean`](https://shanlong-who.github.io/DSIR/reference/geomean.md)
for details. It is a small helper, but it removes a common source of
bugs when re-implementing index calculations from indicator components.

## Plotting with theme_dsi()

[`theme_dsi()`](https://shanlong-who.github.io/DSIR/reference/theme_dsi.md)
is a `ggplot2` theme tuned for WHO-style charts — clean panels, a modest
grid, and a consistent accent colour. Use it as a drop-in replacement
for
[`theme_minimal()`](https://ggplot2.tidyverse.org/reference/ggtheme.html)
whenever a chart is heading into a WHO deliverable.

``` r

uhc_clean |>
  ggplot(aes(x = year, y = value, group = iso3)) +
  geom_line(alpha = 0.6, color = "#0093D5") +
  theme_dsi() +
  labs(
    title    = "UHC Service Coverage Index, WPR Member States",
    subtitle = "2015 onwards",
    x = NULL, y = "SCI"
  )
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
dsi_flextable_defaults()

uhc_clean |>
  filter(year == max(year)) |>
  left_join(who_countries, by = "iso3") |>
  select(name_short, value) |>
  arrange(desc(value)) |>
  flextable() |>
  set_caption("UHC SCI in WPR, latest year")
```

## Working with SDG indicators

[`sdg_data()`](https://shanlong-who.github.io/DSIR/reference/sdg_data.md)
and
[`sdg_clean()`](https://shanlong-who.github.io/DSIR/reference/sdg_clean.md)
follow the same fetch-then-tidy pattern as their GHO counterparts. The
main differences are that indicator codes use the dotted SDG format
(e.g. `"3.4.1"`) and that `value`, `low`, and `high` are kept as
character — the SDG API returns non-numeric entries (`"<0.1"`, aggregate
notes) for some rows, so coerce with
[`as.numeric()`](https://rdrr.io/r/base/numeric.html) only when you are
ready to drop them.

``` r

sdg <- sdg_data(
  indicator = "3.4.1",
  area      = wpro_cty
)
sdg |> glimpse()
```

``` r

sdg_clean(sdg)
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
