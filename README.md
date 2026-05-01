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

## Installation

```r
# from CRAN
install.packages("DSIR")

# or the development version from GitHub  
# install.packages("remotes")
remotes::install_github("shanlong-who/DSIR")
```

## Features

### Visualization

**`theme_dsi()`** — publication-ready `ggplot2` theme.

```r
library(DSIR)
library(ggplot2)

ggplot(women, aes(height, weight)) +
  geom_point(color = "steelblue") +
  theme_dsi()
```

**`dsi_flextable_defaults()`** — one-line setup for `flextable`
formatting (booktabs style, bold headers). Pass
`font_family = "Cambria"` if you have the font installed.

```r
dsi_flextable_defaults()
```

**`ggpie()`** — quick pie charts with automatic percentage labels.

```r
df <- data.frame(category = c("A", "B", "C"), value = c(40, 35, 25))
ggpie(df, "category", "value")
```

### Data

**`wpro_cty`** — ISO-3 country codes for the WHO Western Pacific
Region.

```r
head(wpro_cty)
#> [1] "AUS" "BRN" "KHM" "CHN" "COK" "FJI"
```

### WHO GHO API

```r
# Search indicators by keyword
gho_indicators("mortality")

# Country-level data for an indicator
gho_data("NCDMORT3070", spatial_type = "country")

# Filter by area and year
gho_data("WHOSIS_000001", area = c("FRA", "DEU"), year_from = 2015)

# Discover available dimensions
gho_dimensions("NCDMORT3070")
gho_dimensions("NCDMORT3070", dimension = "Dim1")
```

### UN SDG API

```r
# Browse goals, targets, indicators, and geographic areas
sdg_goals()
sdg_targets()
sdg_indicators()
sdg_areas()

# Fetch indicator data
sdg_data("3.2.1", area = "156", year_from = 2015, year_to = 2023)
```

## License

MIT
