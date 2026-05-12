# DSIR [![DSIR website](reference/figures/logo.jpg)](https://shanlong-who.github.io/DSIR/)

> Data Science Infrastructure for Global Health

An R package for global-health data work. Bundles country metadata and
lightweight clients for the [WHO Global Health
Observatory](https://www.who.int/data/gho) and [UN Sustainable
Development Goals](https://unstats.un.org/sdgs) APIs, plus reusable
WHO-style themes for `ggplot2` and `flextable` so that charts and tables
produced from this data look consistent across reports.

Documentation: <https://shanlong-who.github.io/DSIR/>

## ⚠️ Note about CRAN version

The current CRAN release (0.2.0) has a known issue where
[`gho_data()`](https://shanlong-who.github.io/DSIR/reference/gho_data.md)
returns an HTTP 400 error when called with the full `wpro_cty` vector
(28 countries) or other long region vectors. This has been **fixed in
the GitHub development version** (0.5.0).

If you are using DSIR for regional analysis with all WPR / EUR / AFR /
AMR countries, please install from GitHub for now:

``` r

remotes::install_github("shanlong-who/DSIR")
```

CRAN release 0.5.0 is planned for early June 2026.

## Installation

``` r

# from CRAN
install.packages("DSIR")

# or the development version from GitHub  
# install.packages("remotes")
remotes::install_github("shanlong-who/DSIR")
```

## Features

### Country metadata

**`who_countries`** — a tibble of all 194 WHO Member States with ISO3,
ISO2, UN M49 codes, official and short names, WHO region, and a `is_pic`
flag for Pacific Island Countries.

``` r

library(DSIR)
library(dplyr)

who_countries

# Filter Member States in the Western Pacific Region
who_countries |>
  filter(who_region == "WPR") |>
  select(iso3, name_short, is_pic)
```

**Regional ISO3 vectors** — convenience character vectors for each WHO
region, derived from `who_countries`:

``` r

wpro_cty   # 28 Western Pacific Member States (since May 2025)
afro_cty   # 47 African Region Member States
amro_cty   # 35 Region of the Americas Member States
searo_cty  # 10 South-East Asia Region Member States
euro_cty   # 53 European Region Member States
emro_cty   # 21 Eastern Mediterranean Region Member States
pic_cty    # 14 Pacific Island Country Member States (subset of WPR)
```

**[`iso3_to_region()`](https://shanlong-who.github.io/DSIR/reference/iso3_to_region.md)**
— quick lookup from ISO3 codes to WHO regions. Vectorized; returns `NA`
for codes not matching a Member State.

``` r

iso3_to_region("PHL")                          # "WPR"
iso3_to_region(c("PHL", "FRA", "ZAF", "XYZ"))  # "WPR" "EUR" "AFR" NA
```

**[`iso3_to_m49()`](https://shanlong-who.github.io/DSIR/reference/iso3_to_m49.md)**
— convert ISO3 codes to UN M49 numeric codes. Useful for moving between
GHO (ISO3) and SDG (M49) workflows. Case-insensitive; returns
three-character zero-padded strings; `NA` for non-Members.

``` r

iso3_to_m49("PHL")                             # "608"
iso3_to_m49(c("PHL", "FRA", "JPN"))            # "608" "250" "392"
iso3_to_m49(c("PRI", "PHL"))                   # NA "608"
```

In practice you rarely need to call this directly:
[`sdg_data()`](https://shanlong-who.github.io/DSIR/reference/sdg_data.md)
and
[`sdg_coverage()`](https://shanlong-who.github.io/DSIR/reference/sdg_coverage.md)
accept ISO3 codes for their `area` argument and do the conversion
internally.

### Visualization

**[`theme_dsi()`](https://shanlong-who.github.io/DSIR/reference/theme_dsi.md)
and
[`theme_dsi_facet()`](https://shanlong-who.github.io/DSIR/reference/theme_dsi_facet.md)**
— publication-ready `ggplot2` themes. Use
[`theme_dsi()`](https://shanlong-who.github.io/DSIR/reference/theme_dsi.md)
for single-panel charts and
[`theme_dsi_facet()`](https://shanlong-who.github.io/DSIR/reference/theme_dsi_facet.md)
for faceted plots; the facet variant adds panel borders, light strip
backgrounds, and panel spacing tuned for multi-panel layouts.

``` r

library(ggplot2)
library(dplyr)

# Single panel — theme_dsi()
who_countries |>
  count(who_region) |>
  ggplot(aes(reorder(who_region, n), n)) +
  geom_col(fill = "#0093D5") +
  coord_flip() +
  scale_y_dsi_col() +
  theme_dsi() +
  labs(title = "WHO Member States by region", x = NULL, y = NULL)

# Faceted — theme_dsi_facet()
who_countries |>
  count(who_region, is_pic) |>
  ggplot(aes(reorder(who_region, n), n, fill = is_pic)) +
  geom_col() +
  coord_flip() +
  scale_y_dsi_col() +
  facet_wrap(~ is_pic, labeller = as_labeller(
    c(`TRUE` = "Pacific Island Countries", `FALSE` = "Other Member States")
  )) +
  scale_fill_manual(values = c(`TRUE` = "#0093D5", `FALSE` = "grey70"),
                    guide = "none") +
  theme_dsi_facet() +
  labs(title = "WHO Member States by region and PIC status",
       x = NULL, y = NULL)
```

**[`scale_y_dsi_col()`](https://shanlong-who.github.io/DSIR/reference/scale_dsi_col.md)
and
[`scale_x_dsi_col()`](https://shanlong-who.github.io/DSIR/reference/scale_dsi_col.md)**
— drop-in replacements for
[`scale_y_continuous()`](https://ggplot2.tidyverse.org/reference/scale_continuous.html)
and
[`scale_x_continuous()`](https://ggplot2.tidyverse.org/reference/scale_continuous.html)
that remove the default lower expansion, so columns in bar charts sit
flush with the axis instead of floating above it. Pick the one that
matches where you mapped the value:
[`scale_y_dsi_col()`](https://shanlong-who.github.io/DSIR/reference/scale_dsi_col.md)
when `value` is the `y` aesthetic (including horizontal bars made with
[`coord_flip()`](https://ggplot2.tidyverse.org/reference/coord_flip.html)
— the aesthetic is still `y`), and
[`scale_x_dsi_col()`](https://shanlong-who.github.io/DSIR/reference/scale_dsi_col.md)
when `value` is the `x` aesthetic (e.g. 
`geom_col(aes(value, category))`). Both accept any argument that
`scale_*_continuous()` accepts.

``` r

# Vertical bars
ggplot(mtcars, aes(factor(cyl))) +
  geom_bar(fill = "#0093D5") +
  scale_y_dsi_col() +
  theme_dsi() +
  labs(title = "Cars by cylinder count", x = "Cylinders", y = NULL)
```

**[`dsi_flextable_defaults()`](https://shanlong-who.github.io/DSIR/reference/dsi_flextable_defaults.md)**
— one-line setup for `flextable` formatting (booktabs style, bold
headers, paddings).

``` r

dsi_flextable_defaults()
```

**[`ggpie()`](https://shanlong-who.github.io/DSIR/reference/ggpie.md)**
— quick pie charts with automatic percentage labels.

``` r

df <- data.frame(
  region = c("AFR", "AMR", "EUR", "WPR", "SEAR", "EMR"),
  countries = c(47, 35, 53, 28, 10, 21)
)
ggpie(df, "region", "countries", .offset = 1.2)
```

### Utilities

**[`geomean()`](https://shanlong-who.github.io/DSIR/reference/geomean.md)**
— geometric mean, with optional weights. Useful for aggregating
ratio-based health indicators where the composite is multiplicative —
e.g. UHC service-coverage tracers.

``` r

geomean(c(0.6, 0.8, 0.95))                      # ~0.772
geomean(c(0.6, 0.8, 0.95), w = c(2, 1, 1))      # weighted version
```

### WHO GHO API

**Check availability before downloading.** GHO has thousands of
indicators but any one of them may not cover the countries or years you
need. Three lightweight helpers ask the server what is available without
transferring observations:

``` r

# Yes / no for a given indicator + filter (TRUE / FALSE / NA on failure)
gho_has_data("WHOSIS_000001", area = "FRA")

# Row count the same filter would return — useful for sizing a download
gho_count("WHOSIS_000001", area = wpro_cty)

# Per-country year coverage and observation counts
gho_coverage("WHOSIS_000001", area = c("FRA", "DEU", "JPN"))
#>   location year_min year_max n_obs
#> 1 DEU          2000     2021    66
#> 2 FRA          2000     2021    66
#> 3 JPN          2000     2021    66
```

**Fetch and clean.** The typical workflow is **search → fetch → clean**:

``` r

# Search indicators by keyword
gho_indicators("mortality")

# Discover available dimensions for an indicator
gho_dimensions("NCDMORT3070")
gho_dimensions("NCDMORT3070", dimension = "Dim1")

# Fetch country-level data
gho_data("NCDMORT3070", spatial_type = "country")

# Fetch with area and year filters
gho_data(
  indicator = "WHOSIS_000001", 
  area      = wpro_cty,
  year_from = 2015
)

# Tidy the raw GHO response
raw <- gho_data("NCDMORT3070", spatial_type = "country", area = wpro_cty)
gho_clean(raw)
```

[`gho_clean()`](https://shanlong-who.github.io/DSIR/reference/gho_clean.md)
selects the useful columns and renames them to `indicator`, `location`,
`year`, `dim1`–`dim3`, `value`, `low`, `high`. Output schema is stable
across indicators — missing columns are filled with `NA`.

### UN SDG API

Same pattern as GHO: **search → fetch → clean**.

``` r

# Browse goals, targets, indicators, and geographic areas
sdg_goals()
sdg_targets()
sdg_indicators()
sdg_areas()

# Search indicators by keyword — AND semantics, case-insensitive
# substring match on the indicator description (client-side filter)
sdg_indicators("mortality")
sdg_indicators("mortality cancer")
sdg_indicators(c("maternal", "mortality"))

# Fetch indicator data — `area` accepts ISO3 codes (converted internally)
# or UN M49 numeric codes. ISO3 lets DSIR's regional vectors be passed
# directly, the same way they work with the GHO client.
sdg_data("3.2.1", area = "PHL", year_from = 2015, year_to = 2023)
sdg_data("3.4.1", area = wpro_cty)

# M49 also works (e.g. when copy-pasting codes from sdg_areas())
sdg_data("3.2.1", area = "608", year_from = 2015, year_to = 2023)

# Tidy the SDG response
raw <- sdg_data("3.2.1", area = "PHL")
sdg_clean(raw)
```

[`sdg_clean()`](https://shanlong-who.github.io/DSIR/reference/sdg_clean.md)
renames the SDG API columns to snake_case (`goal`, `target`,
`indicator`, `series`, `location`, `location_name`, `year`, `value`,
`low`, `high`) and flattens the `indicator` list-column. `value`, `low`,
and `high` are returned as character to preserve non-numeric entries
(`"<0.1"`, aggregate notes); coerce with
[`as.numeric()`](https://rdrr.io/r/base/numeric.html) downstream.

**Exploring series.** A single SDG indicator often contains several
series — for example different vaccines, sex strata, or causes of death
— each with its own country / year coverage.
[`sdg_coverage()`](https://shanlong-who.github.io/DSIR/reference/sdg_coverage.md)
summarises the year range and observation count per `(location, series)`
so you can see what is available before deciding which series to
analyse.

``` r

# 3.b.1 (vaccine coverage) is published as four separate series
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

GHO-style `has_data()` /
[`count()`](https://dplyr.tidyverse.org/reference/count.html) helpers
are intentionally not provided for SDG because SDG data is generally
complete enough that pre-flight checks add little value.

## License

MIT — © 2026 Shanlong Ding
