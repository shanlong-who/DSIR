# DSIR <a href="https://shanlong-who.github.io/DSIR/"><img src="man/figures/logo.jpg" align="right" height="120" alt="DSIR website" /></a>

> Data Science Infrastructure for Global Health

<!-- badges: start -->
[![CRAN status](https://www.r-pkg.org/badges/version/DSIR)](https://CRAN.R-project.org/package=DSIR)
[![Lifecycle: stable](https://img.shields.io/badge/lifecycle-stable-brightgreen.svg)](https://lifecycle.r-lib.org/articles/stages.html#stable)
[![CRAN downloads](https://cranlogs.r-pkg.org/badges/grand-total/DSIR)](https://cran.r-project.org/package=DSIR)
<!-- badges: end -->

An R package for global-health data work. Bundles country metadata 
and lightweight clients for the [WHO Global Health Observatory][gho] 
and [UN Sustainable Development Goals][sdg] APIs, plus reusable 
WHO-style themes for `ggplot2` and `flextable` so that charts and 
tables produced from this data look consistent across reports.

[gho]: https://www.who.int/data/gho
[sdg]: https://unstats.un.org/sdgs

Documentation: <https://shanlong-who.github.io/DSIR/>

## ⚠️ Note about CRAN version

The current CRAN release (0.2.0) has a known issue where 
`gho_data()` returns an HTTP 400 error when called with the full 
`wpro_cty` vector (28 countries) or other long region vectors. 
This has been **fixed in the GitHub development version** (0.5.0).

If you are using DSIR for regional analysis with all WPR / EUR / 
AFR / AMR countries, please install from GitHub for now:

```r
remotes::install_github("shanlong-who/DSIR")
```

CRAN release 0.5.0 is planned for early June 2026.

## Installation

```r
# from CRAN
install.packages("DSIR")

# or the development version from GitHub  
# install.packages("remotes")
remotes::install_github("shanlong-who/DSIR")
```

## Features

### Country metadata

**`who_countries`** — a tibble of all 194 WHO Member States with 
ISO3, ISO2, UN M49 codes, official and short names, WHO region, 
and a `is_pic` flag for Pacific Island Countries.

```r
library(DSIR)
library(dplyr)

who_countries

# Filter Member States in the Western Pacific Region
who_countries |>
  filter(who_region == "WPR") |>
  select(iso3, name_short, is_pic)
```

**Regional ISO3 vectors** — convenience character vectors for 
each WHO region, derived from `who_countries`:

```r
wpro_cty   # 28 Western Pacific Member States (since May 2025)
afro_cty   # 47 African Region Member States
amro_cty   # 35 Region of the Americas Member States
searo_cty  # 10 South-East Asia Region Member States
euro_cty   # 53 European Region Member States
emro_cty   # 21 Eastern Mediterranean Region Member States
pic_cty    # 14 Pacific Island Country Member States (subset of WPR)
```

**`iso3_to_region()`** — quick lookup from ISO3 codes to WHO regions.
Vectorized; returns `NA` for codes not matching a Member State.

```r
iso3_to_region("PHL")                          # "WPR"
iso3_to_region(c("PHL", "FRA", "ZAF", "XYZ"))  # "WPR" "EUR" "AFR" NA
```

### Visualization

**`theme_dsi()`** — publication-ready `ggplot2` theme.

```r
library(ggplot2)
library(dplyr)

# WHO Member States by region
who_countries |>
  count(who_region) |>
  ggplot(aes(reorder(who_region, n), n)) +
  geom_col(fill = "#0093D5") +
  coord_flip() +
  theme_dsi() +
  labs(title = "WHO Member States by region", x = NULL, y = NULL)
```

**`dsi_flextable_defaults()`** — one-line setup for `flextable` 
formatting (booktabs style, bold headers, paddings).

```r
dsi_flextable_defaults()
```

**`ggpie()`** — quick pie charts with automatic percentage labels.

```r
df <- data.frame(
  region = c("AFR", "AMR", "EUR", "WPR", "SEAR", "EMR"),
  countries = c(47, 35, 53, 28, 10, 21)
)
ggpie(df, "region", "countries", .offset = 1.2)
```

### Utilities

**`geomean()`** — geometric mean, with optional weights. Useful for 
aggregating ratio-based health indicators where the composite is 
multiplicative — e.g. UHC service-coverage tracers.

```r
geomean(c(0.6, 0.8, 0.95))                      # ~0.772
geomean(c(0.6, 0.8, 0.95), w = c(2, 1, 1))      # weighted version
```

### WHO GHO API

**Check availability before downloading.** GHO has thousands of 
indicators but any one of them may not cover the countries or years 
you need. Three lightweight helpers ask the server what is available 
without transferring observations:

```r
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

```r
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

`gho_clean()` selects the useful columns and renames them to 
`indicator`, `location`, `year`, `dim1`–`dim3`, `value`, `low`, 
`high`. Output schema is stable across indicators — missing 
columns are filled with `NA`.

### UN SDG API

Same pattern as GHO: **search → fetch → clean**.

```r
# Browse goals, targets, indicators, and geographic areas
sdg_goals()
sdg_targets()
sdg_indicators()
sdg_areas()

# Fetch indicator data
sdg_data("3.2.1", area = "156", year_from = 2015, year_to = 2023)

# Tidy the SDG response
raw <- sdg_data("3.2.1", area = "156")
sdg_clean(raw)
```

`sdg_clean()` renames the SDG API columns to snake_case 
(`goal`, `target`, `indicator`, `series`, `location`, 
`location_name`, `year`, `value`, `low`, `high`) and flattens 
the `indicator` list-column. `value`, `low`, and `high` are 
returned as character to preserve non-numeric entries (`"<0.1"`, 
aggregate notes); coerce with `as.numeric()` downstream.

## License

MIT — © 2026 Shanlong Ding